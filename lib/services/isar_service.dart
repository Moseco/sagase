import 'dart:io';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/predefined_dictionary_list.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/utils/constants.dart' as constants;

class IsarService {
  final Isar _isar;

  final _kanaKit = const KanaKit();

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
      ],
    );

    return IsarService(isar);
  }

  Future<void> close() async {
    await _isar.close();
  }

  Future<DictionaryStatus> validateDictionary() async {
    // Check if dictionary count matches expectation
    if ((await _isar.kanjis.count()) != 13108 ||
        (await _isar.vocabs.count()) != 198094) {
      return DictionaryStatus.invalid;
    }

    // Check version matches current
    if ((await _isar.dictionaryInfos.get(0))?.version !=
        constants.dictionaryVersion) {
      return DictionaryStatus.outOfDate;
    }

    return DictionaryStatus.valid;
  }

  Future<List<DictionaryItem>> searchDictionary(String value) async {
    // First check if searching single kanji
    Kanji? kanji;
    if (value.length == 1 && value.contains(constants.kanjiRegExp)) {
      kanji = await _isar.kanjis.getByKanji(value);
    }

    // Search vocab
    final vocabList = await searchVocab(value);

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
        Map<Vocab, bool> vocabRankMap = {};

        for (int i = 0; i < nestedRomajiSortingList.length; i++) {
          for (var vocab in nestedRomajiSortingList[i]) {
            if (!vocabRankMap.containsKey(vocab)) {
              sortedList.add(vocab);
              vocabRankMap[vocab] = true;
            }
          }
          for (var vocab in nestedDefinitionSortingList[i]) {
            if (!vocabRankMap.containsKey(vocab)) {
              sortedList.add(vocab);
              vocabRankMap[vocab] = true;
            }
          }
        }

        for (var vocab in nestedDefinitionSortingList[5]) {
          if (!vocabRankMap.containsKey(vocab)) {
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

    for (int i = 0; i < unsortedList.length; i++) {
      bool noMatch = true;
      for (int j = 0; j < unsortedList[i].definitions.length; j++) {
        if (unsortedList[i].definitions[j].definition.contains(searchString)) {
          noMatch = false;
          if (j == 0) {
            if (unsortedList[i]
                .definitions[j]
                .definition
                .startsWith(searchString)) {
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

  Future<void> updateSpacedRepetitionData(DictionaryItem item) async {
    return _isar.writeTxn(() async {
      if (item is Vocab) {
        await _isar.vocabs.put(item);
      } else {
        await _isar.kanjis.put(item as Kanji);
      }
    });
  }

  static Future<void> importDatabase() async {
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
}

enum DictionaryStatus {
  valid,
  invalid,
  outOfDate,
}
