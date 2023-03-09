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
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:flutter/foundation.dart' show compute;
import 'package:sagase/utils/string_utils.dart';

class IsarService {
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

    final isar = await Isar.open(
      [
        DictionaryInfoSchema,
        VocabSchema,
        KanjiSchema,
        PredefinedDictionaryListSchema,
        MyDictionaryListSchema,
        FlashcardSetSchema,
        KanjiRadicalSchema,
        SearchHistoryItemSchema,
      ],
    );

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

  Future<void> updateFlashcardSet(FlashcardSet flashcardSet) async {
    flashcardSet.timestamp = DateTime.now();
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
    // Load all vocab and kanji and add to maps to avoid duplicates
    await flashcardSet.predefinedDictionaryListLinks.load();
    await flashcardSet.myDictionaryListLinks.load();

    Map<int, Vocab> vocabMap = {};
    Map<String, Kanji> kanjiMap = {};

    // Get predefined lists vocab and kanji
    for (int i = 0;
        i < flashcardSet.predefinedDictionaryListLinks.length;
        i++) {
      await flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .vocabLinks
          .load();
      await flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .kanjiLinks
          .load();

      for (var vocab in flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .vocabLinks) {
        vocabMap[vocab.id] = vocab;
      }
      for (var kanji in flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .kanjiLinks) {
        kanjiMap[kanji.kanji] = kanji;
      }
    }

    // Get my lists vocab and kanji
    for (int i = 0; i < flashcardSet.myDictionaryListLinks.length; i++) {
      await flashcardSet.myDictionaryListLinks.elementAt(i).vocabLinks.load();
      await flashcardSet.myDictionaryListLinks.elementAt(i).kanjiLinks.load();

      for (var vocab
          in flashcardSet.myDictionaryListLinks.elementAt(i).vocabLinks) {
        vocabMap[vocab.id] = vocab;
      }
      for (var kanji
          in flashcardSet.myDictionaryListLinks.elementAt(i).kanjiLinks) {
        kanjiMap[kanji.kanji] = kanji;
      }
    }

    await _isar.writeTxn(() async {
      // Reset vocab spaced repetition data
      for (var vocab in vocabMap.values) {
        vocab.spacedRepetitionData = null;
        await _isar.vocabs.put(vocab);
      }

      // Reset kanji spaced repetition data
      for (var kanji in kanjiMap.values) {
        kanji.spacedRepetitionData = null;
        await _isar.kanjis.put(kanji);
      }
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
            .offset(20)
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
      await compute(
        IsarService.transferUserDataIsolate,
        null,
      );
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
  static Future<void> transferUserDataIsolate(
    _, {
    Isar? testingOldIsar,
    Isar? testingNewIsar,
  }) async {
    final oldIsar = testingOldIsar ??
        await Isar.open(
          [
            DictionaryInfoSchema,
            VocabSchema,
            KanjiSchema,
            PredefinedDictionaryListSchema,
            MyDictionaryListSchema,
            FlashcardSetSchema,
            KanjiRadicalSchema,
          ],
        );

    final newIsar = testingNewIsar ??
        await Isar.open(
          [
            DictionaryInfoSchema,
            VocabSchema,
            KanjiSchema,
            PredefinedDictionaryListSchema,
            MyDictionaryListSchema,
            FlashcardSetSchema,
            KanjiRadicalSchema,
          ],
          name: 'db_export',
        );

    // Transfer my lists
    final myListResult = await oldIsar.myDictionaryLists.where().findAll();
    List<MyDictionaryList> newMyLists = [];
    for (var oldDbMyList in myListResult) {
      MyDictionaryList newDbMyList = MyDictionaryList()
        ..id = oldDbMyList.id!
        ..name = oldDbMyList.name
        ..timestamp = oldDbMyList.timestamp;

      newMyLists.add(newDbMyList);

      await oldDbMyList.vocabLinks.load();
      for (var oldDbVocab in oldDbMyList.vocabLinks) {
        Vocab? newDbVocab = await newIsar.vocabs.get(oldDbVocab.id);
        if (newDbVocab != null) newDbMyList.vocabLinks.add(newDbVocab);
      }

      await oldDbMyList.kanjiLinks.load();
      for (var oldDbKanji in oldDbMyList.kanjiLinks) {
        Kanji? newDbKanji = await newIsar.kanjis.getByKanji(oldDbKanji.kanji);
        if (newDbKanji != null) newDbMyList.kanjiLinks.add(newDbKanji);
      }
    }

    await newIsar.writeTxn(() async {
      for (var myList in newMyLists) {
        await newIsar.myDictionaryLists.put(myList);
        await myList.vocabLinks.save();
        await myList.kanjiLinks.save();
      }
    });

    // Transfer flashcard sets
    final flashcardSetResult = await oldIsar.flashcardSets.where().findAll();
    List<FlashcardSet> newFlashcardSets = [];
    for (var oldDbFlashcardSet in flashcardSetResult) {
      FlashcardSet newDbFlashcardSet = FlashcardSet()
        ..id = oldDbFlashcardSet.id
        ..name = oldDbFlashcardSet.name
        ..usingSpacedRepetition = oldDbFlashcardSet.usingSpacedRepetition
        ..vocabShowReading = oldDbFlashcardSet.vocabShowReading
        ..vocabShowReadingIfRareKanji =
            oldDbFlashcardSet.vocabShowReadingIfRareKanji
        ..kanjiShowReading = oldDbFlashcardSet.kanjiShowReading
        ..timestamp = oldDbFlashcardSet.timestamp;

      newFlashcardSets.add(newDbFlashcardSet);

      await oldDbFlashcardSet.predefinedDictionaryListLinks.load();
      for (var oldDbPredefinedList
          in oldDbFlashcardSet.predefinedDictionaryListLinks) {
        PredefinedDictionaryList? newDbPredefinedList = await newIsar
            .predefinedDictionaryLists
            .get(oldDbPredefinedList.id!);
        if (newDbPredefinedList != null) {
          newDbFlashcardSet.predefinedDictionaryListLinks
              .add(newDbPredefinedList);
        }
      }

      await oldDbFlashcardSet.myDictionaryListLinks.load();
      for (var oldDbMyList in oldDbFlashcardSet.myDictionaryListLinks) {
        MyDictionaryList? newDbMyList =
            await newIsar.myDictionaryLists.get(oldDbMyList.id!);
        if (newDbMyList != null) {
          newDbFlashcardSet.myDictionaryListLinks.add(newDbMyList);
        }
      }
    }

    await newIsar.writeTxn(() async {
      for (var flashcardSet in newFlashcardSets) {
        await newIsar.flashcardSets.put(flashcardSet);
        await flashcardSet.predefinedDictionaryListLinks.save();
        await flashcardSet.myDictionaryListLinks.save();
      }
    });

    // Transfer vocab spaced repetition data
    final vocabResult =
        await oldIsar.vocabs.filter().spacedRepetitionDataIsNotNull().findAll();
    await newIsar.writeTxn(() async {
      for (var oldDbVocab in vocabResult) {
        Vocab? newDbVocab = await newIsar.vocabs.get(oldDbVocab.id);
        if (newDbVocab != null) {
          newDbVocab.spacedRepetitionData = oldDbVocab.spacedRepetitionData;
          await newIsar.vocabs.put(newDbVocab);
        }
      }
    });

    // Transfer kanji spaced repetition data
    final kanjiResult =
        await oldIsar.kanjis.filter().spacedRepetitionDataIsNotNull().findAll();
    await newIsar.writeTxn(() async {
      for (var oldDbKanji in kanjiResult) {
        Kanji? newDbKanji = await newIsar.kanjis.getByKanji(oldDbKanji.kanji);
        if (newDbKanji != null) {
          newDbKanji.spacedRepetitionData = oldDbKanji.spacedRepetitionData;
          await newIsar.kanjis.put(newDbKanji);
        }
      }
    });

    if (testingOldIsar == null) await oldIsar.close();
    if (testingNewIsar == null) await newIsar.close();
  }
}

enum DictionaryStatus {
  valid,
  invalid,
  outOfDate,
}
