import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji_radical.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/predefined_dictionary_list.dart';
import 'package:sagase/datamodels/search_history_item.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:sagase/utils/string_utils.dart';

class IsarService {
  static const List<CollectionSchema<dynamic>> schemas = [
    DictionaryInfoSchema,
    VocabSchema,
    KanjiSchema,
    PredefinedDictionaryListSchema,
    MyDictionaryListSchema,
    FlashcardSetSchema,
    KanjiRadicalSchema,
    SearchHistoryItemSchema,
  ];

  final Isar _isar;

  final _kanaKit = const KanaKit().copyWithConfig(passRomaji: true);

  bool _myDictionaryListsChanged = false;
  bool get myDictionaryListsChanged => _myDictionaryListsChanged;
  List<MyDictionaryList>? _myDictionaryLists;
  List<MyDictionaryList>? get myDictionaryLists => _myDictionaryLists;

  IsarService(this._isar);

  // Optional argument for testing
  static Future<IsarService> initialize({Isar? testingIsar}) async {
    if (testingIsar != null) return IsarService(testingIsar);

    final isar = await Isar.open(schemas);

    return IsarService(isar);
  }

  Future<void> close() async {
    await _isar.close();
  }

  Future<DictionaryStatus> validateDictionary() async {
    // If dictionary info does not exist, this is a fresh install
    final dictionaryInfo = await _isar.dictionaryInfos.get(0);
    if (dictionaryInfo == null) {
      return DictionaryStatus.invalid;
    }

    // If database version does not match current, app update includes a new database
    if (dictionaryInfo.version != constants.dictionaryVersion) {
      return DictionaryStatus.outOfDate;
    }

    // If dictionary count does not match expectation, database probably got corrupted
    if ((await _isar.kanjis.count()) != 13108 ||
        (await _isar.vocabs.count()) != 198094) {
      return DictionaryStatus.invalid;
    }

    return DictionaryStatus.valid;
  }

  Future<List<DictionaryItem>> searchDictionary(String value) async {
    // First convert characters to match what would be in the index
    String searchString =
        _kanaKit.toHiragana(value.toLowerCase().romajiToHalfWidth());

    // First check if searching single kanji
    Kanji? kanji;
    if (searchString.length == 1 &&
        searchString.contains(constants.kanjiRegExp)) {
      kanji = await _isar.kanjis.getByKanji(searchString);
    }

    // Search vocab
    final vocabList = await searchVocab(searchString);

    // Add kanji to the start of results if found
    if (kanji != null) {
      return <DictionaryItem>[kanji] + vocabList;
    } else {
      return vocabList;
    }
  }

