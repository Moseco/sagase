import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/ui/views/flashcards/flashcards_viewmodel.dart';
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

    test('Initialize with empty flashcard set', () async {
      // Create empty flashcard set
      final flashcardSet = await isarService.createFlashcardSet('name');

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was called correctly
      verify(navigationService.back());
    });

    test('Initialize with spaced repetition flashcard set', () async {
      // Create vocab and kanji to use
      final vocab1 = Vocab()..id = 1;
      final vocab2 = Vocab()..id = 2;
      final vocab3 = Vocab()..id = 3;
      final kanji1 = Kanji()
        ..id = 1
        ..kanji = '1'
        ..radical = 0
        ..strokeCount = 0;
      final kanji2 = Kanji()
        ..id = 2
        ..kanji = '2'
        ..radical = 0
        ..strokeCount = 0;
      final kanji3 = Kanji()
        ..id = 3
        ..kanji = '3'
        ..radical = 0
        ..strokeCount = 0;
      isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);

        await isar.kanjis.put(kanji1);
        await isar.kanjis.put(kanji2);
        await isar.kanjis.put(kanji3);
      });

      // Create dictionary lists to use
      // Overlap between lists is on purpose
      await isarService.createMyDictionaryList('list1');
      await isarService.createMyDictionaryList('list2');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![1], vocab2);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![1], vocab3);
      await isarService.addKanjiToMyDictionaryList(
          isarService.myDictionaryLists![0], kanji1);
      await isarService.addKanjiToMyDictionaryList(
          isarService.myDictionaryLists![0], kanji2);
      await isarService.addKanjiToMyDictionaryList(
          isarService.myDictionaryLists![1], kanji2);
      await isarService.addKanjiToMyDictionaryList(
          isarService.myDictionaryLists![1], kanji3);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(flashcardSet,
          myDictionaryLists: [
            isarService.myDictionaryLists![0],
            isarService.myDictionaryLists![1]
          ]);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 6);
      expect(viewModel.activeFlashcards.length, 6);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);

      // Answer flashcards
      late DictionaryItem tempFlashcard;
      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData, null);

      // Repeat
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData, null);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 5);
      expect(tempFlashcard.spacedRepetitionData!.interval, 1);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.5);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(tempFlashcard.spacedRepetitionData!.interval, 1);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());

      // Recreate the viewmodel (as if user exits and returns to a new session)
      viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 6);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);

      // Manually modify the due words to today
      for (int i = 0; i < viewModel.allFlashcards!.length; i++) {
        if (viewModel.allFlashcards![i].spacedRepetitionData != null) {
          viewModel.allFlashcards![i].spacedRepetitionData!.dueDate =
              DateTime.now().toInt();
          await isarService
              .updateSpacedRepetitionData(viewModel.allFlashcards![i]);
        }
      }

      // Recreate the viewmodel (as if user exits and returns to a new session)
      viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 6);
      expect(viewModel.activeFlashcards.length, 2);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 4);

      // Answer flashcards

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard.spacedRepetitionData!.interval, 2);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 2);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.5);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 2)).toInt());

      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard.spacedRepetitionData!.interval, 0);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 0);
      expect(
          tempFlashcard.spacedRepetitionData!.easeFactor, 2.2800000000000002);
      expect(
          tempFlashcard.spacedRepetitionData!.dueDate, DateTime.now().toInt());

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(tempFlashcard.spacedRepetitionData!.interval, 1);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(
          tempFlashcard.spacedRepetitionData!.easeFactor, 2.3800000000000003);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());

      // Answer the rest of the words without checking
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);

      // Back should now have been called because exit dialog was accepted
      verify(navigationService.back());

      // Recreate the viewmodel (as if user exits and returns to a new session)
      viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 6);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);

      // Back should now have been called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Initialize with random-order flashcard set', () async {
      // Create vocab and kanji to use
      final vocab1 = Vocab()..id = 1;
      final vocab2 = Vocab()..id = 2;
      final kanji1 = Kanji()
        ..id = 1
        ..kanji = '1'
        ..radical = 0
        ..strokeCount = 0;
      final kanji2 = Kanji()
        ..id = 2
        ..kanji = '2'
        ..radical = 0
        ..strokeCount = 0;
      isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);

        await isar.kanjis.put(kanji1);
        await isar.kanjis.put(kanji2);
      });

      // Create dictionary list to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);
      await isarService.addKanjiToMyDictionaryList(
          isarService.myDictionaryLists![0], kanji1);
      await isarService.addKanjiToMyDictionaryList(
          isarService.myDictionaryLists![0], kanji2);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.usingSpacedRepetition = false;
      await isarService.updateFlashcardSet(flashcardSet);
      await isarService.addDictionaryListsToFlashcardSet(flashcardSet,
          myDictionaryLists: [isarService.myDictionaryLists![0]]);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Not using spaced repetition
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 4);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);

      // Answer flashcards
      late DictionaryItem tempFlashcard;
      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(viewModel.activeFlashcards.length, 4);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 3);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 2);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);

      // Back should now have been called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set and switch to random order',
        () async {
      // Create vocab and kanji to use
      final vocab1 = Vocab()..id = 1;
      isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
      });

      // Create dictionary list to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(flashcardSet,
          myDictionaryLists: [isarService.myDictionaryLists![0]]);

      final navigationService = getAndRegisterNavigationService();
      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);

      // Answer flashcards
      final tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(tempFlashcard.spacedRepetitionData!.interval, 1);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.5);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());

      // Back should not have been called because random order dialog was accepted
      verifyNever(navigationService.back());

      // Now random order
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);
    });

    test('Random-order flashcard set and go again', () async {
      // Create vocab and kanji to use
      final vocab1 = Vocab()..id = 1;
      isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
      });

      // Create dictionary list to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.usingSpacedRepetition = false;
      await isarService.updateFlashcardSet(flashcardSet);
      await isarService.addDictionaryListsToFlashcardSet(flashcardSet,
          myDictionaryLists: [isarService.myDictionaryLists![0]]);

      final navigationService = getAndRegisterNavigationService();
      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);

      // Answer flashcards
      viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);

      // Back should not have been called restart dialog was accepted
      verifyNever(navigationService.back());

      // Now random order
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.freshFlashcards.length, 0);
    });
  });
}
