import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/material.dart' show StringCharacters, visibleForTesting;
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/search_history_item.dart';
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:path/path.dart' as path;

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
        (await _isar.vocabs.count()) != 207297) {
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
      if (searchString.characters.length == 1 &&
          searchString.contains(constants.kanjiRegExp)) {
        kanji = await _isar.kanjis.get(searchString.kanjiCodePoint());
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
        // If starts with 'to ' merge first and second word
        if (split[0] == 'to') split[0] = '${split[0]} ${split.removeAt(1)}';

        if (split.length == 1) {
          // Search is only 'to ' and another word, search as single string
          unsortedList = await _isar.vocabs
              .where()
              .definitionIndexElementStartsWith(split.first)
              .limit(constants.searchQueryLimit)
              .findAll();
        } else {
          // Do a where check with index and follow up with filters
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
    if (searchString.characters.length == 1 &&
        searchString.contains(constants.kanjiRegExp)) {
      final kanji = await _isar.kanjis.get(searchString.kanjiCodePoint());
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

  Future<List<Vocab>> getVocabList(List<int> list) async {
    if (list.isEmpty) return [];
    return (await _isar.vocabs.getAll(list)).cast<Vocab>();
  }

  Future<List<Vocab>> getVocabByJapaneseTextToken(
    JapaneseTextToken token,
  ) async {
    // If proper noun skip search
    if (token.pos == PartOfSpeech.nounProper) return [];

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
      outer:
      for (int i = 0; i < list.length; i++) {
        for (var reading in list[i].kanjiReadingPairs[0].readings) {
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

  Future<Kanji?> getKanji(String kanji) async {
    return _isar.kanjis.get(kanji.kanjiCodePoint());
  }

  Future<List<Kanji>> getKanjiList(List<int> list) async {
    if (list.isEmpty) return [];
    return (await _isar.kanjis.getAll(list)).cast<Kanji>();
  }

  Future<List<Kanji>> getKanjiWithRadical(String radical) async {
    return _isar.kanjis
        .where()
        .radicalEqualTo(radical)
        .sortByStrokeCount()
        .findAll();
  }

  Future<PredefinedDictionaryList?> getPredefinedDictionaryList(int id) async {
    return _isar.predefinedDictionaryLists.get(id);
  }

  Future<List<PredefinedDictionaryList>> getPredefinedDictionaryLists(
    List<int> list,
  ) async {
    if (list.isEmpty) return [];
    return (await _isar.predefinedDictionaryLists.getAll(list))
        .cast<PredefinedDictionaryList>();
  }

  Future<MyDictionaryList> createMyDictionaryList(String name) async {
    final list = MyDictionaryList()
      ..name = name
      ..timestamp = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.myDictionaryLists.put(list);
    });

    return list;
  }

  Future<void> updateMyDictionaryList(MyDictionaryList list) async {
    list.timestamp = DateTime.now();
    return _isar.writeTxn(() async {
      await _isar.myDictionaryLists.put(list);
    });
  }

  Future<MyDictionaryList?> getMyDictionaryList(int id) async {
    return _isar.myDictionaryLists.get(id);
  }

  Future<List<MyDictionaryList>> getMyDictionaryLists(
    List<int> list,
  ) async {
    if (list.isEmpty) return [];
    return (await _isar.myDictionaryLists.getAll(list))
        .cast<MyDictionaryList>();
  }

  Future<List<MyDictionaryList>> getAllMyDictionaryLists() async {
    return _isar.myDictionaryLists.where().sortByTimestampDesc().findAll();
  }

  Stream<void> watchMyDictionaryList(int id) {
    return _isar.myDictionaryLists.watchObjectLazy(id);
  }

  Stream<void> watchMyDictionaryLists() {
    return _isar.myDictionaryLists.watchLazy();
  }

  Future<void> deleteMyDictionaryList(MyDictionaryList list) async {
    return _isar.writeTxn(() async {
      // Find flashcard sets using this list
      final flashcardSets = await _isar.flashcardSets
          .filter()
          .myDictionaryListsElementEqualTo(list.id)
          .findAll();

      for (var flashcardSet in flashcardSets) {
        flashcardSet.myDictionaryLists = flashcardSet.myDictionaryLists.toList()
          ..remove(list.id);
        await _isar.flashcardSets.put(flashcardSet);
      }

      // Delete the list
      await _isar.myDictionaryLists.delete(list.id);
    });
  }

  Future<void> addVocabToMyDictionaryList(
    MyDictionaryList list,
    Vocab vocab,
  ) async {
    if (list.vocab.contains(vocab.id)) return;
    list.vocab = list.vocab.toList()..insert(0, vocab.id);
    return updateMyDictionaryList(list);
  }

  Future<void> removeVocabFromMyDictionaryList(
    MyDictionaryList list,
    Vocab vocab,
  ) async {
    list.vocab = list.vocab.toList()..remove(vocab.id);
    return updateMyDictionaryList(list);
  }

  Future<void> addKanjiToMyDictionaryList(
    MyDictionaryList list,
    Kanji kanji,
  ) async {
    if (list.kanji.contains(kanji.id)) return;
    list.kanji = list.kanji.toList()..insert(0, kanji.id);
    return updateMyDictionaryList(list);
  }

  Future<void> removeKanjiFromMyDictionaryList(
    MyDictionaryList list,
    Kanji kanji,
  ) async {
    list.kanji = list.kanji.toList()..remove(kanji.id);
    return updateMyDictionaryList(list);
  }

  Future<bool> isVocabInMyDictionaryLists(Vocab vocab) async {
    return (await _isar.myDictionaryLists
            .filter()
            .vocabElementEqualTo(vocab.id)
            .findFirst()) !=
        null;
  }

  Future<bool> isKanjiInMyDictionaryLists(Kanji kanji) async {
    return (await _isar.myDictionaryLists
            .filter()
            .kanjiElementEqualTo(kanji.id)
            .findFirst()) !=
        null;
  }

  Future<MyDictionaryList?> importMyDictionaryList(String path) async {
    try {
      // Parse file
      final myList = MyDictionaryList.fromShareJson(
        await File(path).readAsString(),
      );

      if (myList == null) return null;

      // Sanitize name
      myList.name = sanitizeName(myList.name);

      // Remove missing vocab and kanji
      final vocab = await _isar.vocabs.getAll(myList.vocab);
      vocab.toList().removeWhere((element) => element == null);
      myList.vocab = vocab.map((e) => e!.id).toList();

      final kanji = await _isar.kanjis.getAll(myList.kanji);
      kanji.toList().removeWhere((element) => element == null);
      myList.kanji = kanji.map((e) => e!.id).toList();

      // Add to database
      await updateMyDictionaryList(myList);

      return myList;
    } catch (_) {
      return null;
    }
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

  Future<void> resetFlashcardSetSpacedRepetitionData(
    FlashcardSet flashcardSet,
  ) async {
    await _isar.writeTxn(() async {
      // Predefined lists
      for (var predefinedId in flashcardSet.predefinedDictionaryLists) {
        final list = await getPredefinedDictionaryList(predefinedId);
        if (list == null) continue;
        // Reset vocab
        final vocabList = await getVocabList(list.vocab);
        for (var vocab in vocabList) {
          switch (flashcardSet.frontType) {
            case FrontType.japanese:
              if (vocab.spacedRepetitionData != null) {
                vocab.spacedRepetitionData = null;
                await _isar.vocabs.put(vocab);
              }
              break;
            case FrontType.english:
              if (vocab.spacedRepetitionDataEnglish != null) {
                vocab.spacedRepetitionDataEnglish = null;
                await _isar.vocabs.put(vocab);
              }
              break;
          }
        }

        // Reset kanji
        final kanjiList = await getKanjiList(list.kanji);
        for (var kanji in kanjiList) {
          switch (flashcardSet.frontType) {
            case FrontType.japanese:
              if (kanji.spacedRepetitionData != null) {
                kanji.spacedRepetitionData = null;
                await _isar.kanjis.put(kanji);
              }
              break;
            case FrontType.english:
              if (kanji.spacedRepetitionDataEnglish != null) {
                kanji.spacedRepetitionDataEnglish = null;
                await _isar.kanjis.put(kanji);
              }
              break;
          }
        }
      }

      // My lists
      for (var myListId in flashcardSet.myDictionaryLists) {
        final list = await getMyDictionaryList(myListId);
        if (list == null) continue;
        // Reset vocab
        final vocabList = await getVocabList(list.vocab);
        for (var vocab in vocabList) {
          switch (flashcardSet.frontType) {
            case FrontType.japanese:
              if (vocab.spacedRepetitionData != null) {
                vocab.spacedRepetitionData = null;
                await _isar.vocabs.put(vocab);
              }
              break;
            case FrontType.english:
              if (vocab.spacedRepetitionDataEnglish != null) {
                vocab.spacedRepetitionDataEnglish = null;
                await _isar.vocabs.put(vocab);
              }
              break;
          }
        }

        // Reset kanji
        final kanjiList = await getKanjiList(list.kanji);
        for (var kanji in kanjiList) {
          switch (flashcardSet.frontType) {
            case FrontType.japanese:
              if (kanji.spacedRepetitionData != null) {
                kanji.spacedRepetitionData = null;
                await _isar.kanjis.put(kanji);
              }
              break;
            case FrontType.english:
              if (kanji.spacedRepetitionDataEnglish != null) {
                kanji.spacedRepetitionDataEnglish = null;
                await _isar.kanjis.put(kanji);
              }
              break;
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

  Future<void> setSpacedRepetitionDataToNull(
    DictionaryItem item,
    FrontType frontType,
  ) async {
    // Get instance, set spaced repetition data to null, then update database
    return _isar.writeTxn(() async {
      if (item is Vocab) {
        var vocab = await _isar.vocabs.get(item.id);
        switch (frontType) {
          case FrontType.japanese:
            vocab!.spacedRepetitionData = null;
            break;
          case FrontType.english:
            vocab!.spacedRepetitionDataEnglish = null;
            break;
        }
        await _isar.vocabs.put(vocab);
      } else {
        var kanji = await _isar.kanjis.get(item.id);
        switch (frontType) {
          case FrontType.japanese:
            kanji!.spacedRepetitionData = null;
            break;
          case FrontType.english:
            kanji!.spacedRepetitionDataEnglish = null;
            break;
        }
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

  Future<String?> exportUserData() async {
    try {
      // My dictionary lists
      List<String> myDictionaryListBackups = [];
      final myLists = await getAllMyDictionaryLists();
      for (var myList in myLists) {
        myDictionaryListBackups.add(myList.toBackupJson());
      }

      // Flashcard sets
      List<String> flashcardSetBackups = [];
      final flashcardSets = await getFlashcardSets();
      for (var flashcardSet in flashcardSets) {
        flashcardSetBackups.add(flashcardSet.toBackupJson());
      }

      // Vocab spaced repetition data
      Map<String, String> vocabSpacedRepetitionDataBackups = {};
      final vocabSpacedRepetitionData =
          await _isar.vocabs.filter().spacedRepetitionDataIsNotNull().findAll();
      for (var vocab in vocabSpacedRepetitionData) {
        vocabSpacedRepetitionDataBackups[vocab.id.toString()] =
            vocab.spacedRepetitionData!.toBackupJson();
      }

      // Vocab spaced repetition data English
      Map<String, String> vocabSpacedRepetitionDataEnglishBackups = {};
      final vocabSpacedRepetitionDataEnglish = await _isar.vocabs
          .filter()
          .spacedRepetitionDataEnglishIsNotNull()
          .findAll();
      for (var vocab in vocabSpacedRepetitionDataEnglish) {
        vocabSpacedRepetitionDataEnglishBackups[vocab.id.toString()] =
            vocab.spacedRepetitionDataEnglish!.toBackupJson();
      }

      // Kanji spaced repetition data
      Map<String, String> kanjiSpacedRepetitionDataBackups = {};
      final kanjiSpacedRepetitionData =
          await _isar.kanjis.filter().spacedRepetitionDataIsNotNull().findAll();
      for (var kanji in kanjiSpacedRepetitionData) {
        kanjiSpacedRepetitionDataBackups[kanji.id.toString()] =
            kanji.spacedRepetitionData!.toBackupJson();
      }

      // Kanji spaced repetition data English
      Map<String, String> kanjiSpacedRepetitionDataEnglishBackups = {};
      final kanjiSpacedRepetitionDataEnglish = await _isar.kanjis
          .filter()
          .spacedRepetitionDataEnglishIsNotNull()
          .findAll();
      for (var kanji in kanjiSpacedRepetitionDataEnglish) {
        kanjiSpacedRepetitionDataEnglishBackups[kanji.id.toString()] =
            kanji.spacedRepetitionDataEnglish!.toBackupJson();
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

      await _isar.writeTxn(() async {
        // My dictionary lists
        for (var myListJson in userBackup.myDictionaryLists) {
          final myList = MyDictionaryList.fromBackupJson(myListJson);
          // Confirm vocab exists
          final vocabList = (await _isar.vocabs.getAll(myList.vocab)).toList();
          for (int i = 0; i < vocabList.length; i++) {
            if (vocabList[i] == null) {
              vocabList.removeAt(i);
              myList.vocab.removeAt(i);
              i--;
            }
          }
          // Confirm kanji exists
          final kanjiList = (await _isar.kanjis.getAll(myList.kanji)).toList();
          for (int i = 0; i < kanjiList.length; i++) {
            if (kanjiList[i] == null) {
              kanjiList.removeAt(i);
              myList.kanji.removeAt(i);
              i--;
            }
          }
          await _isar.myDictionaryLists.put(myList);
        }

        // Flashcard sets
        for (var flashcardSetJson in userBackup.flashcardSets) {
          final flashcardSet = FlashcardSet.fromBackupJson(flashcardSetJson);
          // Confirm predefined lists exist
          for (int i = 0;
              i < flashcardSet.predefinedDictionaryLists.length;
              i++) {
            if ((await _isar.predefinedDictionaryLists
                    .get(flashcardSet.predefinedDictionaryLists[i])) ==
                null) {
              flashcardSet.predefinedDictionaryLists.removeAt(i--);
            }
          }
          // Confirm my lists exist
          for (int i = 0; i < flashcardSet.myDictionaryLists.length; i++) {
            if ((await _isar.myDictionaryLists
                    .get(flashcardSet.myDictionaryLists[i])) ==
                null) {
              flashcardSet.myDictionaryLists.removeAt(i--);
            }
          }
          await _isar.flashcardSets.put(flashcardSet);
        }

        // Vocab spaced repetition data
        for (var entry in userBackup.vocabSpacedRepetitionData.entries) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(jsonDecode(entry.value));
          final vocab = await _isar.vocabs.get(int.parse(entry.key));
          if (vocab != null) {
            vocab.spacedRepetitionData = newSpacedRepetition;
            await _isar.vocabs.put(vocab);
          }
        }

        // Vocab spaced repetition data English
        for (var entry in userBackup.vocabSpacedRepetitionDataEnglish.entries) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(jsonDecode(entry.value));
          final vocab = await _isar.vocabs.get(int.parse(entry.key));
          if (vocab != null) {
            vocab.spacedRepetitionDataEnglish = newSpacedRepetition;
            await _isar.vocabs.put(vocab);
          }
        }

        // Kanji spaced repetition data
        for (var entry in userBackup.kanjiSpacedRepetitionData.entries) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(jsonDecode(entry.value));
          final kanji = await _isar.kanjis.get(int.parse(entry.key));
          if (kanji != null) {
            kanji.spacedRepetitionData = newSpacedRepetition;
            await _isar.kanjis.put(kanji);
          }
        }

        // Kanji spaced repetition data English
        for (var entry in userBackup.kanjiSpacedRepetitionDataEnglish.entries) {
          final newSpacedRepetition =
              SpacedRepetitionData.fromBackupJson(jsonDecode(entry.value));
          final kanji = await _isar.kanjis.get(int.parse(entry.key));
          if (kanji != null) {
            kanji.spacedRepetitionDataEnglish = newSpacedRepetition;
            await _isar.kanjis.put(kanji);
          }
        }
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<ImportResult> importDatabase(DictionaryStatus status) async {
    try {
      // Start isolate to handle import
      final rootIsolateToken = RootIsolateToken.instance!;
      return Isolate.run(() async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

        final newDbZipFile = File(path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          constants.baseDictionaryZip,
        ));

        // Extract zip to application support directory
        final appSupportDir =
            await path_provider.getApplicationSupportDirectory();
        await archive.extractFileToDisk(newDbZipFile.path, appSupportDir.path);

        // If upgrading from older database, transfer user data
        if (status == DictionaryStatus.outOfDate) {
          bool transferResult = await IsarService.transferUserData();
          if (!transferResult) return ImportResult.transferDataFailed;
        }

        // Remove old database files
        final oldDbFile = File(path.join(appSupportDir.path, 'default.isar'));
        final oldDbLockFile =
            File(path.join(appSupportDir.path, 'default.isar.lock'));
        if (await oldDbFile.exists()) await oldDbFile.delete();
        if (await oldDbLockFile.exists()) await oldDbLockFile.delete();

        // Rename new database
        await File(path.join(appSupportDir.path, 'base_dictionary.isar'))
            .rename(path.join(appSupportDir.path, 'default.isar'));

        // Delete temp files
        final newDbLockFile =
            File(path.join(appSupportDir.path, 'base_dictionary.isar.lock'));
        if (await newDbLockFile.exists()) await newDbLockFile.delete();

        await newDbZipFile.delete();

        return ImportResult.success;
      });
    } catch (_) {
      return ImportResult.failed;
    }
  }

  // Optional arguments included for testing
  static Future<bool> transferUserData({
    Isar? testingOldIsar,
    Isar? testingNewIsar,
  }) async {
    Isar? isar;
    try {
      final supportDir = await path_provider.getApplicationSupportDirectory();

      // Open old database and get data
      isar = testingOldIsar ??
          await Isar.open(
            schemas,
            directory: supportDir.path,
          );
      final backupPath = await IsarService(isar: isar).exportUserData();
      if (backupPath == null) {
        if (testingOldIsar == null) await isar.close();
        return false;
      }
      final historyResult = await isar.searchHistoryItems.where().findAll();
      if (testingOldIsar == null) await isar.close();

      // Open new database and set data
      isar = testingNewIsar ??
          await Isar.open(
            schemas,
            directory: supportDir.path,
            name: 'base_dictionary',
          );

      bool transferResult =
          await IsarService(isar: isar).importUserData(backupPath);

      File(backupPath).delete();
      await isar.writeTxn(() async {
        for (var history in historyResult) {
          await isar!.searchHistoryItems.put(history);
        }
      });
      if (testingNewIsar == null) await isar.close();

      return transferResult;
    } catch (_) {
      if (testingOldIsar == null &&
          testingNewIsar == null &&
          isar != null &&
          isar.isOpen) {
        await isar.close();
      }

      return false;
    }
  }

  static String sanitizeName(String value) {
    // Remove new line characters
    String name = value.replaceAll('\n', '');
    // Enforce character length and trim whitespace
    return name.substring(0, min(50, name.length)).trim();
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

enum ImportResult {
  success,
  failed,
  transferDataFailed,
}