  Future<List<Vocab>> searchVocab(String value) async {
    // Check if searching Japanese or romaji text
    if (_kanaKit.isRomaji(value)) {
      List<String> split = Isar.splitWords(value);

      if (split.isEmpty) return [];
      if (split.length == 1) {
        // Check both readings and definition
        List<Vocab> unsortedRomajiList = await _isar.vocabs
            .where()
            .romajiTextIndexElementStartsWith(split.first)
            .limit(350)
            .findAll();

        List<Vocab> unsortedDefinitionList = await _isar.vocabs
            .where()
            .definitionIndexElementStartsWith(split.first)
            .limit(350)
            .findAll();

        // Sort romaji result
        // Each nested list is for difference in length compared to search string
        List<List<Vocab>> nestedRomajiSortingList = [[], [], [], [], []];

        for (int i = 0; i < unsortedRomajiList.length; i++) {
          int minDifference = 999;
          for (var current in unsortedRomajiList[i].romajiTextIndex) {
            if (current.length >= minDifference) continue;
            if (current.startsWith(value)) {
              minDifference = current.length - value.length;
            }
          }

          if (minDifference > 4) {
            nestedRomajiSortingList[4].add(unsortedRomajiList[i]);
          } else {
            nestedRomajiSortingList[minDifference].add(unsortedRomajiList[i]);
          }
        }

        // Sort definition result
        final nestedDefinitionSortingList =
            _sortByDefinition(unsortedDefinitionList, value);

        // Merge sorted romaji and definition lists
        List<Vocab> sortedList = [];
        Map<int, bool> vocabRankMap = {};

        // Both romaji and definitions lists are merged in the same loop to
        // make ranking easier. The last element of the definition list is
        // then added afterward below this loop
        for (int i = 0; i < nestedRomajiSortingList.length; i++) {
          for (var vocab in nestedRomajiSortingList[i]) {
            if (!vocabRankMap.containsKey(vocab.id)) {
              sortedList.add(vocab);
              vocabRankMap[vocab.id] = true;
            }
          }
          for (var vocab in nestedDefinitionSortingList[i]) {
            if (!vocabRankMap.containsKey(vocab.id)) {
              sortedList.add(vocab);
              vocabRankMap[vocab.id] = true;
            }
          }
        }

        for (var vocab in nestedDefinitionSortingList[5]) {
          if (!vocabRankMap.containsKey(vocab.id)) {
            sortedList.add(vocab);
          }
        }

        return sortedList;
      } else {
        // Check definition only
        late final List<Vocab> unsortedList;
        // If start with 'to ' search as single string
        if (value.startsWith('to ')) {
          unsortedList = await _isar.vocabs
              .where()
              .definitionIndexElementStartsWith(value)
              .limit(350)
              .findAll();
        } else {
          // Must do a where check with index and follow up with filters
          // Use -EqualTo for all but last element, and use -StartsWith for last element
          late QueryBuilder<Vocab, Vocab, QAfterFilterCondition> query;

          if (split.length == 2) {
            // First filter is also final filter
            query = _isar.vocabs
                .where()
                .definitionIndexElementEqualTo(split.first)
                .filter()
                .definitionIndexElementStartsWith(split[1]);
          } else {
            // Add all filters
            query = _isar.vocabs
                .where()
                .definitionIndexElementEqualTo(split.first)
                .filter()
                .definitionIndexElementEqualTo(split[1]);
            for (int i = 2; i < split.length - 1; i++) {
              query = query.and().definitionIndexElementEqualTo(split[i]);
            }
            query = query.and().definitionIndexElementStartsWith(split.last);
          }

          unsortedList = await query.limit(350).findAll();
        }

        final sortedList = _sortByDefinition(unsortedList, value);
        return sortedList[0] +
            sortedList[1] +
            sortedList[2] +
            sortedList[3] +
            sortedList[4] +
            sortedList[5];
      }
    } else {
      final unsortedList = await _isar.vocabs
          .where()
          .japaneseTextIndexElementStartsWith(value)
          .limit(350)
          .findAll();

      // Each nested list is for difference in length compared to search string
      List<List<Vocab>> nestedSortingList = [[], [], [], [], []];

      for (int i = 0; i < unsortedList.length; i++) {
        int minDifference = 999;
        for (var current in unsortedList[i].japaneseTextIndex) {
          if (current.length >= minDifference) continue;
          if (current.startsWith(value)) {
            minDifference = current.length - value.length;
          }
        }

        if (minDifference > 4) {
          nestedSortingList[4].add(unsortedList[i]);
        } else {
          nestedSortingList[minDifference].add(unsortedList[i]);
        }
      }

      return nestedSortingList[0] +
          nestedSortingList[1] +
          nestedSortingList[2] +
          nestedSortingList[3] +
          nestedSortingList[4];
    }
  }

