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
          ..id = 'a'.kanjiCodePoint()
          ..kanji = 'a'
          ..radical = 'a'
          ..strokeCount = 0;
        final kanji2 = Kanji()
          ..id = 'b'.kanjiCodePoint()
          ..kanji = 'b'
          ..radical = 'b'
          ..strokeCount = 0;
        final kanji3 = Kanji()
          ..id = 'c'.kanjiCodePoint()
          ..kanji = 'c'
          ..radical = 'c'
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
          ..timestamp = DateTime.now()
          ..vocab = [vocab3.id]
          ..kanji = [kanji1.id];
        await oldIsar.myDictionaryLists.put(myList);

        final flashcardSet = FlashcardSet()
          ..id = 0
          ..name = 'set'
          ..timestamp = DateTime.now()
          ..kanjiShowReading = true
          ..myDictionaryLists = [myList.id];
        await oldIsar.flashcardSets.put(flashcardSet);

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
          ..id = 'a'.kanjiCodePoint()
          ..kanji = 'a'
          ..radical = 'a'
          ..strokeCount = 0;
        final kanji2 = Kanji()
          ..id = 'b'.kanjiCodePoint()
          ..kanji = 'b'
          ..radical = 'b'
          ..strokeCount = 0;
        final kanji3 = Kanji()
          ..id = 'c'.kanjiCodePoint()
          ..kanji = 'c'
          ..radical = 'c'
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
      final kanji = await newIsar.kanjis.get('c'.kanjiCodePoint());
      expect(kanji!.spacedRepetitionData != null, true);
      expect(kanji.spacedRepetitionData!.dueDate, 0);

      final myList = await newIsar.myDictionaryLists.get(0);
      expect(myList!.name, 'list');
      expect(myList.vocab.length, 1);
      expect(myList.kanji.length, 1);

      final flashcardSet = await newIsar.flashcardSets.get(0);
      expect(flashcardSet!.name, 'set');
      expect(flashcardSet.kanjiShowReading, true);
      expect(flashcardSet.myDictionaryLists.length, 1);

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

      final service = IsarService(isar: isar);
      String path = (await service.exportUserData())!;
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

      expect((await service.getAllMyDictionaryLists()).length, 0);
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
        ..spacedRepetitionData = SpacedRepetitionData()
        ..spacedRepetitionDataEnglish = SpacedRepetitionData();
      vocab3.spacedRepetitionData!.interval = 1;
      vocab3.spacedRepetitionData!.repetitions = 1;
      vocab3.spacedRepetitionData!.easeFactor = 2.6;
      vocab3.spacedRepetitionData!.dueDate = 0;
      vocab3.spacedRepetitionData!.totalAnswers = 1;
      vocab3.spacedRepetitionData!.totalWrongAnswers = 0;
      vocab3.spacedRepetitionDataEnglish!.interval = 2;
      vocab3.spacedRepetitionDataEnglish!.repetitions = 2;
      vocab3.spacedRepetitionDataEnglish!.easeFactor = 2.7;
      vocab3.spacedRepetitionDataEnglish!.dueDate = 1;
      vocab3.spacedRepetitionDataEnglish!.totalAnswers = 2;
      vocab3.spacedRepetitionDataEnglish!.totalWrongAnswers = 1;
      final kanji1 = Kanji()
        ..id = 'a'.kanjiCodePoint()
        ..kanji = 'a'
        ..radical = 'a'
        ..strokeCount = 0;
      final kanji2 = Kanji()
        ..id = 'b'.kanjiCodePoint()
        ..kanji = 'b'
        ..radical = 'b'
        ..strokeCount = 0;
      final kanji3 = Kanji()
        ..id = 'c'.kanjiCodePoint()
        ..kanji = 'c'
        ..radical = 'c'
        ..strokeCount = 0
        ..spacedRepetitionData = SpacedRepetitionData()
        ..spacedRepetitionDataEnglish = SpacedRepetitionData();
      kanji3.spacedRepetitionData!.interval = 5;
      kanji3.spacedRepetitionData!.repetitions = 2;
      kanji3.spacedRepetitionData!.easeFactor = 2.7776;
      kanji3.spacedRepetitionData!.dueDate = 2;
      kanji3.spacedRepetitionData!.totalAnswers = 2;
      kanji3.spacedRepetitionData!.totalWrongAnswers = 1;
      kanji3.spacedRepetitionDataEnglish!.interval = 6;
      kanji3.spacedRepetitionDataEnglish!.repetitions = 3;
      kanji3.spacedRepetitionDataEnglish!.easeFactor = 2.8776;
      kanji3.spacedRepetitionDataEnglish!.dueDate = 3;
      kanji3.spacedRepetitionDataEnglish!.totalAnswers = 3;
      kanji3.spacedRepetitionDataEnglish!.totalWrongAnswers = 2;

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        await isar.kanjis.put(kanji1);
        await isar.kanjis.put(kanji2);
        await isar.kanjis.put(kanji3);
      });

      final service = IsarService(isar: isar);

      // Create my dictionary list
      final list1 = await service.createMyDictionaryList('list1');
      await service.addVocabToMyDictionaryList(list1, vocab2);
      await service.addVocabToMyDictionaryList(list1, vocab3);
      await service.addKanjiToMyDictionaryList(list1, kanji2);
      await service.addKanjiToMyDictionaryList(list1, kanji3);

      // Create flashcard set
      final flashcardSet = await service.createFlashcardSet('set1');
      flashcardSet.vocabShowReading = true;
      flashcardSet.myDictionaryLists.add(list1.id);
      await service.updateFlashcardSet(flashcardSet);

      // Export data
      String path = (await service.exportUserData())!;
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
        map[SagaseDictionaryConstants.backupMyDictionaryLists][0],
        SagaseDictionaryConstants.dictionaryVersion,
      );
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
      expect(set.frontType, FrontType.japanese);
      expect(set.vocabShowReading, true);
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData].length,
        2,
      );
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
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish]
            .length,
        1,
      );
      final spaced3 = SpacedRepetitionData.fromBackupJson(
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish]
              [0]);
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish][0]
            [SagaseDictionaryConstants.backupSpacedRepetitionDataVocabId],
        3,
      );
      expect(spaced3.interval, 2);
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData].length,
        1,
      );
      final spaced4 = SpacedRepetitionData.fromBackupJson(
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData][0]);
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData][0]
            [SagaseDictionaryConstants.backupSpacedRepetitionDataKanjiId],
        'c'.kanjiCodePoint(),
      );
      expect(spaced4.interval, 5);
      expect(spaced4.repetitions, 2);
      expect(spaced4.easeFactor, 2.7776);
      expect(spaced4.dueDate, 2);
      expect(spaced4.totalAnswers, 2);
      expect(spaced4.totalWrongAnswers, 1);
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish]
            .length,
        1,
      );
      final spaced5 = SpacedRepetitionData.fromBackupJson(
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish]
              [0]);
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish][0]
            [SagaseDictionaryConstants.backupSpacedRepetitionDataKanjiId],
        'c'.kanjiCodePoint(),
      );
      expect(spaced5.interval, 6);

      // Do import and check database content
      await service.importUserData(path);

      final myLists = await service.getAllMyDictionaryLists();
      expect(myLists.length, 1);
      expect(myLists[0].name, 'list1');
      expect(myLists[0].vocab.length, 2);
      expect(myLists[0].kanji.length, 2);

      final flashcardSets = await service.getFlashcardSets();
      expect(flashcardSets.length, 1);
      expect(flashcardSets[0].name, 'set1');
      expect(flashcardSets[0].usingSpacedRepetition, true);
      expect(flashcardSets[0].vocabShowReading, true);
      expect(flashcardSets[0].predefinedDictionaryLists.length, 0);
      expect(flashcardSets[0].myDictionaryLists.length, 1);

      final newVocab1 = await isar.vocabs.get(1);
      expect(newVocab1!.spacedRepetitionData, null);
      expect(newVocab1.spacedRepetitionDataEnglish, null);
      final newVocab2 = await isar.vocabs.get(2);
      expect(newVocab2!.spacedRepetitionData!.interval, 0);
      expect(newVocab2.spacedRepetitionDataEnglish, null);
      final newVocab3 = await isar.vocabs.get(3);
      expect(newVocab3!.spacedRepetitionData!.interval, 1);
      expect(newVocab3.spacedRepetitionDataEnglish!.interval, 2);

      final newKanji1 = await isar.kanjis.get('a'.kanjiCodePoint());
      expect(newKanji1!.spacedRepetitionData, null);
      expect(newKanji1.spacedRepetitionDataEnglish, null);
      final newKanji2 = await isar.kanjis.get('b'.kanjiCodePoint());
      expect(newKanji2!.spacedRepetitionData, null);
      expect(newKanji2.spacedRepetitionDataEnglish, null);
      final newKanji3 = await isar.kanjis.get('c'.kanjiCodePoint());
      expect(newKanji3!.spacedRepetitionData!.interval, 5);
      expect(newKanji3.spacedRepetitionDataEnglish!.interval, 6);

      // Cleanup
      await isar.close(deleteFromDisk: true);
      await file.delete();
    });

    test('sortByDefinition', () async {
      // Set up
      await setUpFakePathProvider();
      Isar isar = await setUpIsar();
      final service = IsarService(isar: isar);

      final result = service.sortByDefinition([
        Vocab()
          ..id = 0
          ..definitions = [VocabDefinition()..definition = 'query'],
        Vocab()
          ..id = 1
          ..definitions = [VocabDefinition()..definition = 'query text'],
        Vocab()
          ..id = 2
          ..definitions = [
            VocabDefinition()..definition = 'other thing; query; more stuff'
          ],
        Vocab()
          ..id = 3
          ..definitions = [
            VocabDefinition()..definition = 'other thing; (qualifier) query'
          ],
        Vocab()
          ..id = 4
          ..definitions = [
            VocabDefinition()..definition = 'other thing; (querys) query'
          ],
        Vocab()
          ..id = 5
          ..definitions = [VocabDefinition()..definition = 'querys'],
        Vocab()
          ..id = 6
          ..definitions = [VocabDefinition()..definition = 'this query after'],
        Vocab()
          ..id = 7
          ..definitions = [
            VocabDefinition()..definition = 'other things',
            VocabDefinition()..definition = 'this says query and other things',
          ],
        Vocab()
          ..id = 8
          ..definitions = [
            VocabDefinition()..definition = 'BEFOREquery',
            VocabDefinition()..definition = 'BEFOREqueryAFTER',
          ],
        Vocab()
          ..id = 9
          ..definitions = [VocabDefinition()..definition = '(query) bla'],
        Vocab()
          ..id = 10
          ..definitions = [VocabDefinition()..definition = '(querys) bla'],
        Vocab()
          ..id = 11
          ..definitions = [VocabDefinition()..definition = '(query) query'],
        Vocab()
          ..id = 12
          ..definitions = [VocabDefinition()..definition = 'other; query text'],
        Vocab()
          ..id = 13
          ..definitions = [VocabDefinition()..definition = 'Bad find'],
        Vocab()
          ..id = 14
          ..definitions = [
            VocabDefinition()..definition = 'query (with trailing)'
          ],
        Vocab()
          ..id = 14
          ..definitions = [
            VocabDefinition()
              ..definition =
                  'other stuff; (leading) query (with trailing); more stuff'
          ],
      ], 'query');

      expect(result[0][0].id, 0);
      expect(result[0][1].id, 2);
      expect(result[0][2].id, 3);
      expect(result[0][3].id, 4);
      expect(result[0][4].id, 11);
      expect(result[0][5].id, 14);
      expect(result[1][0].id, 1);
      expect(result[1][1].id, 5);
      expect(result[1][2].id, 12);
      expect(result[2][0].id, 6);
      expect(result[2][1].id, 9);
      expect(result[2][2].id, 10);
      expect(result[3][0].id, 7);
      expect(result[4][0].id, 8);
      expect(result[4][1].id, 13);

      await isar.close(deleteFromDisk: true);
    });

    test('deleteMyDictionaryList', () async {
      Isar isar = await setUpIsar();
      final isarService = IsarService(isar: isar);

      // Create my lists
      final list1 = await isarService.createMyDictionaryList('list1');
      final list2 = await isarService.createMyDictionaryList('list2');
      await isarService.createMyDictionaryList('list3');

      // Create flashcard set and add my lists
      final flashcardSet = await isarService.createFlashcardSet('set1');
      flashcardSet.myDictionaryLists.add(list1.id);
      flashcardSet.myDictionaryLists.add(list2.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Verify set up
      var myLists = await isarService.getAllMyDictionaryLists();
      expect(myLists.length, 3);
      final preFlashcardSet = (await isarService.getFlashcardSets())[0];
      expect(preFlashcardSet.myDictionaryLists.length, 2);

      // Delete my list
      await isarService.deleteMyDictionaryList(list2);

      // Verify
      final newMyLists = await isarService.getAllMyDictionaryLists();
      expect(newMyLists.length, 2);
      final updateFlashcardSet = (await isarService.getFlashcardSets())[0];
      expect(updateFlashcardSet.myDictionaryLists.length, 1);
      expect(updateFlashcardSet.myDictionaryLists[0], list1.id);

      await isar.close(deleteFromDisk: true);
    });
  });
}
