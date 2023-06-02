import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/datamodels/search_history_item.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/utils/date_time_utils.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('IsarServiceTest', () {
    test('transferUserDataIsolate', () async {
      await setUpFakePathProvider();
      // Create old db to upgrade from
      Isar oldIsar = await setUpIsar();

      await oldIsar.writeTxn(() async {
        final vocab1 = Vocab()..id = 1;
        final vocab2 = Vocab()..id = 2;
        final vocab3 = Vocab()
          ..id = 3
          ..spacedRepetitionData = SpacedRepetitionData();
        vocab3.spacedRepetitionData!.dueDate = 0;
        final kanji1 = Kanji()
          ..id = 1
          ..kanji = '1'
          ..strokeCount = 0;
        final kanji2 = Kanji()
          ..id = 2
          ..kanji = '2'
          ..strokeCount = 0;
        final kanji3 = Kanji()
          ..id = 3
          ..kanji = '3'
          ..strokeCount = 0
          ..spacedRepetitionData = SpacedRepetitionData();
        kanji3.spacedRepetitionData!.dueDate = 0;

        await oldIsar.vocabs.put(vocab1);
        await oldIsar.vocabs.put(vocab2);
        await oldIsar.vocabs.put(vocab3);

        await oldIsar.kanjis.put(kanji1);
        await oldIsar.kanjis.put(kanji2);
        await oldIsar.kanjis.put(kanji3);

        final myList = MyDictionaryList()
          ..id = 0
          ..name = 'list'
          ..timestamp = DateTime.now();
        await oldIsar.myDictionaryLists.put(myList);
        myList.vocabLinks.add(vocab3);
        await myList.vocabLinks.save();
        myList.kanjiLinks.add(kanji1);
        await myList.kanjiLinks.save();

        final flashcardSet = FlashcardSet()
          ..id = 0
          ..name = 'set'
          ..timestamp = DateTime.now()
          ..kanjiShowReading = true;
        await oldIsar.flashcardSets.put(flashcardSet);
        flashcardSet.myDictionaryListLinks.add(myList);
        await flashcardSet.myDictionaryListLinks.save();

        await oldIsar.searchHistoryItems.put(
          SearchHistoryItem()
            ..searchQuery = 'sagase'
            ..timestamp = DateTime.parse('20230414'),
        );
      });

      // Create new db to upgrade to
      Isar newIsar = await setUpIsar();

      await newIsar.writeTxn(() async {
        final vocab1 = Vocab()..id = 1;
        final vocab2 = Vocab()..id = 2;
        final vocab3 = Vocab()..id = 3;
        final kanji1 = Kanji()
          ..id = 1
          ..kanji = '1'
          ..strokeCount = 0;
        final kanji2 = Kanji()
          ..id = 2
          ..kanji = '2'
          ..strokeCount = 0;
        final kanji3 = Kanji()
          ..id = 3
          ..kanji = '3'
          ..strokeCount = 0;

        await newIsar.vocabs.put(vocab1);
        await newIsar.vocabs.put(vocab2);
        await newIsar.vocabs.put(vocab3);

        await newIsar.kanjis.put(kanji1);
        await newIsar.kanjis.put(kanji2);
        await newIsar.kanjis.put(kanji3);
      });

      // Call actual function
      await IsarService.transferUserData(
        testingOldIsar: oldIsar,
        testingNewIsar: newIsar,
      );

      // Verify result
      final vocab = await newIsar.vocabs.get(3);
      expect(vocab!.spacedRepetitionData != null, true);
      expect(vocab.spacedRepetitionData!.dueDate, 0);
      final kanji = await newIsar.kanjis.get(3);
      expect(kanji!.spacedRepetitionData != null, true);
      expect(kanji.spacedRepetitionData!.dueDate, 0);

      final myList = await newIsar.myDictionaryLists.get(0);
      expect(myList!.name, 'list');
      expect(myList.vocabLinks.length, 1);
      expect(myList.kanjiLinks.length, 1);

      final flashcardSet = await newIsar.flashcardSets.get(0);
      expect(flashcardSet!.name, 'set');
      expect(flashcardSet.kanjiShowReading, true);
      expect(flashcardSet.myDictionaryListLinks.length, 1);

      final searchHistory = await newIsar.searchHistoryItems.where().findAll();
      expect(searchHistory.length, 1);
      expect(searchHistory[0].searchQuery, 'sagase');
      expect(searchHistory[0].timestamp.year, 2023);

      // Cleanup
      await oldIsar.close(deleteFromDisk: true);
      await newIsar.close(deleteFromDisk: true);
    });

    test('exportUserData/importUserData empty', () async {
      // Setup
      await setUpFakePathProvider();
      Isar isar = await setUpIsar();

      final service = IsarService(isar);
      String path = await service.exportUserData();
      final file = File(path);

      // Check file content
      String backupContent = await file.readAsString();
      Map<String, dynamic> map = jsonDecode(backupContent);

      expect(
        map[SagaseDictionaryConstants.backupDictionaryVersion],
        SagaseDictionaryConstants.dictionaryVersion,
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(
                map[SagaseDictionaryConstants.backupTimestamp])
            .isDifferentDay(DateTime.now()),
        false,
      );
      expect(map[SagaseDictionaryConstants.backupMyDictionaryLists], []);
      expect(map[SagaseDictionaryConstants.backupFlashcardSets], []);
      expect(
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData], []);
      expect(
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData], []);

      // Do import and check database content
      await service.importUserData(path);

      expect(service.myDictionaryLists!.length, 0);
      expect((await service.getFlashcardSets()).length, 0);

      // Cleanup
      await isar.close(deleteFromDisk: true);
      await file.delete();
    });

    test('exportUserData/importUserData', () async {
      // Set up
      await setUpFakePathProvider();
      Isar isar = await setUpIsar();

      final vocab1 = Vocab()..id = 1;
      final vocab2 = Vocab()
        ..id = 2
        ..spacedRepetitionData = SpacedRepetitionData();
      vocab2.spacedRepetitionData!.interval = 0;
      vocab2.spacedRepetitionData!.repetitions = 0;
      vocab2.spacedRepetitionData!.easeFactor = 2.4;
      vocab2.spacedRepetitionData!.dueDate = 0;
      vocab2.spacedRepetitionData!.totalAnswers = 2;
      vocab2.spacedRepetitionData!.totalWrongAnswers = 2;
      final vocab3 = Vocab()
        ..id = 3
        ..spacedRepetitionData = SpacedRepetitionData();
      vocab3.spacedRepetitionData!.interval = 1;
      vocab3.spacedRepetitionData!.repetitions = 1;
      vocab3.spacedRepetitionData!.easeFactor = 2.6;
      vocab3.spacedRepetitionData!.dueDate = 0;
      vocab3.spacedRepetitionData!.totalAnswers = 1;
      vocab3.spacedRepetitionData!.totalWrongAnswers = 0;
      final kanji1 = Kanji()
        ..id = 1
        ..kanji = 'a'
        ..strokeCount = 0;
      final kanji2 = Kanji()
        ..id = 2
        ..kanji = 'b'
        ..strokeCount = 0;
      final kanji3 = Kanji()
        ..id = 3
        ..kanji = 'c'
        ..strokeCount = 0
        ..spacedRepetitionData = SpacedRepetitionData();
      kanji3.spacedRepetitionData!.interval = 5;
      kanji3.spacedRepetitionData!.repetitions = 2;
      kanji3.spacedRepetitionData!.easeFactor = 2.7776;
      kanji3.spacedRepetitionData!.dueDate = 2;
      kanji3.spacedRepetitionData!.totalAnswers = 2;
      kanji3.spacedRepetitionData!.totalWrongAnswers = 1;

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        await isar.kanjis.put(kanji1);
        await isar.kanjis.put(kanji2);
        await isar.kanjis.put(kanji3);
      });

      final service = IsarService(isar);

      // Create my dictionary list
      await service.getMyDictionaryLists();
      await service.createMyDictionaryList('list1');
      await service.addVocabToMyDictionaryList(
          service.myDictionaryLists![0], vocab2);
      await service.addVocabToMyDictionaryList(
          service.myDictionaryLists![0], vocab3);
      await service.addKanjiToMyDictionaryList(
          service.myDictionaryLists![0], kanji2);
      await service.addKanjiToMyDictionaryList(
          service.myDictionaryLists![0], kanji3);

      // Create flashcard set
      final flashcardSet = await service.createFlashcardSet('set1');
      flashcardSet.vocabShowReading = true;
      await service.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [service.myDictionaryLists![0]],
      );

      // Export data
      String path = await service.exportUserData();
      final file = File(path);

      // Check file content
      String backupContent = await file.readAsString();
      Map<dynamic, dynamic> map = jsonDecode(backupContent);

      expect(
        map[SagaseDictionaryConstants.backupDictionaryVersion],
        SagaseDictionaryConstants.dictionaryVersion,
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(
                map[SagaseDictionaryConstants.backupTimestamp])
            .isDifferentDay(DateTime.now()),
        false,
      );
      expect(map[SagaseDictionaryConstants.backupMyDictionaryLists].length, 1);
      final myList = MyDictionaryList.fromBackupJson(
          map[SagaseDictionaryConstants.backupMyDictionaryLists][0]);
      expect(myList.name, 'list1');
      expect(myList.timestamp.isDifferentDay(DateTime.now()), false);
      expect(
        map[SagaseDictionaryConstants.backupMyDictionaryLists][0]
                [SagaseDictionaryConstants.backupMyDictionaryListVocab]
            .length,
        2,
      );
      expect(
        map[SagaseDictionaryConstants.backupMyDictionaryLists][0]
                [SagaseDictionaryConstants.backupMyDictionaryListKanji]
            .length,
        2,
      );
      final set = FlashcardSet.fromBackupJson(
          map[SagaseDictionaryConstants.backupFlashcardSets][0]);
      expect(map[SagaseDictionaryConstants.backupFlashcardSets].length, 1);
      expect(
        map[SagaseDictionaryConstants.backupFlashcardSets][0]
                [SagaseDictionaryConstants.backupFlashcardSetMyDictionaryLists]
            .length,
        1,
      );
      expect(set.name, 'set1');
      expect(set.usingSpacedRepetition, true);
      expect(set.vocabShowReading, true);
      expect(
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData].length,
          2);
      final spaced1 = SpacedRepetitionData.fromBackupJson(
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData][0]);
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData][0]
            [SagaseDictionaryConstants.backupSpacedRepetitionDataVocabId],
        2,
      );
      expect(spaced1.interval, 0);
      expect(spaced1.repetitions, 0);
      expect(spaced1.easeFactor, 2.4);
      expect(spaced1.dueDate, 0);
      expect(spaced1.totalAnswers, 2);
      expect(spaced1.totalWrongAnswers, 2);
      final spaced2 = SpacedRepetitionData.fromBackupJson(
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData][1]);
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData][1]
            [SagaseDictionaryConstants.backupSpacedRepetitionDataVocabId],
        3,
      );
      expect(spaced2.interval, 1);
      expect(
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData].length,
          1);
      final spaced3 = SpacedRepetitionData.fromBackupJson(
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData][0]);
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData][0]
            [SagaseDictionaryConstants.backupSpacedRepetitionDataKanji],
        'c',
      );
      expect(spaced3.interval, 5);
      expect(spaced3.repetitions, 2);
      expect(spaced3.easeFactor, 2.7776);
      expect(spaced3.dueDate, 2);
      expect(spaced3.totalAnswers, 2);
      expect(spaced3.totalWrongAnswers, 1);

      // Do import and check database content
      await service.importUserData(path);

      expect(service.myDictionaryLists!.length, 1);
      expect(service.myDictionaryLists![0].name, 'list1');
      expect(service.myDictionaryLists![0].vocabLinks.length, 2);
      expect(service.myDictionaryLists![0].kanjiLinks.length, 2);

      final flashcardSets = await service.getFlashcardSets();
      expect(flashcardSets.length, 1);
      expect(flashcardSets[0].name, 'set1');
      expect(flashcardSets[0].usingSpacedRepetition, true);
      expect(flashcardSets[0].vocabShowReading, true);
      expect(flashcardSets[0].predefinedDictionaryListLinks.length, 0);
      expect(flashcardSets[0].myDictionaryListLinks.length, 1);

      final newVocab1 = await isar.vocabs.get(1);
      expect(newVocab1!.spacedRepetitionData, null);
      final newVocab2 = await isar.vocabs.get(2);
      expect(newVocab2!.spacedRepetitionData!.interval, 0);
      final newVocab3 = await isar.vocabs.get(3);
      expect(newVocab3!.spacedRepetitionData!.interval, 1);

      // Cleanup
      await isar.close(deleteFromDisk: true);
      await file.delete();
    });
  });
}