  List<List<Vocab>> _sortByDefinition(
    List<Vocab> unsortedList,
    String searchString,
  ) {
    // Each nested list is for quality of match
    //    Nested list 0: definitions 1 starts with string (common vocab)
    //    Nested list 1: exact match in definition 1 (common vocab)
    //    Nested list 2: definitions 1 starts with string (not common vocab)
    //    Nested list 3: exact match in definition 1 (not common vocab)
    //    Nested list 4: exact match in other definition
    //    Nested list 5: no exact match found
    List<List<Vocab>> nestedSortingList = [[], [], [], [], [], []];

    final searchRegExp = RegExp(
      RegExp.escape(searchString),
      caseSensitive: false,
    );
    for (int i = 0; i < unsortedList.length; i++) {
      bool noMatch = true;
      for (int j = 0; j < unsortedList[i].definitions.length; j++) {
        if (unsortedList[i].definitions[j].definition.contains(searchRegExp)) {
          noMatch = false;
          if (j == 0) {
            if (unsortedList[i]
                .definitions[j]
                .definition
                .startsWith(searchRegExp)) {
              if (unsortedList[i].commonWord) {
                nestedSortingList[0].add(unsortedList[i]);
              } else {
                nestedSortingList[2].add(unsortedList[i]);
              }
            } else {
              if (unsortedList[i].commonWord) {
                nestedSortingList[1].add(unsortedList[i]);
              } else {
                nestedSortingList[3].add(unsortedList[i]);
              }
            }
          } else {
            nestedSortingList[4].add(unsortedList[i]);
          }
          break;
        }
      }
      if (noMatch) nestedSortingList[5].add(unsortedList[i]);
    }

    return nestedSortingList;
  }

  Future<Vocab?> getVocab(int id) async {
    return _isar.vocabs.get(id);
  }

  Future<Kanji?> getKanji(String kanji) async {
    return _isar.kanjis.getByKanji(kanji);
  }

  Future<DictionaryList?> getPredefinedDictionaryList(int id) async {
    return _isar.predefinedDictionaryLists.get(id);
  }

