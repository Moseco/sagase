import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/isar/flashcard_set.dart';
import 'package:sagase/datamodels/isar/kanji.dart';
import 'package:sagase/datamodels/isar/my_dictionary_list.dart';
import 'package:sagase/datamodels/isar/spaced_repetition_data.dart';
import 'package:sagase/datamodels/isar/vocab.dart';
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart'
    show JapaneseTextHelpers, SagaseDictionaryConstants;
import 'package:sagase/utils/date_time_utils.dart';

import '../helpers/fakes.dart';
import '../helpers/isar_helper.dart';

void main() {
  group('IsarServiceTest', () {
    late Isar isar;

    setUp(() async {
      setUpFakePathProvider();
      isar = await setUpIsar();
    });

    tearDown(() async {
      await isar.close();
      cleanUpFakePathProvider();
    });

    test('exportUserData - empty', () async {
      final service = IsarService(isar: isar);
      String path = (await service.exportUserData())!;
      final file = File(path);

      // Check file content
      String backupContent = await file.readAsString();
      Map<String, dynamic> map = jsonDecode(backupContent);

      expect(
        map[SagaseDictionaryConstants.exportType],
        SagaseDictionaryConstants.exportTypeBackup,
      );
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
      expect(
        map[SagaseDictionaryConstants.backupMyDictionaryLists],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupFlashcardSets],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish],
        isEmpty,
      );
    });

    test('exportUserData - with data', () async {
      // Create data
      final vocab1 = Vocab()..id = 1;
      final vocab2 = Vocab()
        ..id = 2
        ..spacedRepetitionData = (SpacedRepetitionData()
          ..interval = 0
          ..repetitions = 0
          ..easeFactor = 2.4
          ..dueDate = 0
          ..totalAnswers = 2
          ..totalWrongAnswers = 2);
      final vocab3 = Vocab()
        ..id = 3
        ..spacedRepetitionData = (SpacedRepetitionData()
          ..interval = 1
          ..repetitions = 1
          ..easeFactor = 2.6
          ..dueDate = 0
          ..totalAnswers = 1
          ..totalWrongAnswers = 0)
        ..spacedRepetitionDataEnglish = (SpacedRepetitionData()
          ..interval = 2
          ..repetitions = 2
          ..easeFactor = 2.7
          ..dueDate = 1
          ..totalAnswers = 2
          ..totalWrongAnswers = 1);
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
        ..spacedRepetitionData = (SpacedRepetitionData()
          ..interval = 5
          ..repetitions = 2
          ..easeFactor = 2.7776
          ..dueDate = 2
          ..totalAnswers = 2
          ..totalWrongAnswers = 1)
        ..spacedRepetitionDataEnglish = (SpacedRepetitionData()
          ..interval = 6
          ..repetitions = 3
          ..easeFactor = 2.8776
          ..dueDate = 3
          ..totalAnswers = 3
          ..totalWrongAnswers = 2);

      await isar.writeTxn(() async {
        // Add vocab
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        // Add kanji
        await isar.kanjis.put(kanji1);
        await isar.kanjis.put(kanji2);
        await isar.kanjis.put(kanji3);
        // Add my dictionary lists
        int myDictionaryListId = await isar.myDictionaryLists.put(
          MyDictionaryList()
            ..name = 'list1'
            ..timestamp = DateTime.now()
            ..vocab = [vocab2.id, vocab3.id]
            ..kanji = [kanji2.id, kanji3.id],
        );
        await isar.myDictionaryLists.put(
          MyDictionaryList()
            ..name = 'empty list'
            ..timestamp = DateTime.now(),
        );
        // Add flashcard set
        await isar.flashcardSets.put(
          FlashcardSet()
            ..name = 'set1'
            ..timestamp = DateTime.now()
            ..vocabShowReading = true
            ..myDictionaryLists = [myDictionaryListId],
        );
      });

      final service = IsarService(isar: isar);

      // Export data
      String path = (await service.exportUserData())!;
      final file = File(path);

      // Export and import from class
      final userBackup = UserBackup.fromBackupJson(await file.readAsString());

      expect(userBackup, isNotNull);

      expect(
        userBackup!.dictionaryVersion,
        SagaseDictionaryConstants.dictionaryVersion,
      );
      expect(userBackup.timestamp.isDifferentDay(DateTime.now()), false);

      expect(userBackup.myDictionaryLists.length, 2);
      final myList =
          MyDictionaryList.fromBackupJson(userBackup.myDictionaryLists[0]);
      expect(myList.name, 'list1');
      expect(myList.timestamp.isDifferentDay(DateTime.now()), false);
      expect(myList.vocab.length, 2);
      expect(myList.kanji.length, 2);
      final emptyMyList =
          MyDictionaryList.fromBackupJson(userBackup.myDictionaryLists[1]);
      expect(emptyMyList.name, 'empty list');
      expect(emptyMyList.timestamp.isDifferentDay(DateTime.now()), false);

      expect(userBackup.flashcardSets.length, 1);
      final set = FlashcardSet.fromBackupJson(userBackup.flashcardSets[0]);
      expect(set.myDictionaryLists.length, 1);
      expect(set.name, 'set1');
      expect(set.usingSpacedRepetition, true);
      expect(set.frontType, FrontType.japanese);
      expect(set.vocabShowReading, true);

      expect(userBackup.vocabSpacedRepetitionData.length, 2);
      expect(userBackup.vocabSpacedRepetitionData['2'], isNotNull);
      final spaced1 = SpacedRepetitionData.fromBackupJson(
          jsonDecode(userBackup.vocabSpacedRepetitionData['2']));
      expect(spaced1.interval, 0);
      expect(spaced1.repetitions, 0);
      expect(spaced1.easeFactor, 2.4);
      expect(spaced1.dueDate, 0);
      expect(spaced1.totalAnswers, 2);
      expect(spaced1.totalWrongAnswers, 2);

      expect(userBackup.vocabSpacedRepetitionData['3'], isNotNull);
      final spaced2 = SpacedRepetitionData.fromBackupJson(
          jsonDecode(userBackup.vocabSpacedRepetitionData['3']));
      expect(spaced2.interval, 1);

      expect(userBackup.vocabSpacedRepetitionDataEnglish.length, 1);
      expect(userBackup.vocabSpacedRepetitionDataEnglish['3'], isNotNull);
      final spaced3 = SpacedRepetitionData.fromBackupJson(
          jsonDecode(userBackup.vocabSpacedRepetitionDataEnglish['3']));
      expect(spaced3.interval, 2);

      expect(userBackup.kanjiSpacedRepetitionData.length, 1);
      expect(
        userBackup.kanjiSpacedRepetitionData['c'.kanjiCodePoint().toString()],
        isNotNull,
      );
      final spaced4 = SpacedRepetitionData.fromBackupJson(jsonDecode(userBackup
          .kanjiSpacedRepetitionData['c'.kanjiCodePoint().toString()]));
      expect(spaced4.interval, 5);
      expect(spaced4.repetitions, 2);
      expect(spaced4.easeFactor, 2.7776);
      expect(spaced4.dueDate, 2);
      expect(spaced4.totalAnswers, 2);
      expect(spaced4.totalWrongAnswers, 1);

      expect(userBackup.kanjiSpacedRepetitionDataEnglish.length, 1);
      expect(
        userBackup
            .kanjiSpacedRepetitionDataEnglish['c'.kanjiCodePoint().toString()],
        isNotNull,
      );
      final spaced5 = SpacedRepetitionData.fromBackupJson(jsonDecode(userBackup
          .kanjiSpacedRepetitionDataEnglish['c'.kanjiCodePoint().toString()]));

      expect(spaced5.interval, 6);
    });
  });
}
