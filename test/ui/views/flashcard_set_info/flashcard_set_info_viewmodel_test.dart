import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/ui/views/flashcard_set_info/flashcard_set_info_viewmodel.dart';
import 'package:sagase/utils/date_time_utils.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FlashcardsViewModelTest', () {
    late Isar isar;
    late IsarService isarService;

    setUp(() async {
      registerServices();
      isar = await setUpIsar();
      isarService = await getAndRegisterRealIsarService(isar);
    });

    tearDown(() {
      unregisterServices();
      isar.close(deleteFromDisk: true);
    });

    test('Upcoming due flashcards', () async {
      await isar.writeTxn(() async {
        // Create 1 flashcard due each day for the upcoming week
        for (int i = 0; i < 8; i++) {
          var spacedRepetitionData = SpacedRepetitionData()
            ..dueDate = DateTime.now().toInt() + i;

          var vocab = Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ]
            ..spacedRepetitionData = spacedRepetitionData;

          await isar.vocabs.put(vocab);
        }

        // Create flashcards that shouldn't be added
        await isar.vocabs.put(Vocab()
          ..id = 8
          ..spacedRepetitionData = SpacedRepetitionData());
        await isar.vocabs.put(Vocab()..id = 9);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 10; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.upcomingDueFlashcards!.length, 8);
      expect(viewModel.upcomingDueFlashcards![0], 1);
      expect(viewModel.upcomingDueFlashcards![1], 1);
      expect(viewModel.upcomingDueFlashcards![2], 1);
      expect(viewModel.upcomingDueFlashcards![3], 1);
      expect(viewModel.upcomingDueFlashcards![4], 1);
      expect(viewModel.upcomingDueFlashcards![5], 1);
      expect(viewModel.upcomingDueFlashcards![6], 1);
      expect(viewModel.upcomingDueFlashcards![7], 1);
    });

    test('Upcoming due flashcards - English front', () async {
      await isar.writeTxn(() async {
        // Create 1 flashcard due each day for the upcoming week
        for (int i = 0; i < 8; i++) {
          var spacedRepetitionData = SpacedRepetitionData()
            ..dueDate = DateTime.now().toInt() + i;

          var vocab = Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ]
            ..spacedRepetitionDataEnglish = spacedRepetitionData;

          await isar.vocabs.put(vocab);
        }

        // Create flashcards that shouldn't be added
        await isar.vocabs.put(Vocab()
          ..id = 8
          ..spacedRepetitionData = SpacedRepetitionData());
        await isar.vocabs.put(Vocab()..id = 9);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 10; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.upcomingDueFlashcards!.length, 8);
      expect(viewModel.upcomingDueFlashcards![0], 1);
      expect(viewModel.upcomingDueFlashcards![1], 1);
      expect(viewModel.upcomingDueFlashcards![2], 1);
      expect(viewModel.upcomingDueFlashcards![3], 1);
      expect(viewModel.upcomingDueFlashcards![4], 1);
      expect(viewModel.upcomingDueFlashcards![5], 1);
      expect(viewModel.upcomingDueFlashcards![6], 1);
      expect(viewModel.upcomingDueFlashcards![7], 1);
    });

    test('Upcoming due flashcards - mismatched data and front type', () async {
      // Create 1 flashcard due each day for the upcoming week
      await isar.writeTxn(() async {
        for (int i = 0; i < 8; i++) {
          var spacedRepetitionData = SpacedRepetitionData()
            ..dueDate = DateTime.now().toInt() + i;

          var vocab = Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ]
            ..spacedRepetitionData = spacedRepetitionData;

          await isar.vocabs.put(vocab);
        }
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 8; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.upcomingDueFlashcards!.length, 8);
      expect(viewModel.upcomingDueFlashcards![0], 0);
      expect(viewModel.upcomingDueFlashcards![1], 0);
      expect(viewModel.upcomingDueFlashcards![2], 0);
      expect(viewModel.upcomingDueFlashcards![3], 0);
      expect(viewModel.upcomingDueFlashcards![4], 0);
      expect(viewModel.upcomingDueFlashcards![5], 0);
      expect(viewModel.upcomingDueFlashcards![6], 0);
      expect(viewModel.upcomingDueFlashcards![7], 0);
    });

    test('Flashcard interval counts', () async {
      // Create 1 flashcard for each interval group
      await isar.writeTxn(() async {
        var spacedRepetitionData1 = SpacedRepetitionData()
          ..interval = 1
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData2 = SpacedRepetitionData()
          ..interval = 8
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData3 = SpacedRepetitionData()
          ..interval = 30
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData4 = SpacedRepetitionData()
          ..interval = 60
          ..dueDate = DateTime.now().toInt();

        var vocab1 = Vocab()
          ..id = 0
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
          ]
          ..spacedRepetitionData = spacedRepetitionData1;
        var vocab2 = Vocab()
          ..id = 1
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
          ]
          ..spacedRepetitionData = spacedRepetitionData2;
        var vocab3 = Vocab()
          ..id = 2
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '2'],
          ]
          ..spacedRepetitionData = spacedRepetitionData3;
        var vocab4 = Vocab()
          ..id = 3
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '3'],
          ]
          ..spacedRepetitionData = spacedRepetitionData4;
        var vocab5 = Vocab()
          ..id = 4
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '4'],
          ]
          ..spacedRepetitionData = SpacedRepetitionData();
        var vocab6 = Vocab()
          ..id = 5
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '5'],
          ];

        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        await isar.vocabs.put(vocab4);
        await isar.vocabs.put(vocab5);
        await isar.vocabs.put(vocab6);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 6; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.flashcardIntervalCounts[0], 2);
      expect(viewModel.flashcardIntervalCounts[1], 1);
      expect(viewModel.flashcardIntervalCounts[2], 1);
      expect(viewModel.flashcardIntervalCounts[3], 1);
      expect(viewModel.flashcardIntervalCounts[4], 1);
    });

    test('Flashcard interval counts - English front', () async {
      // Create 1 flashcard for each interval group
      await isar.writeTxn(() async {
        var spacedRepetitionData1 = SpacedRepetitionData()
          ..interval = 1
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData2 = SpacedRepetitionData()
          ..interval = 8
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData3 = SpacedRepetitionData()
          ..interval = 30
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData4 = SpacedRepetitionData()
          ..interval = 60
          ..dueDate = DateTime.now().toInt();

        var vocab1 = Vocab()
          ..id = 0
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
          ]
          ..spacedRepetitionDataEnglish = spacedRepetitionData1;
        var vocab2 = Vocab()
          ..id = 1
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
          ]
          ..spacedRepetitionDataEnglish = spacedRepetitionData2;
        var vocab3 = Vocab()
          ..id = 2
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '2'],
          ]
          ..spacedRepetitionDataEnglish = spacedRepetitionData3;
        var vocab4 = Vocab()
          ..id = 3
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '3'],
          ]
          ..spacedRepetitionDataEnglish = spacedRepetitionData4;
        var vocab5 = Vocab()
          ..id = 4
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '4'],
          ]
          ..spacedRepetitionData = SpacedRepetitionData();
        var vocab6 = Vocab()
          ..id = 5
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '5'],
          ];

        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        await isar.vocabs.put(vocab4);
        await isar.vocabs.put(vocab5);
        await isar.vocabs.put(vocab6);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 6; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.flashcardIntervalCounts[0], 2);
      expect(viewModel.flashcardIntervalCounts[1], 1);
      expect(viewModel.flashcardIntervalCounts[2], 1);
      expect(viewModel.flashcardIntervalCounts[3], 1);
      expect(viewModel.flashcardIntervalCounts[4], 1);
    });

    test('Flashcard interval counts - mismatched data and front type',
        () async {
      // Create 1 flashcard for each interval group
      await isar.writeTxn(() async {
        var spacedRepetitionData1 = SpacedRepetitionData()
          ..interval = 1
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData2 = SpacedRepetitionData()
          ..interval = 8
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData3 = SpacedRepetitionData()
          ..interval = 30
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData4 = SpacedRepetitionData()
          ..interval = 60
          ..dueDate = DateTime.now().toInt();

        var vocab1 = Vocab()
          ..id = 0
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
          ]
          ..spacedRepetitionData = spacedRepetitionData1;
        var vocab2 = Vocab()
          ..id = 1
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
          ]
          ..spacedRepetitionData = spacedRepetitionData2;
        var vocab3 = Vocab()
          ..id = 2
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '2'],
          ]
          ..spacedRepetitionData = spacedRepetitionData3;
        var vocab4 = Vocab()
          ..id = 3
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '3'],
          ]
          ..spacedRepetitionData = spacedRepetitionData4;
        var vocab5 = Vocab()
          ..id = 4
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '4'],
          ];

        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        await isar.vocabs.put(vocab4);
        await isar.vocabs.put(vocab5);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 5; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.flashcardIntervalCounts[0], 5);
      expect(viewModel.flashcardIntervalCounts[1], 0);
      expect(viewModel.flashcardIntervalCounts[2], 0);
      expect(viewModel.flashcardIntervalCounts[3], 0);
      expect(viewModel.flashcardIntervalCounts[4], 0);
    });

    test('Flashcard challenging flashcards', () async {
      await isar.writeTxn(() async {
        for (int i = 0; i < 20; i++) {
          var spacedRepetitionData = SpacedRepetitionData()
            ..totalAnswers = i + 1
            ..totalWrongAnswers = i
            ..dueDate = DateTime.now().toInt() + i;

          var vocab = Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ]
            ..spacedRepetitionData = spacedRepetitionData;

          await isar.vocabs.put(vocab);
        }

        var spacedRepetitionData = SpacedRepetitionData()
          ..totalAnswers = 20
          ..totalWrongAnswers = 3
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData2 = SpacedRepetitionData()
          ..totalAnswers = 10
          ..totalWrongAnswers = 3
          ..dueDate = DateTime.now().toInt();

        var vocab = Vocab()
          ..id = 20
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '20'],
          ]
          ..spacedRepetitionData = spacedRepetitionData;
        var vocab2 = Vocab()
          ..id = 21
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '21'],
          ]
          ..spacedRepetitionData = spacedRepetitionData2;

        await isar.vocabs.put(vocab);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 22; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Check contents
      expect(viewModel.challengingFlashcards.length, 10);
      expect(viewModel.challengingFlashcards.first.id, 19);
      expect(viewModel.challengingFlashcards.last.id, 10);
    });

    test('Flashcard challenging flashcards - English front', () async {
      await isar.writeTxn(() async {
        for (int i = 0; i < 20; i++) {
          var spacedRepetitionData = SpacedRepetitionData()
            ..totalAnswers = i + 1
            ..totalWrongAnswers = i
            ..dueDate = DateTime.now().toInt() + i;

          var vocab = Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ]
            ..spacedRepetitionDataEnglish = spacedRepetitionData;

          await isar.vocabs.put(vocab);
        }

        var spacedRepetitionData = SpacedRepetitionData()
          ..totalAnswers = 20
          ..totalWrongAnswers = 3
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData2 = SpacedRepetitionData()
          ..totalAnswers = 10
          ..totalWrongAnswers = 3
          ..dueDate = DateTime.now().toInt();

        var vocab = Vocab()
          ..id = 20
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '20'],
          ]
          ..spacedRepetitionDataEnglish = spacedRepetitionData;
        var vocab2 = Vocab()
          ..id = 21
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '21'],
          ]
          ..spacedRepetitionDataEnglish = spacedRepetitionData2;

        await isar.vocabs.put(vocab);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 22; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Check contents
      expect(viewModel.challengingFlashcards.length, 10);
      expect(viewModel.challengingFlashcards.first.id, 19);
      expect(viewModel.challengingFlashcards.last.id, 10);
    });

    test('Flashcard challenging flashcards - mismatched data and front type',
        () async {
      await isar.writeTxn(() async {
        for (int i = 0; i < 20; i++) {
          var spacedRepetitionData = SpacedRepetitionData()
            ..totalAnswers = i + 1
            ..totalWrongAnswers = i
            ..dueDate = DateTime.now().toInt() + i;

          var vocab = Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ]
            ..spacedRepetitionData = spacedRepetitionData;

          await isar.vocabs.put(vocab);
        }

        var spacedRepetitionData = SpacedRepetitionData()
          ..totalAnswers = 20
          ..totalWrongAnswers = 3
          ..dueDate = DateTime.now().toInt();
        var spacedRepetitionData2 = SpacedRepetitionData()
          ..totalAnswers = 10
          ..totalWrongAnswers = 3
          ..dueDate = DateTime.now().toInt();

        var vocab = Vocab()
          ..id = 20
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '20'],
          ]
          ..spacedRepetitionData = spacedRepetitionData;
        var vocab2 = Vocab()
          ..id = 21
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '21'],
          ]
          ..spacedRepetitionData = spacedRepetitionData2;

        await isar.vocabs.put(vocab);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 22; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);
      await viewModel.futureToRun();

      // Check contents
      expect(viewModel.challengingFlashcards.length, 0);
    });
  });
}
