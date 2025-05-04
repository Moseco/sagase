import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/ui/views/flashcards/flashcards_viewmodel.dart';
import 'package:sagase/utils/date_time_utils.dart';

import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('FlashcardsViewModelTest', () {
    late DictionaryService dictionaryService;

    setUp(() async {
      registerServices();
      dictionaryService = await getAndRegisterRealDictionaryService();
    });

    tearDown(() async {
      await dictionaryService.close();
      unregisterServices();
    });

    test('Empty flashcard set', () async {
      // Create empty flashcard set
      final flashcardSet = await dictionaryService.createFlashcardSet('name');

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null);
      await viewModel.futureToRun();

      // Verify that back was called correctly
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set', () async {
      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.predefinedDictionaryLists.add(0);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 5);
      expect(viewModel.activeFlashcards.length, 5);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

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

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 3);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Finish set
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);

      // Verify that back was called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set finish half and resume', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 2);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

      // Answer flashcards
      late DictionaryItem tempFlashcard;
      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Recreate the viewmodel (as if user exits and returns to a new session)
      viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

      // Finish last flashcard
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 0);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Verify that back was called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set mixed answers', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 2);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

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
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 1);
      expect(tempFlashcard.spacedRepetitionData!.totalAnswers, 0);
      expect(tempFlashcard.spacedRepetitionData!.totalWrongAnswers, 0);

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());
      expect(tempFlashcard.spacedRepetitionData!.totalAnswers, 1);
      expect(tempFlashcard.spacedRepetitionData!.totalWrongAnswers, 0);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 2);

      // Repeat
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 2);

      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 1);
      expect(tempFlashcard.spacedRepetitionData!.totalAnswers, 0);
      expect(tempFlashcard.spacedRepetitionData!.totalWrongAnswers, 0);

      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 0);

      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 0);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 1);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 2);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      expect(tempFlashcard.spacedRepetitionData!.interval, 1);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.5);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());
      expect(tempFlashcard.spacedRepetitionData!.totalAnswers, 1);
      expect(tempFlashcard.spacedRepetitionData!.totalWrongAnswers, 0);

      // Verify that back was called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set and switch to random order',
        () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

      // Answer flashcards
      final tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Back should not have been called because random order dialog was accepted
      verifyNever(navigationService.back());

      // Now random order
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);
    });

    test('Spaced repetition set with mixed starting spaced repetition data',
        () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab3(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab3());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 3);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 1);

      // Answer flashcards
      late DictionaryItem tempFlashcard;
      // Repeat
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(
          tempFlashcard.spacedRepetitionData!.dueDate, DateTime.now().toInt());
      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 0);
      expect(
          tempFlashcard.spacedRepetitionData!.easeFactor, 2.1799999999999997);
      expect(
          tempFlashcard.spacedRepetitionData!.dueDate, DateTime.now().toInt());
      // Undo
      await viewModel.undo();
      // Correct (causes switch from due cards to new cards)
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.newFlashcards.length, 0);
      expect(tempFlashcard.spacedRepetitionData!.interval, 2);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 2);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.5);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 2)).toInt());

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard.spacedRepetitionData!.initialCorrectCount, 1);
      expect(tempFlashcard.spacedRepetitionData!.dueDate, null);

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 0);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());
    });

    test('Random-order flashcard set', () async {
      // Create flashcard set and assign list
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.usingSpacedRepetition = false;
      flashcardSet.predefinedDictionaryLists.addAll([0, 1]);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Not using spaced repetition
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 10);
      expect(viewModel.activeFlashcards.length, 10);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

      // Answer flashcards
      late DictionaryItem tempFlashcard;
      // Wrong
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(viewModel.activeFlashcards.length, 10);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 9);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 8);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);

      // Back should now have been called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Random-order flashcard set and restart', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.usingSpacedRepetition = false;
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

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
      expect(viewModel.newFlashcards.length, 0);
    });

    test('Undo', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      for (int i = 1; i < 11; i++) {
        await dictionaryService.addToMyDictionaryList(
          dictionaryList,
          await dictionaryService.getVocab(i),
        );
      }
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('一'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('二'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('三'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('四'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('五'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('六'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('七'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('八'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('九'))!);
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, (await dictionaryService.getKanji('十'))!);

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 20);
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Answer flashcard and then undo
      DictionaryItem firstFlashcard = viewModel.activeFlashcards[0];
      DictionaryItem secondFlashcard = viewModel.activeFlashcards[1];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(firstFlashcard.spacedRepetitionData != null, true);
      expect(secondFlashcard.spacedRepetitionData != null, true);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 2);
      await viewModel.undo();
      expect(viewModel.activeFlashcards[0] == secondFlashcard, true);
      await viewModel.undo();
      expect(viewModel.activeFlashcards[0] == firstFlashcard, true);
      expect(firstFlashcard.spacedRepetitionData == null, true);
      expect(secondFlashcard.spacedRepetitionData == null, true);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Answer 10 flashcards and undo to check undo length limit
      expect(viewModel.activeFlashcards.length, 20);
      for (int i = 0; i < 10; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      }
      expect(viewModel.activeFlashcards.length, 10);
      for (int i = 0; i < 10; i++) {
        await viewModel.undo();
        expect(viewModel.activeFlashcards.length, 11 + i);
      }
      expect(viewModel.activeFlashcards.length, 20);

      // Answer 11 flashcards and undo to check undo length limit (will lose 1)
      for (int i = 0; i < 11; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      }
      expect(viewModel.activeFlashcards.length, 9);
      for (int i = 0; i < 10; i++) {
        await viewModel.undo();
        expect(viewModel.activeFlashcards.length, 10 + i);
      }

      // This undo does nothing because limit has been reached
      expect(viewModel.activeFlashcards.length, 19);
      await viewModel.undo();
      expect(viewModel.activeFlashcards.length, 19);
      expect(viewModel.activeFlashcards[0] == secondFlashcard, true);

      // Answer wrong and undo
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Answer repeat and undo
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Answer correct and undo
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Answer all flashcards and check that undo does not work after starting random
      for (int i = 0; i < 19; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      }

      expect(viewModel.activeFlashcards.length, 20);
      await viewModel.undo();
      expect(viewModel.activeFlashcards.length, 20);

      // Make sure undo removes when undoing a wrong answer
      firstFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.activeFlashcards[0] != firstFlashcard, true);
      expect(viewModel.activeFlashcards[14] == firstFlashcard, true);
      await viewModel.undo();
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.activeFlashcards[0] == firstFlashcard, true);
    });

    test('Undo with previous spaced repetition data', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer correct
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionData!.repetitions, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.repetitions, 2);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Verify database has new spaced repetition data
      var fetchedVocab =
          await dictionaryService.getVocab(1, frontType: FrontType.japanese);
      expect(fetchedVocab.spacedRepetitionData!.repetitions, 2);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.repetitions, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Verify database has old spaced repetition data
      fetchedVocab =
          await dictionaryService.getVocab(1, frontType: FrontType.japanese);
      expect(fetchedVocab.spacedRepetitionData!.repetitions, 1);

      // Answer wrong and undo
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 1);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Answer repeat and undo
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
    });

    test('Undo with new card initial correct requirement', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard and undo
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionData, null);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.dueDate, null);
      expect(flashcard.spacedRepetitionData!.initialCorrectCount, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData, null);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Answer the flashcard so spaced repetition data gets set in database
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      expect(flashcard.spacedRepetitionData!.interval, 1);
      expect(flashcard.spacedRepetitionData!.repetitions, 1);
      expect(flashcard.spacedRepetitionData!.easeFactor, 2.5);
      expect(flashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Verify database has spaced repetition data
      var fetchedVocab =
          await dictionaryService.getVocab(1, frontType: FrontType.japanese);
      expect(fetchedVocab.spacedRepetitionData!.dueDate, isNotNull);
      expect(fetchedVocab.spacedRepetitionData!.repetitions, 1);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.dueDate, null);
      expect(flashcard.spacedRepetitionData!.initialCorrectCount, 2);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Verify database has set spaced repetition data due date to null
      fetchedVocab =
          await dictionaryService.getVocab(1, frontType: FrontType.japanese);
      expect(fetchedVocab.spacedRepetitionData!.dueDate, null);
    });

    test('Multiple wrong answers in a row', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard as incorrect
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(flashcard.spacedRepetitionData!.repetitions, 0);
      expect(flashcard.spacedRepetitionData!.easeFactor, 2.1799999999999997);
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(flashcard.spacedRepetitionData!.easeFactor, 2.1799999999999997);
    });

    test('Performance tracking', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionData!.totalAnswers, 1);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(flashcard.spacedRepetitionData!.totalAnswers, 2);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 1);
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(flashcard.spacedRepetitionData!.totalAnswers, 3);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 2);
      // Make sure undo changes values back
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.totalAnswers, 2);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 1);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.totalAnswers, 3);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 1);
    });

    test('Flashcard learning mode enabled', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Set shared preferences
      getAndRegisterSharedPreferencesService(
          getFlashcardLearningModeEnabled: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.learning);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 2);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Complete the due card (not a new card with current seed)
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      // Complete the new card with correct
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Undo and complete with very correct instead
      await viewModel.undo();
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Undo again to check count
      await viewModel.undo();
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
    });

    test('Flashcard start in learning mode', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.learning);
    });

    test('Flashcard start in skip due cards mode', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.skip,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.skip);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.activeFlashcards[0].id, 2);
    });

    test('Flashcard start in normal mode with learning mode enabled', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Set shared preferences
      getAndRegisterSharedPreferencesService(
          getFlashcardLearningModeEnabled: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.normal,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.normal);
    });

    test('Learning mode with more new cards than will be added', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.predefinedDictionaryLists.addAll([0, 1]);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Set shared preferences
      getAndRegisterSharedPreferencesService(getNewFlashcardsPerDay: 4);

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.learning);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 10);
      expect(viewModel.activeFlashcards.length, 5);
      expect(viewModel.newFlashcards.length, 5);
      expect(viewModel.initialDueFlashcardCount, 5);

      // Complete one of the new flashcards (works with the current seed)
      expect(viewModel.activeFlashcards[0].id != 0, true);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);

      // Recreate viewModel (simulate leaving and coming back)
      viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Flashcard contents
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 1);
      expect(viewModel.allFlashcards!.length, 10);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.newFlashcards.length, 5);
      expect(viewModel.initialDueFlashcardCount, 5);

      // Finish the rest of the cards
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 3);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 4);

      // Rest of the new cards should be in the list now
      expect(viewModel.activeFlashcards.length, 5);
    });

    test('Custom flashcard distance', () async {
      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.predefinedDictionaryLists.addAll([0, 1]);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Set shared preferences
      getAndRegisterSharedPreferencesService(getFlashcardDistance: 5);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 10);
      expect(viewModel.activeFlashcards.length, 10);

      // Confirm how far back flashcard is put with different answers
      var flashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(flashcard == viewModel.activeFlashcards[4], true);

      flashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(flashcard == viewModel.activeFlashcards[4], true);

      flashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard == viewModel.activeFlashcards[4], true);
    });

    test('Custom flashcard correct answers required', () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Set shared preferences
      getAndRegisterSharedPreferencesService(
          getFlashcardCorrectAnswersRequired: 2);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcards
      final flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionData, null);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.initialCorrectCount, 1);
      expect(flashcard.spacedRepetitionData!.dueDate, null);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.dueDate != null, true);

      // Undo and correct again
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.initialCorrectCount, 1);
      expect(flashcard.spacedRepetitionData!.dueDate, null);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.dueDate != null, true);
    });

    test('Partially completed flashcards - normal mode', () async {
      // Set spaced repetition data for 5 vocab with long due dates
      for (int i = 1; i < 6; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: 99990101,
            totalAnswers: 1,
          ),
        );
      }

      // Set spaced repetition data for 5 vocab due today
      for (int i = 6; i < 11; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: DateTime.now().toInt(),
            totalAnswers: 1,
          ),
        );
      }

      // Set spaced repetition data for 5 vocab without due date
      for (int i = 11; i < 16; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(interval: 1, repetitions: 1, totalAnswers: 1),
        );
      }

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      // Add 50 vocab
      for (int i = 1; i < 51; i++) {
        await dictionaryService.addToMyDictionaryList(
          dictionaryList,
          await dictionaryService.getVocab(i),
        );
      }

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize using normal mode
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Flashcard contents
      expect(viewModel.activeFlashcards.length, 5);
      expect(viewModel.startedFlashcards.length, 5);
      expect(viewModel.newFlashcards.length, 35);
      expect(viewModel.initialDueFlashcardCount, 5);

      // Verify due flashcard
      expect(
        viewModel.activeFlashcards[0].spacedRepetitionData!.dueDate != null,
        true,
      );

      // Finish due flashcards
      for (int i = 0; i < 5; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.correct);
      }

      // Verify first flashcards are the partially complete ones followed by new ones
      expect(viewModel.activeFlashcards.length, 40);
      expect(viewModel.startedFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);
      expect(
        viewModel.activeFlashcards[0].spacedRepetitionData!.dueDate == null,
        true,
      );
      expect(
        viewModel.activeFlashcards[4].spacedRepetitionData!.dueDate == null,
        true,
      );
      expect(viewModel.activeFlashcards[5].spacedRepetitionData == null, true);
    });

    test('Partially completed flashcards - learning mode', () async {
      // Set spaced repetition data for 5 vocab with long due dates
      for (int i = 1; i < 6; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: 99990101,
            totalAnswers: 1,
          ),
        );
      }

      // Set spaced repetition data for 5 vocab due today
      for (int i = 6; i < 11; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: DateTime.now().toInt(),
            totalAnswers: 1,
          ),
        );
      }

      // Set spaced repetition data for 5 vocab without due date
      for (int i = 11; i < 16; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(interval: 1, repetitions: 1, totalAnswers: 1),
        );
      }

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      // Add 50 vocab
      for (int i = 1; i < 51; i++) {
        await dictionaryService.addToMyDictionaryList(
          dictionaryList,
          await dictionaryService.getVocab(i),
        );
      }

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize using normal mode
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Flashcard contents
      expect(viewModel.activeFlashcards.length, 15);
      expect(viewModel.startedFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 30);
      expect(viewModel.initialDueFlashcardCount, 15);

      // Verify flashcard counts
      int dueFlashcardCount = 0;
      int partialFlashcardCount = 0;
      int newFlashcardCount = 0;
      for (var flashcard in viewModel.activeFlashcards) {
        if (flashcard.spacedRepetitionData == null) {
          newFlashcardCount++;
        } else if (flashcard.spacedRepetitionData!.dueDate == null) {
          partialFlashcardCount++;
        } else {
          dueFlashcardCount++;
        }
      }
      expect(dueFlashcardCount, 5);
      expect(partialFlashcardCount, 5);
      expect(newFlashcardCount, 5);
    });

    test('Partially completed flashcards - skip mode', () async {
      // Set spaced repetition data for 5 vocab with long due dates
      for (int i = 1; i < 6; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: 99990101,
            totalAnswers: 1,
          ),
        );
      }

      // Set spaced repetition data for 5 vocab due today
      for (int i = 6; i < 11; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: DateTime.now().toInt(),
            totalAnswers: 1,
          ),
        );
      }

      // Set spaced repetition data for 5 vocab without due date
      for (int i = 11; i < 16; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(interval: 1, repetitions: 1, totalAnswers: 1),
        );
      }

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      // Add 50 vocab
      for (int i = 1; i < 51; i++) {
        await dictionaryService.addToMyDictionaryList(
          dictionaryList,
          await dictionaryService.getVocab(i),
        );
      }

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize using normal mode
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.skip,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Flashcard contents
      expect(viewModel.activeFlashcards.length, 40);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.startedFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

      // Verify first flashcards are the partially complete ones followed by new ones
      expect(
        viewModel.activeFlashcards[0].spacedRepetitionData!.dueDate == null,
        true,
      );
      expect(
        viewModel.activeFlashcards[4].spacedRepetitionData!.dueDate == null,
        true,
      );
      expect(viewModel.activeFlashcards[5].spacedRepetitionData == null, true);
    });

    test('Flashcard set report basic values', () async {
      // Set spaced repetition data for vocab
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));

      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.newFlashcards.length, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);

      // Answer flashcards
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 1);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 1);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      // Need to undo twice to get to original wrong answer that marked report
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 1);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.undo();
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 0);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 0);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 1);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.flashcardSetReport.dueFlashcardsCompleted, 1);
      expect(viewModel.flashcardSetReport.dueFlashcardsGotWrong, 1);
      expect(viewModel.flashcardSetReport.newFlashcardsCompleted, 0);
    });

    group('Flashcard set streak', () {
      test('No flashcard set report exists', () async {
        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab2());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        await dictionaryService.updateFlashcardSet(flashcardSet);

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        expect(viewModel.flashcardSet.streak, 0);
        expect(viewModel.flashcardSetReport.date, DateTime.now().toInt());
      });

      test('Two day old flashcard set report exists', () async {
        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab2());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        flashcardSet.streak = 1;
        await dictionaryService.updateFlashcardSet(flashcardSet);
        await dictionaryService.createFlashcardSetReport(flashcardSet,
            DateTime.now().subtract(const Duration(days: 2)).toInt());

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        expect(viewModel.flashcardSet.streak, 1);
        expect(viewModel.flashcardSetReport.date, DateTime.now().toInt());
      });

      test('Flashcard set report exists from yesterday', () async {
        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab2());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        flashcardSet.streak = 1;
        await dictionaryService.updateFlashcardSet(flashcardSet);
        await dictionaryService.createFlashcardSetReport(flashcardSet,
            DateTime.now().subtract(const Duration(days: 1)).toInt());

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        expect(viewModel.flashcardSet.streak, 2);
        expect(viewModel.flashcardSetReport.date, DateTime.now().toInt());
      });

      test('Flashcard set report exists for today', () async {
        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab2());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        flashcardSet.streak = 1;
        await dictionaryService.updateFlashcardSet(flashcardSet);
        await dictionaryService.createFlashcardSetReport(
            flashcardSet, DateTime.now().toInt());

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        expect(viewModel.flashcardSet.streak, 1);
        expect(viewModel.flashcardSetReport.date, DateTime.now().toInt());
      });
    });

    group('Flashcard set report dialog', () {
      test('Dialog not shown because only new flashcards finished', () async {
        final navigationService = getAndRegisterNavigationService();
        final dialogService = getAndRegisterDialogService();
        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab2());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        await dictionaryService.updateFlashcardSet(flashcardSet);
        await dictionaryService.createFlashcardSetReport(
            flashcardSet, DateTime.now().toInt());

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);

        // Verify dialog
        verifyNever(dialogService.showCustomDialog(
          variant: DialogType.flashcardSetReport,
          data: anyNamed('data'),
          barrierDismissible: true,
        ));
        verify(navigationService.back());
      });

      test('Dialog shown because due flashcards finished', () async {
        final navigationService = getAndRegisterNavigationService();
        final dialogService = getAndRegisterDialogService();
        // Set spaced repetition data for vocab
        await dictionaryService.setSpacedRepetitionData(
            SpacedRepetitionData.initial(
                    dictionaryItem: getVocab1(), frontType: FrontType.japanese)
                .copyWith(
                    interval: 1,
                    repetitions: 1,
                    dueDate: DateTime.now().toInt(),
                    totalAnswers: 1));

        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab2());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        await dictionaryService.updateFlashcardSet(flashcardSet);
        await dictionaryService.createFlashcardSetReport(
            flashcardSet, DateTime.now().toInt());

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);

        verify(dialogService.showCustomDialog(
          variant: DialogType.flashcardSetReport,
          data: anyNamed('data'),
          barrierDismissible: true,
        )).called(1);
        verifyNever(navigationService.back());

        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);

        verifyNever(dialogService.showCustomDialog(
          variant: DialogType.flashcardSetReport,
          data: anyNamed('data'),
          barrierDismissible: true,
        ));
        verify(navigationService.back());
      });

      test('Dialog not shown because no due or new flashcards', () async {
        final navigationService = getAndRegisterNavigationService();
        final dialogService = getAndRegisterDialogService();

        // Set spaced repetition data for vocab
        await dictionaryService.setSpacedRepetitionData(
            SpacedRepetitionData.initial(
                    dictionaryItem: getVocab1(), frontType: FrontType.japanese)
                .copyWith(
                    interval: 1,
                    repetitions: 1,
                    dueDate:
                        DateTime.now().add(const Duration(days: 1)).toInt(),
                    totalAnswers: 1));

        // Create dictionary lists to use
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list1');
        await dictionaryService.addToMyDictionaryList(
            dictionaryList, getVocab1());

        // Create flashcard set and assign lists
        final flashcardSet = await dictionaryService.createFlashcardSet('name');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        await dictionaryService.updateFlashcardSet(flashcardSet);
        await dictionaryService.createFlashcardSetReport(
            flashcardSet, DateTime.now().toInt());

        // Call initialize
        var viewModel =
            FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
        await viewModel.futureToRun();

        // Verify dialog
        verifyNever(dialogService.showCustomDialog(
          variant: DialogType.flashcardSetReport,
          data: anyNamed('data'),
          barrierDismissible: true,
        ));
        verify(navigationService.back());
      });
    });

    test('Spread out due flashcards', () async {
      await dictionaryService.close();
      dictionaryService =
          await getAndRegisterRealDictionaryService(vocabToCreate: 305);
      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Set spaced repetition data for vocab
      for (int i = 1; i <= 305; i++) {
        await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
            dictionaryItem: await dictionaryService.getVocab(i),
            frontType: FrontType.japanese,
          ).copyWith(
            interval: 1,
            repetitions: 1,
            dueDate: DateTime.now().toInt(),
            totalAnswers: 1,
          ),
        );
      }

      // Create dictionary list to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      for (int i = 1; i <= 305; i++) {
        await dictionaryService.addToMyDictionaryList(
          dictionaryList,
          await dictionaryService.getVocab(i),
        );
      }

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.timestamp = DateTime.now().subtract(const Duration(days: 7));
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet,
          updateTimestamp: false);
      await dictionaryService.createFlashcardSetReport(
          flashcardSet, flashcardSet.timestamp.toInt());

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify active flashcards
      expect(viewModel.activeFlashcards.length, 150);

      // Verify dialog
      verify(dialogService.showCustomDialog(
        variant: DialogType.confirmation,
        title: anyNamed('title'),
        description: anyNamed('description'),
        mainButtonTitle: anyNamed('mainButtonTitle'),
        secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
        barrierDismissible: true,
      )).called(1);

      // Load flashcards and verify due dates
      final flashcards =
          await dictionaryService.getFlashcardSetFlashcards(flashcardSet);
      List<int> dueDateCounts = List.filled(14, 0);
      final now = DateTime.parse(DateTime.now().toInt().toString());
      for (final flashcard in flashcards) {
        int difference =
            DateTime.parse(flashcard.spacedRepetitionData!.dueDate.toString())
                .difference(now)
                .inDays;
        dueDateCounts[difference]++;
      }
      expect(dueDateCounts[0], 150);
      expect(dueDateCounts[1], 12);
      expect(dueDateCounts.last, 11);
    });

    test('Do not create flashcard set report if not using spaced repetition',
        () async {
      // Create dictionary lists to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign lists
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      flashcardSet.usingSpacedRepetition = false;
      await dictionaryService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Check results
      final report =
          await dictionaryService.getRecentFlashcardSetReport(flashcardSet);
      expect(report, null);
    });
  });
}
