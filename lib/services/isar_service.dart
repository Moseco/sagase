import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/search_history_item.dart';
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:sagase/utils/string_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

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

  late final Isar _isar;

  final _kanaKit = const KanaKit().copyWithConfig(passRomaji: true);

  bool _myDictionaryListsChanged = false;
  bool get myDictionaryListsChanged => _myDictionaryListsChanged;
  List<MyDictionaryList>? _myDictionaryLists;
  List<MyDictionaryList>? get myDictionaryLists => _myDictionaryLists;

  IsarService({Isar? isar}) {
    if (isar != null) _isar = isar;
  }

  Future<DictionaryStatus> initialize({bool validate = true}) async {
    try {
      _isar = await Isar.open(
        schemas,
        directory: (await path_provider.getApplicationSupportDirectory()).path,
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
    await _isar.close();
  }

  Future<DictionaryStatus> _validateDictionary() async {
    // If dictionary info does not exist, this is a fresh install
    final dictionaryInfo = await _isar.dictionaryInfos.get(0);
    if (dictionaryInfo == null) {
      return DictionaryStatus.invalid;
    }

    // If database version does not match current, app update includes a new database
    if (dictionaryInfo.version != SagaseDictionaryConstants.dictionaryVersion) {
      return DictionaryStatus.outOfDate;
    }

    // If dictionary count does not match expectation, database probably got corrupted
    if ((await _isar.kanjis.count()) != 13108 ||
        (await _isar.vocabs.count()) != 198094) {
      return DictionaryStatus.invalid;
    }

    return DictionaryStatus.valid;
  }

  Future<List<DictionaryItem>> searchDictionary(
    String value,
    SearchFilter filter,
  ) async {
    // First convert characters to match what would be in the index
    String searchString =
        _kanaKit.toHiragana(value.toLowerCase().romajiToHalfWidth());

    if (filter == SearchFilter.vocab) {
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
    } else {
      return _searchKanji(searchString);
    }
  }

  Future<List<Vocab>> searchVocab(String searchString) async {
    // Check if searching Japanese or romaji text
    if (_kanaKit.isRomaji(searchString)) {
      List<String> split = Isar.splitWords(searchString);

      if (split.isEmpty) return [];
      if (split.length == 1) {
        // Check both readings and definition
        List<Vocab> unsortedRomajiList = await _isar.vocabs
            .where()
            .romajiTextIndexElementStartsWith(split.first)
            .limit(constants.searchQueryLimit)
            .findAll();

        List<Vocab> unsortedDefinitionList = await _isar.vocabs
            .where()
            .definitionIndexElementStartsWith(split.first)
            .limit(constants.searchQueryLimit)
            .findAll();

        // Sort reading result
        // Each nested list is for difference in length compared to search string
        List<List<Vocab>> nestedReadingSortingList = [[], [], [], [], []];

        for (var currentVocab in unsortedRomajiList) {
          int minDifference = 999;
          for (var current in currentVocab.romajiTextIndex) {
            if (current.startsWith(searchString)) {
              minDifference = current.length - searchString.length;
              break;
            }
          }

          nestedReadingSortingList[min(4, minDifference)].add(currentVocab);
        }

        // If found vocab at limit, do exact match search to find possibly missed vocab
        if (unsortedRomajiList.length == constants.searchQueryLimit) {
          final exactMatchList = await _isar.vocabs
              .where()
              .romajiTextIndexElementEqualTo(searchString)
              .limit(constants.searchQueryLimit)
              .findAll();

          // Clear existing list of exact matches before adding new results
          nestedReadingSortingList[0].clear();

          for (var currentVocab in exactMatchList) {
            nestedReadingSortingList[0].add(currentVocab);
          }
        }

        // Sort definition result
        final nestedDefinitionSortingList =
            sortByDefinition(unsortedDefinitionList, searchString);

        // Merge reading and definition lists and then sort
        List<List<Vocab>> nestedSortingList = [[], [], [], [], []];
        Map<int, bool> vocabMap = {};

        for (int i = 0; i < nestedReadingSortingList.length; i++) {
          for (var vocab in nestedReadingSortingList[i]) {
            if (!vocabMap.containsKey(vocab.id)) {
              nestedSortingList[i].add(vocab);
              vocabMap[vocab.id] = true;
            }
          }
          for (var vocab in nestedDefinitionSortingList[i]) {
            if (!vocabMap.containsKey(vocab.id)) {
              nestedSortingList[i].add(vocab);
              vocabMap[vocab.id] = true;
            }
          }
          nestedSortingList[i].sort(_compareVocab);
        }

        return nestedSortingList[0] +
            nestedSortingList[1] +
            nestedSortingList[2] +
            nestedSortingList[3] +
            nestedSortingList[4];
      } else {
        // Check definition only
        late final List<Vocab> unsortedList;
        // If start with 'to ' search as single string
        if (searchString.startsWith('to ')) {
          unsortedList = await _isar.vocabs
              .where()
              .definitionIndexElementStartsWith(searchString)
              .limit(constants.searchQueryLimit)
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

          unsortedList =
              await query.limit(constants.searchQueryLimit).findAll();
        }

        final nestedSortingList = sortByDefinition(unsortedList, searchString);
        // Sort lists
        nestedSortingList[0].sort(_compareVocab);
        nestedSortingList[1].sort(_compareVocab);
        nestedSortingList[2].sort(_compareVocab);
        nestedSortingList[3].sort(_compareVocab);
        nestedSortingList[4].sort(_compareVocab);

        return nestedSortingList[0] +
            nestedSortingList[1] +
            nestedSortingList[2] +
            nestedSortingList[3] +
            nestedSortingList[4];
      }
    } else {
      // Searching with Japanese text
      final unsortedList = await _isar.vocabs
          .where()
          .japaneseTextIndexElementStartsWith(searchString)
          .limit(constants.searchQueryLimit)
          .findAll();

      // Each nested list is for difference in length compared to search string
      List<List<Vocab>> nestedSortingList = [[], [], [], [], [], []];

      for (var currentVocab in unsortedList) {
        int minDifference = 999;
        for (var currentText in currentVocab.japaneseTextIndex) {
          if (currentText.startsWith(searchString)) {
            minDifference = currentText.length - searchString.length;
            break;
          }
        }

        if (minDifference > 0) {
          nestedSortingList[min(5, minDifference + 1)].add(currentVocab);
        } else {
          // Sort exact matches by if search string is in the primary kanji/reading pair
          if (currentVocab.kanjiReadingPairs[0].kanjiWritings?[0].kanji ==
                  searchString ||
              currentVocab.kanjiReadingPairs[0].readings[0].reading ==
                  searchString) {
            nestedSortingList[0].add(currentVocab);
          } else {
            nestedSortingList[1].add(currentVocab);
          }
        }
      }

      // If found vocab at limit, do exact match search to find possibly missed vocab
      if (unsortedList.length == constants.searchQueryLimit) {
        final exactMatchList = await _isar.vocabs
            .where()
            .japaneseTextIndexElementEqualTo(searchString)
            .limit(constants.searchQueryLimit)
            .findAll();

        // Clear existing list of exact matches
        nestedSortingList[0].clear();
        nestedSortingList[1].clear();

        for (var currentVocab in exactMatchList) {
          // Sort by if search string is in the primary kanji/reading pair
          if (currentVocab.kanjiReadingPairs[0].kanjiWritings?[0].kanji ==
                  searchString ||
              currentVocab.kanjiReadingPairs[0].readings[0].reading ==
                  searchString) {
            nestedSortingList[0].add(currentVocab);
          } else {
            nestedSortingList[1].add(currentVocab);
          }
        }
      }

      // Sort lists
      nestedSortingList[0].sort(_compareVocab);
      nestedSortingList[1].sort(_compareVocab);
      nestedSortingList[2].sort(_compareVocab);
      nestedSortingList[3].sort(_compareVocab);
      nestedSortingList[4].sort(_compareVocab);
      nestedSortingList[5].sort(_compareVocab);

      return nestedSortingList[0] +
          nestedSortingList[1] +
          nestedSortingList[2] +
          nestedSortingList[3] +
          nestedSortingList[4] +
          nestedSortingList[5];
    }
  }

  // Function to be used with list.sort
  // Compare by frequency score and commonness
  // b - a so that the list will be sorted from highest to lowest
  int _compareVocab(Vocab a, Vocab b) {
    return b.frequencyScore +
        (b.commonWord ? 1 : 0) -
        a.frequencyScore -
        (a.commonWord ? 1 : 0);
  }

  @visibleForTesting
  List<List<Vocab>> sortByDefinition(List<Vocab> unsortedList, String query) {
    // Each nested list is for quality of match
    //    Nested list 0: definition 1 sub-definition contains only query
    //    Nested list 1: definition 1 sub-definition starts with query
    //    Nested list 2: exact match in definition 1 other than start
    //    Nested list 3: exact match in definition 2+
    //    Nested list 4: no match found
    List<List<Vocab>> nestedSortingList = [[], [], [], [], []];

    // Match word starting with query
    String escapedQuery = RegExp.escape(query);
    final queryRegExp = RegExp(
      r'\b' + escapedQuery,
      caseSensitive: false,
    );
    // Match query at the start of string or after ';' and ignore leading/trailing parenthesis
    final startingRegExp = RegExp(
      r'(^|(; ))(\([^)]*\) )?\b' + escapedQuery + r'( \([^)]*\))?',
      caseSensitive: false,
    );
    // Same as above but with end of string or followed by another sub-definition
    final startingEndRegExp = RegExp(
      startingRegExp.pattern + r'($|;)',
      caseSensitive: false,
    );

    for (var vocab in unsortedList) {
      bool noMatch = true;
      for (int i = 0; i < vocab.definitions.length; i++) {
        final definition = vocab.definitions[i].definition;
        if (definition.contains(queryRegExp)) {
          noMatch = false;
          if (i == 0) {
            int foundIndex = definition.indexOf(startingRegExp);
            if (foundIndex != -1) {
              if (definition.contains(startingEndRegExp, foundIndex)) {
                nestedSortingList[0].add(vocab);
              } else {
                nestedSortingList[1].add(vocab);
              }
            } else {
              nestedSortingList[2].add(vocab);
            }
          } else {
            nestedSortingList[3].add(vocab);
          }
          break;
        }
      }
      if (noMatch) nestedSortingList[4].add(vocab);
    }

    return nestedSortingList;
  }

  Future<List<Kanji>> _searchKanji(String searchString) async {
    // If searching single kanji, just return it
    if (searchString.length == 1 &&
        searchString.contains(constants.kanjiRegExp)) {
      final kanji = await _isar.kanjis.getByKanji(searchString);
      if (kanji != null) return [kanji];
    }

    // Each nested list is for difference in length compared to search string
    List<List<Kanji>> nestedSortingList = [[], [], [], [], []];

    // Search reading
    final unsortedReadingList = await _isar.kanjis
        .where()
        .readingIndexElementStartsWith(searchString)
        .limit(constants.searchQueryLimit)
        .findAll();

    for (var kanji in unsortedReadingList) {
      int minDifference = 999;
      for (var reading in kanji.readingIndex!) {
        if (reading.length >= minDifference) continue;
        if (reading.startsWith(searchString)) {
          minDifference = reading.length - searchString.length;
        }
      }

      nestedSortingList[min(4, minDifference)].add(kanji);
    }

    // If found kanji at limit, do exact match search to find possibly missed kanji
    if (unsortedReadingList.length == constants.searchQueryLimit) {
      final exactMatchList = await _isar.kanjis
          .where()
          .readingIndexElementEqualTo(searchString)
          .limit(constants.searchQueryLimit)
          .findAll();

      // Clear existing list of exact matches
      nestedSortingList[0].clear();

      for (var kanji in exactMatchList) {
        nestedSortingList[0].add(kanji);
      }
    }

    // Search meaning
    final unsortedMeaningList = await _isar.kanjis
        .where()
        .meaningsElementStartsWith(searchString)
        .limit(constants.searchQueryLimit)
        .findAll();

    for (var kanji in unsortedMeaningList) {
      int minDifference = 999;
      for (var meaning in kanji.meanings!) {
        if (meaning.length >= minDifference) continue;
        if (meaning.startsWith(searchString)) {
          minDifference = meaning.length - searchString.length;
        }
      }

      nestedSortingList[min(4, minDifference)].add(kanji);
    }

    // Sort lists
    nestedSortingList[0].sort(_compareKanji);
    nestedSortingList[1].sort(_compareKanji);
    nestedSortingList[2].sort(_compareKanji);
    nestedSortingList[3].sort(_compareKanji);
    nestedSortingList[4].sort(_compareKanji);

    return nestedSortingList[0] +
        nestedSortingList[1] +
        nestedSortingList[2] +
        nestedSortingList[3] +
        nestedSortingList[4];
  }

  // Function to be used with list.sort
  // Compare by frequency of kanji
  // a - b so that the list will be sorted from lowest to highest
  int _compareKanji(Kanji a, Kanji b) {
    return (a.frequency ?? 9999) - (b.frequency ?? 9999);
  }

  Future<Vocab?> getVocab(int id) async {
    return _isar.vocabs.get(id);
  }

  Future<List<Vocab>> getVocabByJapaneseTextToken(
    JapaneseTextToken token,
  ) async {
    final baseQuery = _isar.vocabs.where().japaneseTextIndexElementEqualTo(
        _kanaKit.toHiragana(token.base.toLowerCase().romajiToHalfWidth()));

    late List<Vocab> results;
    // If text contains kanji, add filter for reading
    if (token.base.contains(constants.kanjiRegExp)) {
      results = await baseQuery
          .filter()
          .japaneseTextIndexElementEqualTo(_kanaKit
              .toHiragana(token.baseReading.toLowerCase().romajiToHalfWidth()))
          .findAll();

      // If nothing was found, try again with only base query
      if (results.isEmpty) results = await baseQuery.findAll();
    } else {
      results = await baseQuery.findAll();
    }

    if (results.length <= 1) return results;

    // Check part of speech
    if (token.pos != null) {
      List<Vocab> list = List.from(results);
      for (int i = 0; i < list.length; i++) {
        bool removeCurrent = true;
        for (var definition in list[i].definitions) {
          if (definition.pos != null && definition.pos!.contains(token.pos)) {
            removeCurrent = false;
            break;
          }
        }
        if (removeCurrent) list.removeAt(i--);
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
        if (list[i].kanjiReadingPairs[0].kanjiWritings != null &&
            !list[i].isUsuallyKanaAlone()) {
          list.removeAt(i--);
        }
      }

      if (list.length == 1) {
        return list;
      } else if (list.isEmpty) {
        list = List.from(results);
      }

      // Remove vocab with reading not in the first kanji reading pair
      for (int i = 0; i < list.length; i++) {
        bool removeCurrent = true;
        for (var reading in list[i].kanjiReadingPairs[0].readings) {
          if (token.base == reading.reading) {
            removeCurrent = false;
            break;
          }
        }
        if (removeCurrent) list.removeAt(i--);
      }

      if (list.isNotEmpty) return list..sort(_compareVocab);
    }

    return results..sort(_compareVocab);
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
      dictionaryVersion: SagaseDictionaryConstants.dictionaryVersion,
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
        for (var myListMap
            in backupMap[SagaseDictionaryConstants.backupMyDictionaryLists]) {
          final newMyList = MyDictionaryList.fromBackupJson(myListMap);

          // Add vocab
          for (var vocabId in myListMap[
              SagaseDictionaryConstants.backupMyDictionaryListVocab]) {
            final vocab = await _isar.vocabs.get(vocabId);
            if (vocab != null) newMyList.vocabLinks.add(vocab);
          }

          // Add kanji
          for (var kanjiId in myListMap[
              SagaseDictionaryConstants.backupMyDictionaryListKanji]) {
            final kanji = await _isar.kanjis.getByKanji(kanjiId);
            if (kanji != null) newMyList.kanjiLinks.add(kanji);
          }

          await _isar.myDictionaryLists.put(newMyList);
          await newMyList.vocabLinks.save();
          await newMyList.kanjiLinks.save();
        }

        // Flashcard sets
        for (var flashcardSetMap
            in backupMap[SagaseDictionaryConstants.backupFlashcardSets]) {
          final newFlashcardSet = FlashcardSet.fromBackupJson(flashcardSetMap);

          // Predefined dictionary lists
          for (var predefinedId in flashcardSetMap[SagaseDictionaryConstants
              .backupFlashcardSetPredefinedDictionaryLists]) {
            final predefinedDictionaryList =
                await _isar.predefinedDictionaryLists.get(predefinedId);
            if (predefinedDictionaryList != null) {
              newFlashcardSet.predefinedDictionaryListLinks
                  .add(predefinedDictionaryList);
            }
          }

          // My dictionary lists
          for (var myId in flashcardSetMap[
              SagaseDictionaryConstants.backupFlashcardSetMyDictionaryLists]) {
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
        for (var spacedRepetitionMap in backupMap[
            SagaseDictionaryConstants.backupVocabSpacedRepetitionData]) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(spacedRepetitionMap);
          final vocab = await _isar.vocabs.get(spacedRepetitionMap[
              SagaseDictionaryConstants.backupSpacedRepetitionDataVocabId]);
          if (vocab != null) {
            vocab.spacedRepetitionData = newSpacedRepetition;
            await _isar.vocabs.put(vocab);
          }
        }

        // Kanji spaced repetition data
        for (var spacedRepetitionMap in backupMap[
            SagaseDictionaryConstants.backupKanjiSpacedRepetitionData]) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(spacedRepetitionMap);
          final kanji = await _isar.kanjis.getByKanji(spacedRepetitionMap[
              SagaseDictionaryConstants.backupSpacedRepetitionDataKanji]);
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

    // Start isolate to handle import
    final rootIsolateToken = RootIsolateToken.instance!;
    await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

      final newDbZipBytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final tempDir = await path_provider.getTemporaryDirectory();
      final File newDbZipFile = File('${tempDir.path}/db_export.zip');
      await newDbZipFile.writeAsBytes(newDbZipBytes);

      // Extract zip to application support directory
      final appSupportDir =
          await path_provider.getApplicationSupportDirectory();
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
    });
  }

  // Optional arguments included for testing
  static Future<void> transferUserData({
    Isar? testingOldIsar,
    Isar? testingNewIsar,
  }) async {
    // Open old database and get data
    final oldIsar = testingOldIsar ??
        await Isar.open(
          schemas,
          directory:
              (await path_provider.getApplicationSupportDirectory()).path,
        );
    final path = await IsarService(isar: oldIsar).exportUserData();
    final historyResult = await oldIsar.searchHistoryItems.where().findAll();
    if (testingOldIsar == null) await oldIsar.close();

    // Open new database and set data
    final newIsar = testingNewIsar ??
        await Isar.open(
          schemas,
          directory:
              (await path_provider.getApplicationSupportDirectory()).path,
          name: 'db_export',
        );
    await IsarService(isar: newIsar).importUserData(path);
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

enum SearchFilter {
  vocab,
  kanji,
}