  Future<void> createMyDictionaryList(String name) async {
    final list = MyDictionaryList()
      ..name = name
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.myDictionaryLists.put(list);
    });
    // If my lists are loaded, insert the new list, otherwise load my lists
    if (_myDictionaryLists == null) {
      await getMyDictionaryLists();
    } else {
      _myDictionaryLists!.insert(0, list);
    }
  }

  Future<void> updateMyDictionaryList(MyDictionaryList list) async {
    // Move list to start
    _myDictionaryLists!.remove(list);
    _myDictionaryLists!.insert(0, list);
    // Update
    list.timestamp = DateTime.now();
    return _isar.writeTxn(() async {
      await _isar.myDictionaryLists.put(list);
      await list.vocabLinks.save();
      await list.kanjiLinks.save();
    });
  }

  Future<void> getMyDictionaryLists() async {
    _myDictionaryLists =
        await _isar.myDictionaryLists.where().sortByTimestampDesc().findAll();
  }

  Future<void> deleteMyDictionaryList(MyDictionaryList list) async {
    _myDictionaryListsChanged = true;
    // Remove from in memory list
    _myDictionaryLists!.remove(list);
    // Remove from database
    await _isar.writeTxn(() async {
      await _isar.myDictionaryLists.delete(list.id!);
    });
  }

  Future<void> addVocabToMyDictionaryList(
    MyDictionaryList list,
    Vocab vocab,
  ) async {
    _myDictionaryListsChanged = true;
    list.vocabLinks.add(vocab);
    await updateMyDictionaryList(list);
  }

  Future<void> removeVocabFromMyDictionaryList(
    MyDictionaryList list,
    Vocab vocab,
  ) async {
    _myDictionaryListsChanged = true;
    if (!list.vocabLinks.isLoaded) await list.vocabLinks.load();
    list.vocabLinks.removeWhere((element) => element.id == vocab.id);
    await updateMyDictionaryList(list);
  }

  Future<void> addKanjiToMyDictionaryList(
    MyDictionaryList list,
    Kanji kanji,
  ) async {
    _myDictionaryListsChanged = true;
    list.kanjiLinks.add(kanji);
    await updateMyDictionaryList(list);
  }

  Future<void> removeKanjiFromMyDictionaryList(
    MyDictionaryList list,
    Kanji kanji,
  ) async {
    _myDictionaryListsChanged = true;
    if (!list.kanjiLinks.isLoaded) await list.kanjiLinks.load();
    list.kanjiLinks.removeWhere((element) => element.id == kanji.id);
    await updateMyDictionaryList(list);
  }

  Future<FlashcardSet> createFlashcardSet(String name) async {
    final flashcardSet = FlashcardSet()
      ..name = name
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.flashcardSets.put(flashcardSet);
    });
    return flashcardSet;
  }

  Future<void> updateFlashcardSet(
    FlashcardSet flashcardSet, {
    bool updateTimestamp = true,
  }) async {
    if (updateTimestamp) flashcardSet.timestamp = DateTime.now();
    return _isar.writeTxn(() async {
      await _isar.flashcardSets.put(flashcardSet);
      await flashcardSet.predefinedDictionaryListLinks.save();
      await flashcardSet.myDictionaryListLinks.save();
    });
  }

  Future<List<FlashcardSet>> getFlashcardSets() async {
    return _isar.flashcardSets.where().sortByTimestampDesc().findAll();
  }

  Future<FlashcardSet?> getRecentFlashcardSet() async {
    final result = await _isar.flashcardSets
        .where()
        .sortByTimestampDesc()
        .limit(1)
        .findAll();
    if (result.isNotEmpty) {
      return result[0];
    } else {
      return null;
    }
  }

  Future<void> deleteFlashcardSet(FlashcardSet flashcardSet) async {
    await _isar.writeTxn(() async {
      await _isar.flashcardSets.delete(flashcardSet.id);
    });
  }

  Future<void> addDictionaryListsToFlashcardSet(
    FlashcardSet flashcardSet, {
    List<int> predefinedDictionaryListIds = const [],
    List<MyDictionaryList> myDictionaryLists = const [],
  }) async {
    // Add predefined dictionary lists
    for (int i = 0; i < predefinedDictionaryListIds.length; i++) {
      final predefinedDictionaryList = await _isar.predefinedDictionaryLists
          .get(predefinedDictionaryListIds[i]);
      if (predefinedDictionaryList != null) {
        flashcardSet.predefinedDictionaryListLinks
            .add(predefinedDictionaryList);
      }
    }
    // Add my dictionary lists
    for (int i = 0; i < myDictionaryLists.length; i++) {
      flashcardSet.myDictionaryListLinks.add(myDictionaryLists[i]);
    }
    // Update in database if something was changed
    if (predefinedDictionaryListIds.isNotEmpty ||
        myDictionaryLists.isNotEmpty) {
      return updateFlashcardSet(flashcardSet);
    }
  }

  Future<void> removeDictionaryListsToFlashcardSet(
    FlashcardSet flashcardSet, {
    List<int> predefinedDictionaryListIds = const [],
    List<MyDictionaryList> myDictionaryLists = const [],
  }) async {
    // Remove predefined dictionary lists
    for (int i = 0; i < predefinedDictionaryListIds.length; i++) {
      flashcardSet.predefinedDictionaryListLinks.removeWhere(
          (element) => element.id == predefinedDictionaryListIds[i]);
    }
    // Remove my dictionary lists
    for (int i = 0; i < myDictionaryLists.length; i++) {
      flashcardSet.myDictionaryListLinks
          .removeWhere((element) => element.id == myDictionaryLists[i].id);
    }
    // Update in database if something was changed
    if (predefinedDictionaryListIds.isNotEmpty ||
        myDictionaryLists.isNotEmpty) {
      return updateFlashcardSet(flashcardSet);
    }
  }

  Future<void> resetFlashcardSetSpacedRepetitionData(
      FlashcardSet flashcardSet) async {
    await _isar.writeTxn(() async {
      // Predefined lists
      await flashcardSet.predefinedDictionaryListLinks.load();
      for (var list in flashcardSet.predefinedDictionaryListLinks) {
        // Reset vocab
        await list.vocabLinks.load();
        for (var vocab in list.vocabLinks) {
          if (vocab.spacedRepetitionData != null) {
            vocab.spacedRepetitionData = null;
            await _isar.vocabs.put(vocab);
          }
        }

        // Reset kanji
        await list.kanjiLinks.load();
        for (var kanji in list.kanjiLinks) {
          if (kanji.spacedRepetitionData != null) {
            kanji.spacedRepetitionData = null;
            await _isar.kanjis.put(kanji);
          }
        }
      }

      // My lists
      await flashcardSet.myDictionaryListLinks.load();
      for (var list in flashcardSet.myDictionaryListLinks) {
        // Reset vocab
        await list.vocabLinks.load();
        for (var vocab in list.vocabLinks) {
          if (vocab.spacedRepetitionData != null) {
            vocab.spacedRepetitionData = null;
            await _isar.vocabs.put(vocab);
          }
        }

        // Reset kanji
        await list.kanjiLinks.load();
        for (var kanji in list.kanjiLinks) {
          if (kanji.spacedRepetitionData != null) {
            kanji.spacedRepetitionData = null;
            await _isar.kanjis.put(kanji);
          }
        }
      }

      // Finally set new card counter to 0
      flashcardSet.newFlashcardsCompletedToday = 0;
      await _isar.flashcardSets.put(flashcardSet);
    });
  }

  Future<void> updateSpacedRepetitionData(DictionaryItem item) async {
    return _isar.writeTxn(() async {
      if (item is Vocab) {
        await _isar.vocabs.put(item);
      } else {
        await _isar.kanjis.put(item as Kanji);
      }
    });
  }

  Future<void> setSpacedRepetitionDataToNull(DictionaryItem item) async {
    // Get instance, set spaced repetition data to null, then update database
    return _isar.writeTxn(() async {
      if (item is Vocab) {
        var vocab = await _isar.vocabs.get(item.id);
        vocab!.spacedRepetitionData = null;
        await _isar.vocabs.put(vocab);
      } else {
        var kanji = await _isar.kanjis.get(item.id);
        kanji!.spacedRepetitionData = null;
        await _isar.kanjis.put(kanji);
      }
    });
  }

  Future<KanjiRadical?> getKanjiRadical(String radical) async {
    return _isar.kanjiRadicals.getByRadical(radical);
  }

  Future<List<KanjiRadical>> getAllKanjiRadicals() async {
    return _isar.kanjiRadicals.where().findAll();
  }

  Future<List<KanjiRadical>> getClassicKanjiRadicals() async {
    return _isar.kanjiRadicals
        .filter()
        .kangxiIdIsNotNull()
        .sortByKangxiId()
        .findAll();
  }

  Future<List<KanjiRadical>> getImportantKanjiRadicals() async {
    return _isar.kanjiRadicals
        .filter()
        .importanceLessThan(KanjiRadicalImportance.none)
        .sortByImportance()
        .thenByKangxiId()
        .findAll();
  }

  Future<List<SearchHistoryItem>> getSearchHistory() async {
    // Delete old entries first
    List<int> idsToDelete = (await _isar.searchHistoryItems
            .where()
            .sortByTimestampDesc()
            .offset(100)
            .findAll())
        .map((e) => e.id)
        .toList();

    if (idsToDelete.isNotEmpty) {
      await _isar.writeTxn(() async {
        await _isar.searchHistoryItems.deleteAll(idsToDelete);
      });
    }

    // Return actual search history
    return _isar.searchHistoryItems.where().sortByTimestampDesc().findAll();
  }

  Future<void> setSearchHistoryItem(SearchHistoryItem item) async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryItems.put(item);
    });
  }

  Future<void> deleteSearchHistoryItem(SearchHistoryItem item) async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryItems.delete(item.id);
    });
  }

  Future<void> deleteSearchHistory() async {
    await _isar.writeTxn(() async {
      await _isar.searchHistoryItems.clear();
    });
  }

  Future<String> exportUserData() async {
    // My dictionary lists
    List<String> myDictionaryListBackups = [];
    await getMyDictionaryLists();
    for (var myList in _myDictionaryLists!) {
      await myList.vocabLinks.load();
      await myList.kanjiLinks.load();
      myDictionaryListBackups.add(myList.toBackupJson());
    }

    // Flashcard sets
    List<String> flashcardSetBackups = [];
    final flashcardSets = await getFlashcardSets();
    for (var flashcardSet in flashcardSets) {
      await flashcardSet.predefinedDictionaryListLinks.load();
      await flashcardSet.myDictionaryListLinks.load();
      flashcardSetBackups.add(flashcardSet.toBackupJson());
    }

    // Vocab spaced repetition data
    List<String> vocabSpacedRepetitionDataBackups = [];
    final vocabSpacedRepetitionData =
        await _isar.vocabs.filter().spacedRepetitionDataIsNotNull().findAll();
    for (var vocab in vocabSpacedRepetitionData) {
      vocabSpacedRepetitionDataBackups
          .add(vocab.spacedRepetitionData!.toBackupJson(vocabId: vocab.id));
    }

    // Kanji spaced repetition data
    List<String> kanjiSpacedRepetitionDataBackups = [];
    final kanjiSpacedRepetitionData =
        await _isar.kanjis.filter().spacedRepetitionDataIsNotNull().findAll();
    for (var kanji in kanjiSpacedRepetitionData) {
      kanjiSpacedRepetitionDataBackups
          .add(kanji.spacedRepetitionData!.toBackupJson(kanji: kanji.kanji));
    }

    // Create instance
    DateTime now = DateTime.now();
    final backup = UserBackup(
      dictionaryVersion: constants.dictionaryVersion,
      timestamp: now,
      myDictionaryLists: myDictionaryListBackups,
      flashcardSets: flashcardSetBackups,
      vocabSpacedRepetitionData: vocabSpacedRepetitionDataBackups,
      kanjiSpacedRepetitionData: kanjiSpacedRepetitionDataBackups,
    );

    // Create file and write to it
    final tempDir = await path_provider.getTemporaryDirectory();
    final File file = File(
        '${tempDir.path}${Platform.pathSeparator}backup_${now.year}-${now.month}-${now.day}_${now.millisecondsSinceEpoch}.sagase');

    await file.writeAsString(backup.toJson());

    return file.path;
  }

  Future<bool> importUserData(String path) async {
    // Check if file exists in provided path
    final file = File(path);
    if (!await file.exists()) return false;

    // Try to decode the backup file
    try {
      Map<String, dynamic> backupMap = jsonDecode(await file.readAsString());

      await _isar.writeTxn(() async {
        // My dictionary lists
        for (var myListMap in backupMap[constants.backupMyDictionaryLists]) {
          final newMyList = MyDictionaryList.fromBackupJson(myListMap);

          // Add vocab
          for (var vocabId
              in myListMap[constants.backupMyDictionaryListVocab]) {
            final vocab = await _isar.vocabs.get(vocabId);
            if (vocab != null) newMyList.vocabLinks.add(vocab);
          }

          // Add kanji
          for (var kanjiId
              in myListMap[constants.backupMyDictionaryListKanji]) {
            final kanji = await _isar.kanjis.getByKanji(kanjiId);
            if (kanji != null) newMyList.kanjiLinks.add(kanji);
          }

          await _isar.myDictionaryLists.put(newMyList);
          await newMyList.vocabLinks.save();
          await newMyList.kanjiLinks.save();
        }

        // Flashcard sets
        for (var flashcardSetMap in backupMap[constants.backupFlashcardSets]) {
          final newFlashcardSet = FlashcardSet.fromBackupJson(flashcardSetMap);

          // Predefined dictionary lists
          for (var predefinedId in flashcardSetMap[
              constants.backupFlashcardSetPredefinedDictionaryLists]) {
            final predefinedDictionaryList =
                await _isar.predefinedDictionaryLists.get(predefinedId);
            if (predefinedDictionaryList != null) {
              newFlashcardSet.predefinedDictionaryListLinks
                  .add(predefinedDictionaryList);
            }
          }

          // My dictionary lists
          for (var myId in flashcardSetMap[
              constants.backupFlashcardSetMyDictionaryLists]) {
            final myDictionaryList = await _isar.myDictionaryLists.get(myId);
            if (myDictionaryList != null) {
              newFlashcardSet.myDictionaryListLinks.add(myDictionaryList);
            }
          }

          await _isar.flashcardSets.put(newFlashcardSet);
          await newFlashcardSet.predefinedDictionaryListLinks.save();
          await newFlashcardSet.myDictionaryListLinks.save();
        }

        // Vocab spaced repetition data
        for (var spacedRepetitionMap
            in backupMap[constants.backupVocabSpacedRepetitionData]) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(spacedRepetitionMap);
          final vocab = await _isar.vocabs.get(
              spacedRepetitionMap[constants.backupSpacedRepetitionDataVocabId]);
          if (vocab != null) {
            vocab.spacedRepetitionData = newSpacedRepetition;
            await _isar.vocabs.put(vocab);
          }
        }

        // Kanji spaced repetition data
        for (var spacedRepetitionMap
            in backupMap[constants.backupKanjiSpacedRepetitionData]) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(spacedRepetitionMap);
          final kanji = await _isar.kanjis.getByKanji(
              spacedRepetitionMap[constants.backupSpacedRepetitionDataKanji]);
          if (kanji != null) {
            kanji.spacedRepetitionData = newSpacedRepetition;
            await _isar.kanjis.put(kanji);
          }
        }
      });
    } catch (_) {
      return false;
    }

    await getMyDictionaryLists();
    _myDictionaryListsChanged = true;

    return true;
  }

  static Future<void> importDatabase(DictionaryStatus status) async {
    // Copy db_export.zip asset to temporary directory file
    final ByteData byteData =
        await rootBundle.load('assets/dictionary_source/db_export.zip');
    final newDbZipBytes = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    final tempDir = await path_provider.getTemporaryDirectory();
    final File newDbZipFile = File('${tempDir.path}/db_export.zip');
    await newDbZipFile.writeAsBytes(newDbZipBytes);

    // Extract zip to application support directory
    final appSupportDir = await path_provider.getApplicationSupportDirectory();
    await archive.extractFileToDisk(newDbZipFile.path, appSupportDir.path);

    // If upgrading from older database, transfer user data
    if (status == DictionaryStatus.outOfDate) {
      await IsarService.transferUserData();
    }

    // Remove old database file, rename new one, delete temp file
    final File oldDbFile = File('${appSupportDir.path}/default.isar');
    if (await oldDbFile.exists()) {
      await oldDbFile.delete();
      await File('${appSupportDir.path}/default.isar.lock').delete();
    }
    await File('${appSupportDir.path}/db_export.isar')
        .rename('${appSupportDir.path}/default.isar');
    await newDbZipFile.delete();
  }

  // Optional arguments included for testing
  static Future<void> transferUserData({
    Isar? testingOldIsar,
    Isar? testingNewIsar,
  }) async {
    // Open old database and get data
    final oldIsar = testingOldIsar ?? await Isar.open(schemas);
    final path = await IsarService(oldIsar).exportUserData();
    final historyResult = await oldIsar.searchHistoryItems.where().findAll();
    if (testingOldIsar == null) await oldIsar.close();

    // Open new database and set data
    final newIsar = testingNewIsar ??
        await Isar.open(
          schemas,
          name: 'db_export',
        );
    await IsarService(newIsar).importUserData(path);
    File(path).delete();
    await newIsar.writeTxn(() async {
      for (var history in historyResult) {
        await newIsar.searchHistoryItems.put(history);
      }
    });
    if (testingNewIsar == null) await newIsar.close();
  }
}

enum DictionaryStatus {
  valid,
  invalid,
  outOfDate,
}
