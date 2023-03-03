import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
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

    test('Empty flashcard set', () async {
      // Create empty flashcard set
      final flashcardSet = await isarService.createFlashcardSet('name');

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null);
      await viewModel.initialize();

      // Verify that back was called correctly
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set', () async {
      // Create vocab and kanji to use
      final vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1']
        ];
      final vocab2 = Vocab()
        ..id = 2
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '2']
        ];
      final vocab3 = Vocab()
        ..id = 3
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '3']
        ];
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
      await isar.writeTxn(() async {
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
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 6);
      expect(viewModel.activeFlashcards.length, 6);
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
      expect(viewModel.activeFlashcards.length, 5);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
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
      // Create vocab to use
      final vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1']
        ];
      final vocab2 = Vocab()
        ..id = 2
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '2']
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(flashcardSet,
          myDictionaryLists: [isarService.myDictionaryLists![0]]);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      await viewModel.initialize();

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
      // Create vocab to use
      final vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1']
        ];
      final vocab2 = Vocab()
        ..id = 2
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '2']
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(flashcardSet,
          myDictionaryLists: [isarService.myDictionaryLists![0]]);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 1);
      expect(tempFlashcard.spacedRepetitionData!.interval, 4);
      expect(tempFlashcard.spacedRepetitionData!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionData!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionData!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

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

      // Verify that back was called because exit dialog was accepted
      verify(navigationService.back());
    });

    test('Spaced repetition flashcard set and switch to random order',
        () async {
      // Create vocab to use
      final vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1']
        ];
      await isar.writeTxn(() async {
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
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      // Create vocab to use
      var spacedRepetitionData1 = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt()
        ..totalAnswers = 1;
      var spacedRepetitionData2 = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt() + 1
        ..totalAnswers = 1;

      var vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
        ]
        ..spacedRepetitionData = spacedRepetitionData1;
      var vocab2 = Vocab()
        ..id = 2
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '2'],
        ];
      var vocab3 = Vocab()
        ..id = 3
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '3'],
        ]
        ..spacedRepetitionData = spacedRepetitionData2;

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
        await isar.vocabs.put(vocab3);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab3);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      viewModel.undo();
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
      // Create vocab and kanji to use
      final vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1']
        ];
      final vocab2 = Vocab()
        ..id = 2
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '2']
        ];
      final kanji1 = Kanji()
        ..id = 1
        ..kanji = '1'
        ..strokeCount = 0;
      final kanji2 = Kanji()
        ..id = 2
        ..kanji = '2'
        ..strokeCount = 0;
      await isar.writeTxn(() async {
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
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Not using spaced repetition
      expect(viewModel.usingSpacedRepetition, false);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 4);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

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

    test('Random-order flashcard set and restart', () async {
      // Create vocab to use
      final vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1']
        ];
      await isar.writeTxn(() async {
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
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      // Create 20 vocab to use
      await isar.writeTxn(() async {
        for (int i = 0; i < 20; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]);
        }
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 20; i++) {
        await isarService.addVocabToMyDictionaryList(
            isarService.myDictionaryLists![0], Vocab()..id = i);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      final navigationService = getAndRegisterNavigationService();
      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 20);
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);

      // Answer flashcard and then undo
      DictionaryItem firstFlashcard = viewModel.activeFlashcards[0];
      DictionaryItem secondFlashcard = viewModel.activeFlashcards[1];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(firstFlashcard.spacedRepetitionData != null, true);
      expect(secondFlashcard.spacedRepetitionData != null, true);
      viewModel.undo();
      expect(viewModel.activeFlashcards[0] == secondFlashcard, true);
      viewModel.undo();
      expect(viewModel.activeFlashcards[0] == firstFlashcard, true);
      expect(firstFlashcard.spacedRepetitionData == null, true);
      expect(secondFlashcard.spacedRepetitionData == null, true);

      // Answer 10 flashcards and undo to check undo length limit
      expect(viewModel.activeFlashcards.length, 20);
      for (int i = 0; i < 10; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      }
      expect(viewModel.activeFlashcards.length, 10);
      for (int i = 0; i < 10; i++) {
        viewModel.undo();
        expect(viewModel.activeFlashcards.length, 11 + i);
      }
      expect(viewModel.activeFlashcards.length, 20);

      // Answer 11 flashcards and undo to check undo length limit (will lose 1)
      for (int i = 0; i < 11; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      }
      expect(viewModel.activeFlashcards.length, 9);
      for (int i = 0; i < 10; i++) {
        viewModel.undo();
        expect(viewModel.activeFlashcards.length, 10 + i);
      }

      // This undo does nothing because limit has been reached
      expect(viewModel.activeFlashcards.length, 19);
      viewModel.undo();
      expect(viewModel.activeFlashcards.length, 19);
      expect(viewModel.activeFlashcards[0] == secondFlashcard, true);

      // Answer all flashcards and check that undo does not work after starting random
      for (int i = 0; i < 19; i++) {
        await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      }

      expect(viewModel.activeFlashcards.length, 20);
      viewModel.undo();
      expect(viewModel.activeFlashcards.length, 20);

      // Make sure undo removes when undoing a wrong answer
      firstFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.wrong);
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.activeFlashcards[0] != firstFlashcard, true);
      expect(viewModel.activeFlashcards[14] == firstFlashcard, true);
      viewModel.undo();
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.activeFlashcards[0] == firstFlashcard, true);
    });

    test('Undo with previous spaced repetition data', () async {
      // Create vocab to use
      var spacedRepetitionData = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt()
        ..totalAnswers = 1;

      var vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
        ]
        ..spacedRepetitionData = spacedRepetitionData;
      var vocab2 = Vocab()
        ..id = 2
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '2'],
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionData!.repetitions, 1);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.repetitions, 2);

      // Verify database has new spaced repetition data
      var fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData!.repetitions, 2);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.repetitions, 1);

      // Verify database has old spaced repetition data
      fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData!.repetitions, 1);
    });

    test('Undo with new card initial correct requirement', () async {
      // Create vocab to use
      var vocab1 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      viewModel.undo();
      expect(flashcard.spacedRepetitionData, null);

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

      // Verify database has spaced repetition data
      var fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData!.repetitions, 1);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.dueDate, null);
      expect(flashcard.spacedRepetitionData!.initialCorrectCount, 2);

      // Verify database has set spaced repetition data to null
      fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData, null);
    });

    test('Multiple wrong answers in a row', () async {
      // Create vocab to use
      var spacedRepetitionData = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt();

      var vocab = Vocab()
        ..id = 0
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
        ]
        ..spacedRepetitionData = spacedRepetitionData;

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      // Create vocab to use
      var spacedRepetitionData = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt()
        ..totalAnswers = 1;

      var vocab = Vocab()
        ..id = 0
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
        ]
        ..spacedRepetitionData = spacedRepetitionData;

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

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
      viewModel.undo();
      expect(flashcard.spacedRepetitionData!.totalAnswers, 2);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 1);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.totalAnswers, 3);
      expect(flashcard.spacedRepetitionData!.totalWrongAnswers, 1);
    });

    test('Flashcard learning mode enabled', () async {
      // Create vocab to use
      var spacedRepetitionData = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt();

      var vocab1 = Vocab()
        ..id = 0
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
        ]
        ..spacedRepetitionData = spacedRepetitionData;

      var vocab2 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Set shared preferences
      getAndRegisterSharedPreferencesService(
          flashcardLearningModeEnabled: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.initialize();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.learning);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 2);

      // Complete the due card (not a new card with current seed)
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      // Complete the new card with correct
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Undo and complete with very correct instead
      viewModel.undo();
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);
    });

    test('Flashcard start in learning mode', () async {
      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.initialize();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.learning);
    });

    test('Flashcard start in skip due cards mode', () async {
      // Create vocab to use
      var spacedRepetitionData = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt();

      var vocab1 = Vocab()
        ..id = 0
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
        ]
        ..spacedRepetitionData = spacedRepetitionData;

      var vocab2 = Vocab()
        ..id = 1
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '1'],
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab1);
      await isarService.addVocabToMyDictionaryList(
          isarService.myDictionaryLists![0], vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.skip,
        randomSeed: 123,
      );
      await viewModel.initialize();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.skip);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.activeFlashcards[0].id, 1);
    });

    test('Flashcard start in normal mode with learning mode enabled', () async {
      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Set shared preferences
      getAndRegisterSharedPreferencesService(
          flashcardLearningModeEnabled: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.normal,
        randomSeed: 123,
      );
      await viewModel.initialize();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.normal);
    });

    test('Learning mode with more new cards than will be added', () async {
      // Create vocab to use
      var spacedRepetitionData = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 1
        ..easeFactor = 2.5
        ..dueDate = DateTime.now().toInt();

      List<Vocab> vocabs = [
        Vocab()
          ..id = 0
          ..kanjiReadingPairs = [
            KanjiReadingPair()..readings = [VocabReading()..reading = '0'],
          ]
          ..spacedRepetitionData = spacedRepetitionData,
      ];

      for (int i = 0; i < 10; i++) {
        vocabs.add(
          Vocab()
            ..id = i + 1
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = (i + 1).toString()],
            ],
        );
      }

      await isar.writeTxn(() async {
        for (var vocab in vocabs) {
          await isar.vocabs.put(vocab);
        }
      });

      // Create dictionary lists to use
      await isarService.createMyDictionaryList('list1');
      for (var vocab in vocabs) {
        await isarService.addVocabToMyDictionaryList(
            isarService.myDictionaryLists![0], vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      await isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        myDictionaryLists: [isarService.myDictionaryLists![0]],
      );

      // Set shared preferences
      getAndRegisterSharedPreferencesService(newFlashcardsPerDay: 4);

      // Call initialize
      var viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.initialize();

      // Using spaced repetition with learning mode enabled
      expect(viewModel.usingSpacedRepetition, true);
      expect(viewModel.startMode, FlashcardStartMode.learning);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 11);
      expect(viewModel.activeFlashcards.length, 5);
      expect(viewModel.newFlashcards.length, 6);

      // Complete one of the new flashcards (works with the current seed)
      expect(viewModel.activeFlashcards[0].id != 0, true);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Recreate viewModel (simulate leaving and coming back)
      viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.initialize();

      // Flashcard contents
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);
      expect(viewModel.allFlashcards!.length, 11);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.newFlashcards.length, 6);

      // Finish the rest of the cards
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 3);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 4);

      // Rest of the new cards should be in the list now
      expect(viewModel.activeFlashcards.length, 6);
    });
  });
}
