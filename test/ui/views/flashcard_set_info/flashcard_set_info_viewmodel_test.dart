import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
import 'package:sagase/datamodels/vocab.dart';
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
      await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 8; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(
            isarService.myDictionaryLists![0], vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);

      // wait for loading to finished
      while (true) {
        if (!viewModel.loading) break;
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.upcomingDueFlashcards.length, 8);
      expect(viewModel.upcomingDueFlashcards[0], 1);
      expect(viewModel.upcomingDueFlashcards[1], 1);
      expect(viewModel.upcomingDueFlashcards[2], 1);
      expect(viewModel.upcomingDueFlashcards[3], 1);
      expect(viewModel.upcomingDueFlashcards[4], 1);
      expect(viewModel.upcomingDueFlashcards[5], 1);
      expect(viewModel.upcomingDueFlashcards[6], 1);
      expect(viewModel.upcomingDueFlashcards[7], 1);
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
          ];

        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
        await isar.vocabs.put(vocab4);
        await isar.vocabs.put(vocab5);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 5; i++) {
        var vocab = Vocab()..id = i;
        await isarService.addVocabToMyDictionaryList(
            isarService.myDictionaryLists![0], vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(flashcardSet);

      // wait for loading to finished
      while (true) {
        if (!viewModel.loading) break;
        await Future.delayed(const Duration(milliseconds: 1));
      }

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.flashcardIntervalCounts[0], 1);
      expect(viewModel.flashcardIntervalCounts[1], 1);
      expect(viewModel.flashcardIntervalCounts[2], 1);
      expect(viewModel.flashcardIntervalCounts[3], 1);
      expect(viewModel.flashcardIntervalCounts[4], 1);
    });
  });
}