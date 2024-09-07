import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:drift/native.dart' as native;
import 'package:flutter/material.dart' show StringCharacters;
import 'package:flutter/services.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

class DictionaryService {
  late AppDatabase _database;

  final _kanaKit = const KanaKit().copyWithConfig(passRomaji: true);

  DictionaryService({AppDatabase? database}) {
    if (database != null) _database = database;
  }

  Future<void> initialize() async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    // Set temp directory
    sqlite3.tempDirectory = (await path_provider.getTemporaryDirectory()).path;
  }

  Future<DictionaryStatus> open({
    bool validate = true,
    bool transferCheck = true,
  }) async {
    try {
      final appSupportDir =
          await path_provider.getApplicationSupportDirectory();

      if (transferCheck) {
        // Check if user data transfer was previously interrupted
        String userDataTransferPath = path.join(
          appSupportDir.path,
          constants.userDataTransferFile,
        );
        if (await File(userDataTransferPath).exists()) {
          return DictionaryStatus.transferInterrupted;
        }
      }

      // Check if database file exists
      String dbPath = path.join(
        appSupportDir.path,
        SagaseDictionaryConstants.dictionaryDatabaseFile,
      );

      if (!await File(dbPath).exists()) {
        if (await File(
                path.join(appSupportDir.path, constants.isarDatabaseFile))
            .exists()) {
          return DictionaryStatus.migrationRequired;
        }
        return DictionaryStatus.initialInstall;
      }

      // Open the database
      _database = AppDatabase(
        native.NativeDatabase.createInBackground(File(dbPath)),
      );

      if (validate) {
        return _validateDictionary();
      } else {
        return DictionaryStatus.valid;
      }
    } catch (_) {
      return DictionaryStatus.invalid;
    }
  }

  Future<void> close() async {
    return _database.close();
  }

  Future<DictionaryStatus> _validateDictionary() async {
    // If dictionary info does not exist, something is wrong with the database
    final dictionaryInfo = await _database.dictionaryInfosDao.get();
    if (dictionaryInfo == null) {
      return DictionaryStatus.invalid;
    }

    // If database version does not match current, app update includes a new database
    if (dictionaryInfo.version != SagaseDictionaryConstants.dictionaryVersion) {
      return DictionaryStatus.outOfDate;
    }

    return DictionaryStatus.valid;
  }

  Future<List<DictionaryItem>> searchDictionary(
    String text,
    SearchFilter filter,
  ) async {
    switch (filter) {
      case SearchFilter.vocab:
        // First check if searching single kanji
        Kanji? kanji;
        if (text.characters.length == 1 &&
            text.contains(constants.kanjiRegExp)) {
          kanji = await _database.kanjisDao.getKanji(text);
        }

        // Search vocab
        final vocabList = await _database.vocabsDao.search(text);

        // Add kanji to the start of results if found
        if (kanji != null) {
          return <DictionaryItem>[kanji] + vocabList;
        } else {
          return vocabList;
        }
      case SearchFilter.kanji:
        return _database.kanjisDao.search(text);
      case SearchFilter.properNouns:
        return _database.properNounsDao.search(text);
    }
  }

  Future<Vocab> getVocab(int id, {FrontType? frontType}) async {
    return _database.vocabsDao.get(id, frontType: frontType);
  }

  Future<List<Vocab>> getVocabList(
    List<int> list, {
    FrontType? frontType,
  }) async {
    return _database.vocabsDao.getAll(list, frontType: frontType);
  }

  Future<List<Vocab>> getVocabUsingKanji(String kanji) async {
    return (await _database.vocabsDao.getUsingKanji(kanji))
      ..sort(_compareVocab);
  }

  Future<List<Vocab>> getVocabByJapaneseTextToken(
    JapaneseTextToken token,
  ) async {
    late List<Vocab> results;
    if (token.base.contains(constants.kanjiRegExp)) {
      // Search by writing and reading
      results = await _database.vocabsDao.getByWritingAndReading(
        token.base,
        _kanaKit.toHiragana(token.baseReading),
      );
      // If nothing was found, try again with only writing
      if (results.isEmpty) {
        results = await _database.vocabsDao.getByWriting(token.base);
      }
    } else {
      // Search by reading only
      results = await _database.vocabsDao.getByReading(token.base);
    }

    if (results.length <= 1) return results;

    // Check part of speech
    if (token.pos != null) {
      List<Vocab> list = List.from(results);
      outer:
      for (int i = 0; i < list.length; i++) {
        if (list[i].pos != null && list[i].pos!.contains(token.pos)) {
          continue outer;
        } else {
          for (var definition in list[i].definitions) {
            if (definition.pos != null && definition.pos!.contains(token.pos)) {
              continue outer;
            }
          }
        }
        list.removeAt(i--);
      }

      if (list.length == 1) {
        return list;
      } else if (list.length > 1) {
        results = list;
      }
    }

    // If only kana, try to limit returned vocab
    if (_kanaKit.isKana(token.base)) {
      List<Vocab> list = List.from(results);
      // Remove vocab not usually written only with kana
      for (int i = 0; i < list.length; i++) {
        if (list[i].writings != null && !list[i].isUsuallyKanaAlone()) {
          list.removeAt(i--);
        }
      }

      if (list.length == 1) {
        return list;
      } else if (list.isEmpty) {
        list = List.from(results);
      }

      // Remove vocab with reading not in the first kanji reading pair
      outer:
      for (int i = 0; i < list.length; i++) {
        for (var reading in list[i].readings) {
          if (token.base == reading.reading) {
            continue outer;
          }
        }
        list.removeAt(i--);
      }

      if (list.isNotEmpty) return list..sort(_compareVocab);
    }

    return results..sort(_compareVocab);
  }

  // Function to be used with list.sort
  // Compare by frequency score and commonness
  // b - a so that the list will be sorted from highest to lowest
  int _compareVocab(Vocab a, Vocab b) {
    return b.frequencyScore +
        (b.common ? 1 : 0) -
        a.frequencyScore -
        (a.common ? 1 : 0);
  }

  Future<Kanji> getKanji(String kanji) async {
    return _database.kanjisDao.getKanji(kanji);
  }

  Future<List<Kanji>> getKanjiList(
    List<int> list, {
    FrontType? frontType,
  }) async {
    return _database.kanjisDao.getAll(list, frontType: frontType);
  }

  Future<List<Kanji>> getKanjiWithRadical(String radical) async {
    return _database.kanjisDao.getAllWithRadical(radical);
  }

  Future<PredefinedDictionaryList> getPredefinedDictionaryList(int id) async {
    return _database.predefinedDictionaryListsDao.get(id);
  }

  Future<List<PredefinedDictionaryList>> getPredefinedDictionaryLists(
    List<int> ids,
  ) async {
    return _database.predefinedDictionaryListsDao.getAll(ids);
  }

  Future<List<PredefinedDictionaryList>>
      getPredefinedDictionaryListsWithoutItems(List<int> ids) async {
    return _database.predefinedDictionaryListsDao.getAllWithoutItems(ids);
  }

  Future<MyDictionaryList> createMyDictionaryList(String name) async {
    return _database.myDictionaryListsDao.create(name);
  }

  Future<void> renameMyDictionaryList(
    MyDictionaryList dictionaryList,
    String name,
  ) async {
    return _database.myDictionaryListsDao.rename(dictionaryList, name);
  }

  Future<MyDictionaryList> getMyDictionaryList(int id) async {
    return _database.myDictionaryListsDao.get(id);
  }

  Future<List<MyDictionaryList>> getMyDictionaryLists(List<int> ids) async {
    return _database.myDictionaryListsDao.getAllFromList(ids);
  }

  Future<List<MyDictionaryList>> getAllMyDictionaryLists() async {
    return _database.myDictionaryListsDao.getAll();
  }

  Future<DictionaryItemIdsResult> getMyDictionaryListItems(
    MyDictionaryList dictionaryList,
  ) async {
    return _database.myDictionaryListsDao
        .getDictionaryListItems(dictionaryList);
  }

  Stream<List<MyDictionaryList>> watchMyDictionaryLists() {
    return _database.myDictionaryListsDao.watchAll();
  }

  Stream<DictionaryItemIdsResult> watchMyDictionaryListItems(
    MyDictionaryList dictionaryList,
  ) {
    return _database.myDictionaryListsDao
        .watchMyDictionaryListItems(dictionaryList);
  }

  Stream<List<int>> watchMyDictionaryListsContainingDictionaryItem(
    DictionaryItem dictionaryItem,
  ) {
    return _database.myDictionaryListsDao
        .watchContainingDictionaryItem(dictionaryItem);
  }

  Future<void> deleteMyDictionaryList(MyDictionaryList dictionaryList) async {
    return _database.myDictionaryListsDao
        .deleteMyDictionaryList(dictionaryList);
  }

  Future<void> addToMyDictionaryList(
    MyDictionaryList dictionaryList,
    DictionaryItem dictionaryItem,
  ) async {
    return _database.myDictionaryListsDao
        .addDictionaryItem(dictionaryList, dictionaryItem);
  }

  Future<void> removeFromMyDictionaryList(
    MyDictionaryList dictionaryList,
    DictionaryItem dictionaryItem,
  ) async {
    return _database.myDictionaryListsDao
        .removeDictionaryItem(dictionaryList, dictionaryItem);
  }

  Future<List<int>> getMyDictionaryListsContainingDictionaryItem(
    DictionaryItem dictionaryItem,
  ) async {
    return _database.myDictionaryListsDao
        .getContainingDictionaryItem(dictionaryItem);
  }

  Future<MyDictionaryList?> importMyDictionaryList(String path) async {
    try {
      return _database.myDictionaryListsDao
          .importShare(await File(path).readAsString());
    } catch (_) {
      return null;
    }
  }

  Future<FlashcardSet> createFlashcardSet(String name) async {
    return _database.flashcardSetsDao.create(name);
  }

  Future<void> updateFlashcardSet(FlashcardSet flashcardSet) async {
    flashcardSet.timestamp = DateTime.now();
    return _database.flashcardSetsDao.setFlashcardSet(flashcardSet);
  }

  Future<List<FlashcardSet>> getFlashcardSets() async {
    return _database.flashcardSetsDao.getAll();
  }

  Future<void> deleteFlashcardSet(FlashcardSet flashcardSet) async {
    return _database.flashcardSetsDao.deleteFlashcardSet(flashcardSet);
  }

  Future<List<DictionaryItem>> getFlashcardSetFlashcards(
    FlashcardSet flashcardSet,
  ) async {
    Set<int> vocabIds = {};
    Set<int> kanjiIds = {};
    // Get predefined dictionary list vocab/kanji ids
    final predefinedDictionaryLists = await getPredefinedDictionaryLists(
        flashcardSet.predefinedDictionaryLists);
    for (var dictionaryList in predefinedDictionaryLists) {
      vocabIds.addAll(dictionaryList.vocab);
      kanjiIds.addAll(dictionaryList.kanji);
    }

    // Get my dictionary list vocab/kanji ids
    final myDictionaryLists =
        await getMyDictionaryLists(flashcardSet.myDictionaryLists);
    for (var dictionaryList in myDictionaryLists) {
      // Load dictionary list content
      final items = await _database.myDictionaryListsDao
          .getDictionaryListItems(dictionaryList);
      vocabIds.addAll(items.vocabIds);
      kanjiIds.addAll(items.kanjiIds);
    }

    // Load vocab and kanji
    return (await getVocabList(
          vocabIds.toList(),
          frontType: flashcardSet.frontType,
        ))
            .cast<DictionaryItem>() +
        await getKanjiList(
          kanjiIds.toList(),
          frontType: flashcardSet.frontType,
        );
  }

  Future<FlashcardSet> resetFlashcardSetSpacedRepetitionData(
    FlashcardSet flashcardSet,
  ) async {
    // Get dictionary items for the flashcard set
    final dictionaryItems = await getFlashcardSetFlashcards(flashcardSet);

    // Delete the appropriate spaced repetition data
    for (var item in dictionaryItems) {
      await _database.spacedRepetitionDatasDao
          .deleteSpacedRepetitionData(item, flashcardSet.frontType);
    }

    // Finally set flashcard counters to 0
    flashcardSet.flashcardsCompletedToday = 0;
    flashcardSet.newFlashcardsCompletedToday = 0;

    await updateFlashcardSet(flashcardSet);
    return flashcardSet;
  }

  Future<void> setSpacedRepetitionData(SpacedRepetitionData data) async {
    return _database.spacedRepetitionDatasDao.set(data);
  }

  Future<void> deleteSpacedRepetitionData(
    DictionaryItem dictionaryItem,
    FrontType frontType,
  ) async {
    return _database.spacedRepetitionDatasDao
        .deleteSpacedRepetitionData(dictionaryItem, frontType);
  }

  Future<Radical> getRadical(String radical) async {
    return _database.radicalsDao.get(radical);
  }

  Future<List<Radical>> getAllRadicals() async {
    return _database.radicalsDao.getAll();
  }

  Future<List<Radical>> getClassicRadicals() async {
    return _database.radicalsDao.getClassic();
  }

  Future<List<Radical>> getImportantRadicals() async {
    return _database.radicalsDao.getImportant();
  }

  Future<List<SearchHistoryItem>> getSearchHistory() async {
    return _database.searchHistoryItemsDao.getAll();
  }

  Future<void> setSearchHistoryItem(SearchHistoryItem item) async {
    return _database.searchHistoryItemsDao.set(item);
  }

  Future<void> deleteSearchHistoryItem(SearchHistoryItem item) async {
    return _database.searchHistoryItemsDao.deleteItem(item);
  }

  Future<void> deleteSearchHistory() async {
    await _database.searchHistoryItemsDao.deleteAll();
    await _database.textAnalysisHistoryItemsDao.deleteAll();
  }

  Future<List<TextAnalysisHistoryItem>> getTextAnalysisHistory() async {
    return _database.textAnalysisHistoryItemsDao.getAll();
  }

  Future<TextAnalysisHistoryItem> createTextAnalysisHistoryItem(
      String text) async {
    return _database.textAnalysisHistoryItemsDao.create(text);
  }

  Future<void> setTextAnalysisHistoryItem(TextAnalysisHistoryItem item) async {
    return _database.textAnalysisHistoryItemsDao.set(item);
  }

  Future<void> deleteTextAnalysisHistoryItem(
    TextAnalysisHistoryItem item,
  ) async {
    return _database.textAnalysisHistoryItemsDao.deleteItem(item);
  }

  Future<List<ProperNoun>> getProperNounByJapaneseTextToken(
    JapaneseTextToken token,
  ) async {
    if (token.base.contains(constants.kanjiRegExp)) {
      final results = await _database.properNounsDao.getByWritingAndReading(
        token.base,
        _kanaKit.toHiragana(token.baseReading),
      );
      // If nothing was found, try again with only writing
      if (results.isEmpty) {
        return _database.properNounsDao.getByWriting(token.base);
      } else {
        return results;
      }
    } else {
      return _database.properNounsDao.getByReading(token.base);
    }
  }

  Future<String?> exportUserData() async {
    try {
      // My dictionary lists
      List<String> myDictionaryListBackups = [];
      final dictionaryLists = await getAllMyDictionaryLists();
      for (final dictionaryList in dictionaryLists) {
        final result = await getMyDictionaryListItems(dictionaryList);
        myDictionaryListBackups.add(
          dictionaryList
              .copyWith(vocab: result.vocabIds, kanji: result.kanjiIds)
              .toBackupJson(),
        );
      }

      // Flashcard sets
      List<String> flashcardSetBackups = [];
      final flashcardSets = await getFlashcardSets();
      for (final flashcardSet in flashcardSets) {
        flashcardSetBackups.add(flashcardSet.toBackupJson());
      }

      // Spaced repetition data
      Map<String, String> vocabSpacedRepetitionDataBackups = {};
      Map<String, String> vocabSpacedRepetitionDataEnglishBackups = {};
      Map<String, String> kanjiSpacedRepetitionDataBackups = {};
      Map<String, String> kanjiSpacedRepetitionDataEnglishBackups = {};
      final spacedRepetitionDataList =
          await _database.spacedRepetitionDatasDao.getAll();
      for (final spacedRepetitionData in spacedRepetitionDataList) {
        if (spacedRepetitionData.vocabId != 0) {
          if (spacedRepetitionData.frontType == FrontType.japanese) {
            vocabSpacedRepetitionDataBackups[spacedRepetitionData.vocabId
                .toString()] = spacedRepetitionData.toBackupJson();
          } else {
            vocabSpacedRepetitionDataEnglishBackups[spacedRepetitionData.vocabId
                .toString()] = spacedRepetitionData.toBackupJson();
          }
        } else {
          if (spacedRepetitionData.frontType == FrontType.japanese) {
            kanjiSpacedRepetitionDataBackups[spacedRepetitionData.kanjiId
                .toString()] = spacedRepetitionData.toBackupJson();
          } else {
            kanjiSpacedRepetitionDataEnglishBackups[spacedRepetitionData.kanjiId
                .toString()] = spacedRepetitionData.toBackupJson();
          }
        }
      }

      // Create instance
      DateTime now = DateTime.now();
      final backup = UserBackup(
        dictionaryVersion: SagaseDictionaryConstants.dictionaryVersion,
        timestamp: now,
        myDictionaryLists: myDictionaryListBackups,
        flashcardSets: flashcardSetBackups,
        vocabSpacedRepetitionData: vocabSpacedRepetitionDataBackups,
        vocabSpacedRepetitionDataEnglish:
            vocabSpacedRepetitionDataEnglishBackups,
        kanjiSpacedRepetitionData: kanjiSpacedRepetitionDataBackups,
        kanjiSpacedRepetitionDataEnglish:
            kanjiSpacedRepetitionDataEnglishBackups,
      );

      // Create file and write to it
      final file = File(path.join(
        (await path_provider.getApplicationCacheDirectory()).path,
        'backup_${now.year}-${now.month}-${now.day}_${now.millisecondsSinceEpoch}.sagase',
      ));

      await file.writeAsString(backup.toBackupJson());

      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<bool> importUserData(String path) async {
    try {
      // Check if file exists in provided path
      final file = File(path);
      if (!await file.exists()) return false;

      // Try to decode the backup file
      final userBackup = UserBackup.fromBackupJson(await file.readAsString());
      if (userBackup == null) return false;

      await _database.transaction(() async {
        // My dictionary lists
        for (final json in userBackup.myDictionaryLists) {
          await _database.myDictionaryListsDao.importBackup(json);
        }

        // Flashcard sets
        for (final flashcardSetJson in userBackup.flashcardSets) {
          await _database.flashcardSetsDao.importBackup(flashcardSetJson);
        }

        // Vocab spaced repetition data
        for (final entry in userBackup.vocabSpacedRepetitionData.entries) {
          final spacedRepetitionData = SpacedRepetitionData.fromBackupJson(
            jsonDecode(entry.value),
            vocabId: int.parse(entry.key),
            frontType: FrontType.japanese,
          );

          await _database.spacedRepetitionDatasDao.set(spacedRepetitionData);
        }

        // Vocab spaced repetition data English
        for (var entry in userBackup.vocabSpacedRepetitionDataEnglish.entries) {
          final spacedRepetitionData = SpacedRepetitionData.fromBackupJson(
            jsonDecode(entry.value),
            vocabId: int.parse(entry.key),
            frontType: FrontType.english,
          );

          await _database.spacedRepetitionDatasDao.set(spacedRepetitionData);
        }

        // Kanji spaced repetition data
        for (final entry in userBackup.kanjiSpacedRepetitionData.entries) {
          final spacedRepetitionData = SpacedRepetitionData.fromBackupJson(
            jsonDecode(entry.value),
            kanjiId: int.parse(entry.key),
            frontType: FrontType.japanese,
          );

          await _database.spacedRepetitionDatasDao.set(spacedRepetitionData);
        }

        // Kanji spaced repetition data English
        for (var entry in userBackup.kanjiSpacedRepetitionDataEnglish.entries) {
          final spacedRepetitionData = SpacedRepetitionData.fromBackupJson(
            jsonDecode(entry.value),
            kanjiId: int.parse(entry.key),
            frontType: FrontType.english,
          );

          await _database.spacedRepetitionDatasDao.set(spacedRepetitionData);
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<ImportResult> importDatabase(DictionaryStatus status) async {
    try {
      final appSupportDir =
          await path_provider.getApplicationSupportDirectory();
      final appCacheDir = await path_provider.getApplicationCacheDirectory();

      // If upgrading from isar to sql export user data to file
      final isarDb =
          File(path.join(appSupportDir.path, constants.isarDatabaseFile));
      if (await isarDb.exists()) {
        final isarService = IsarService();
        await isarService.initialize();

        // Export user data and move it to support directory
        final isarUserDataPath = await isarService.exportUserData();
        await isarService.close();

        if (isarUserDataPath == null) return ImportResult.transferFailed;

        await File(isarUserDataPath).rename(
            path.join(appSupportDir.path, constants.userDataTransferFile));

        // Delete isar database file
        await isarDb.delete();
        final newDbLockFile =
            File(path.join(appSupportDir.path, constants.isarDatabaseLockFile));
        if (await newDbLockFile.exists()) await newDbLockFile.delete();
      }

      // If upgrading from older database export user data to file
      if (status == DictionaryStatus.outOfDate) {
        final userDataPath = await exportUserData();
        if (userDataPath == null) return ImportResult.transferFailed;

        await File(userDataPath).rename(
            path.join(appSupportDir.path, constants.userDataTransferFile));

        // Remove old database file
        await close();
        final oldDbFile = File(path.join(
          appSupportDir.path,
          SagaseDictionaryConstants.dictionaryDatabaseFile,
        ));
        if (await oldDbFile.exists()) await oldDbFile.delete();
      }

      // Start isolate to handle zip file extraction
      final rootIsolateToken = RootIsolateToken.instance!;
      await Isolate.run(() async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        // Extract zip to application support directory
        final zipFile = File(path.join(
          appCacheDir.path,
          SagaseDictionaryConstants.dictionaryZip,
        ));
        await archive.extractFileToDisk(zipFile.path, appSupportDir.path);

        // Delete zip file
        await zipFile.delete();
      });

      // Open dictionary and return failed import if not valid
      final newDictionaryStatus = await open(transferCheck: false);
      if (newDictionaryStatus != DictionaryStatus.valid) {
        return ImportResult.failed;
      }

      // Transfer user data if it exists
      // This also catches previously failed transfers
      final userDataTransfer =
          File(path.join(appSupportDir.path, constants.userDataTransferFile));
      if (await userDataTransfer.exists()) {
        final importResult = await importUserData(userDataTransfer.path);
        if (!importResult) return ImportResult.failed;
        await userDataTransfer.delete();
      }

      return ImportResult.success;
    } catch (_) {
      return ImportResult.failed;
    }
  }

  Future<bool> importProperNouns() async {
    try {
      final appCacheDir = await path_provider.getApplicationCacheDirectory();

      // Start isolate to handle zip file extraction
      final rootIsolateToken = RootIsolateToken.instance!;
      await Isolate.run(() async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        // Extract zip to application support directory
        final zipFile = File(path.join(
          appCacheDir.path,
          SagaseDictionaryConstants.properNounDictionaryZip,
        ));
        await archive.extractFileToDisk(zipFile.path, appCacheDir.path);

        // Delete zip file
        await zipFile.delete();
      });

      final properNounDictionaryFile = File(path.join(
        appCacheDir.path,
        SagaseDictionaryConstants.properNounDictionaryDatabaseFile,
      ));

      await _database.properNounsDao
          .importProperNouns(properNounDictionaryFile.path);

      await properNounDictionaryFile.delete();

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearProperNouns() async {
    await _database.properNounsDao.deleteProperNouns();
  }
}

enum DictionaryStatus {
  valid,
  invalid,
  outOfDate,
  initialInstall,
  migrationRequired,
  transferInterrupted,
}

enum SearchFilter {
  vocab,
  kanji,
  properNouns,
}

enum ImportResult {
  success,
  failed,
  transferFailed,
}
