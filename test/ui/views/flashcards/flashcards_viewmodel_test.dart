import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
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
      await viewModel.futureToRun();

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
      final list1 = await isarService.createMyDictionaryList('list1');
      final list2 = await isarService.createMyDictionaryList('list2');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);
      await isarService.addVocabToMyDictionaryList(list2, vocab2);
      await isarService.addVocabToMyDictionaryList(list2, vocab3);
      await isarService.addKanjiToMyDictionaryList(list1, kanji1);
      await isarService.addKanjiToMyDictionaryList(list1, kanji2);
      await isarService.addKanjiToMyDictionaryList(list2, kanji2);
      await isarService.addKanjiToMyDictionaryList(list2, kanji3);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      flashcardSet.myDictionaryLists.add(list2.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

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

    test('Spaced repetition flashcard set - English front', () async {
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
      final list1 = await isarService.createMyDictionaryList('list1');
      final list2 = await isarService.createMyDictionaryList('list2');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);
      await isarService.addVocabToMyDictionaryList(list2, vocab2);
      await isarService.addVocabToMyDictionaryList(list2, vocab3);
      await isarService.addKanjiToMyDictionaryList(list1, kanji1);
      await isarService.addKanjiToMyDictionaryList(list1, kanji2);
      await isarService.addKanjiToMyDictionaryList(list2, kanji2);
      await isarService.addKanjiToMyDictionaryList(list2, kanji3);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      flashcardSet.myDictionaryLists.add(list2.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // English front
      expect(viewModel.flashcardSet.frontType, FrontType.english);

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
      expect(tempFlashcard.spacedRepetitionDataEnglish, null);

      // Repeat
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.repeat);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(tempFlashcard.spacedRepetitionDataEnglish, null);

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 5);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.interval, 4);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.dueDate,
          DateTime.now().add(const Duration(days: 4)).toInt());

      // Very correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.interval, 4);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.repetitions, 1);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.easeFactor, 2.6);
      expect(tempFlashcard.spacedRepetitionDataEnglish!.dueDate,
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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);
      await isarService.addVocabToMyDictionaryList(list1, vocab3);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
        ..id = 'a'.kanjiCodePoint()
        ..kanji = 'a'
        ..radical = 'a'
        ..strokeCount = 0;
      final kanji2 = Kanji()
        ..id = 'b'.kanjiCodePoint()
        ..kanji = 'b'
        ..radical = 'b'
        ..strokeCount = 0;
      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab1);
        await isar.vocabs.put(vocab2);

        await isar.kanjis.put(kanji1);
        await isar.kanjis.put(kanji2);
      });

      // Create dictionary list to use
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);
      await isarService.addKanjiToMyDictionaryList(list1, kanji1);
      await isarService.addKanjiToMyDictionaryList(list1, kanji2);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.usingSpacedRepetition = false;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.usingSpacedRepetition = false;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 20; i++) {
        await isarService.addVocabToMyDictionaryList(list1, Vocab()..id = i);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Answer flashcard and then undo
      DictionaryItem firstFlashcard = viewModel.activeFlashcards[0];
      DictionaryItem secondFlashcard = viewModel.activeFlashcards[1];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(firstFlashcard.spacedRepetitionData != null, true);
      expect(secondFlashcard.spacedRepetitionData != null, true);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 2);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 2);
      viewModel.undo();
      expect(viewModel.activeFlashcards[0] == secondFlashcard, true);
      viewModel.undo();
      expect(viewModel.activeFlashcards[0] == firstFlashcard, true);
      expect(firstFlashcard.spacedRepetitionData == null, true);
      expect(secondFlashcard.spacedRepetitionData == null, true);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

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

    test('Undo - English front', () async {
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
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 20; i++) {
        await isarService.addVocabToMyDictionaryList(list1, Vocab()..id = i);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDialogService(dialogResponseConfirmed: true);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // English front
      expect(viewModel.flashcardSet.frontType, FrontType.english);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 20);
      expect(viewModel.activeFlashcards.length, 20);
      expect(viewModel.dueFlashcards.length, 0);
      expect(viewModel.newFlashcards.length, 0);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Answer flashcard and then undo
      DictionaryItem firstFlashcard = viewModel.activeFlashcards[0];
      DictionaryItem secondFlashcard = viewModel.activeFlashcards[1];
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(firstFlashcard.spacedRepetitionDataEnglish != null, true);
      expect(secondFlashcard.spacedRepetitionDataEnglish != null, true);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 2);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 2);
      viewModel.undo();
      expect(viewModel.activeFlashcards[0] == secondFlashcard, true);
      viewModel.undo();
      expect(viewModel.activeFlashcards[0] == firstFlashcard, true);
      expect(firstFlashcard.spacedRepetitionDataEnglish == null, true);
      expect(secondFlashcard.spacedRepetitionDataEnglish == null, true);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionData!.repetitions, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionData!.repetitions, 2);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Verify database has new spaced repetition data
      var fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData!.repetitions, 2);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.repetitions, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Verify database has old spaced repetition data
      fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData!.repetitions, 1);
    });

    test('Undo with previous spaced repetition data - English front', () async {
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
        ..spacedRepetitionDataEnglish = spacedRepetitionData;
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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // English front
      expect(viewModel.flashcardSet.frontType, FrontType.english);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 2);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionDataEnglish!.repetitions, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionDataEnglish!.repetitions, 2);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Verify database has new spaced repetition data
      var fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionDataEnglish!.repetitions, 2);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionDataEnglish!.repetitions, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Verify database has old spaced repetition data
      fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionDataEnglish!.repetitions, 1);
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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      viewModel.undo();
      expect(flashcard.spacedRepetitionData, null);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

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
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Verify database has spaced repetition data
      var fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData!.repetitions, 1);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionData!.dueDate, null);
      expect(flashcard.spacedRepetitionData!.initialCorrectCount, 2);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Verify database has set spaced repetition data to null
      fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionData, null);
    });

    test('Undo with new card initial correct requirement - English front',
        () async {
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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.frontType = FrontType.english;
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Call initialize
      var viewModel = FlashcardsViewModel(flashcardSet, null, randomSeed: 123);
      await viewModel.futureToRun();

      // Using spaced repetition
      expect(viewModel.usingSpacedRepetition, true);

      // English front
      expect(viewModel.flashcardSet.frontType, FrontType.english);

      // Flashcard contents
      expect(viewModel.allFlashcards!.length, 1);
      expect(viewModel.activeFlashcards.length, 1);

      // Answer flashcard and undo
      DictionaryItem flashcard = viewModel.activeFlashcards[0];
      expect(flashcard.spacedRepetitionDataEnglish, null);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(flashcard.spacedRepetitionDataEnglish!.dueDate, null);
      expect(flashcard.spacedRepetitionDataEnglish!.initialCorrectCount, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      viewModel.undo();
      expect(flashcard.spacedRepetitionDataEnglish, null);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Answer the flashcard so spaced repetition data gets set in database
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      await viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      expect(flashcard.spacedRepetitionDataEnglish!.interval, 1);
      expect(flashcard.spacedRepetitionDataEnglish!.repetitions, 1);
      expect(flashcard.spacedRepetitionDataEnglish!.easeFactor, 2.5);
      expect(flashcard.spacedRepetitionDataEnglish!.dueDate,
          DateTime.now().add(const Duration(days: 1)).toInt());
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Verify database has spaced repetition data
      var fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionDataEnglish!.repetitions, 1);

      // Undo
      await viewModel.undo();
      expect(flashcard.spacedRepetitionDataEnglish!.dueDate, null);
      expect(flashcard.spacedRepetitionDataEnglish!.initialCorrectCount, 2);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Verify database has set spaced repetition data to null
      fetchedVocab = await isar.vocabs.get(1);
      expect(fetchedVocab!.spacedRepetitionDataEnglish, null);
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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 0);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);

      // Complete the due card (not a new card with current seed)
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      // Complete the new card with correct
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      viewModel.answerFlashcard(FlashcardAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 2);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Undo and complete with very correct instead
      viewModel.undo();
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
      viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 0);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 2);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Undo again to check count
      viewModel.undo();
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 0);
    });

    test('Flashcard start in learning mode', () async {
      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab1);
      await isarService.addVocabToMyDictionaryList(list1, vocab2);

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      expect(viewModel.activeFlashcards[0].id, 1);
    });

    test('Flashcard start in normal mode with learning mode enabled', () async {
      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final list1 = await isarService.createMyDictionaryList('list1');
      for (var vocab in vocabs) {
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      expect(viewModel.allFlashcards!.length, 11);
      expect(viewModel.activeFlashcards.length, 5);
      expect(viewModel.newFlashcards.length, 6);
      expect(viewModel.initialDueFlashcardCount, 5);

      // Complete one of the new flashcards (works with the current seed)
      expect(viewModel.activeFlashcards[0].id != 0, true);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);

      // Recreate viewModel (simulate leaving and coming back)
      viewModel = FlashcardsViewModel(
        flashcardSet,
        FlashcardStartMode.learning,
        randomSeed: 123,
      );
      await viewModel.futureToRun();

      // Flashcard contents
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 1);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 1);
      expect(viewModel.allFlashcards!.length, 11);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.newFlashcards.length, 6);
      expect(viewModel.initialDueFlashcardCount, 5);

      // Finish the rest of the cards
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.activeFlashcards.length, 1);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 4);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 3);
      await viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
      expect(viewModel.flashcardSet.flashcardsCompletedToday, 5);
      expect(viewModel.flashcardSet.newFlashcardsCompletedToday, 4);

      // Rest of the new cards should be in the list now
      expect(viewModel.activeFlashcards.length, 6);
    });

    test('Custom flashcard distance', () async {
      // Create vocab to use
      List<Vocab> vocabs = [];

      for (int i = 0; i < 10; i++) {
        vocabs.add(
          Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()],
            ],
        );
      }

      await isar.writeTxn(() async {
        for (var vocab in vocabs) {
          await isar.vocabs.put(vocab);
        }
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (var vocab in vocabs) {
        await isarService.addVocabToMyDictionaryList(list1, vocab);
      }

      // Create flashcard set and assign lists
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      // Create vocab to use
      final vocab = Vocab()
        ..id = 0
        ..kanjiReadingPairs = [
          KanjiReadingPair()..readings = [VocabReading()..reading = '0']
        ];

      await isar.writeTxn(() async {
        await isar.vocabs.put(vocab);
      });

      // Create dictionary list to use
      final list1 = await isarService.createMyDictionaryList('list1');
      await isarService.addVocabToMyDictionaryList(list1, vocab);

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final now = DateTime.now();
      await isar.writeTxn(() async {
        // Create 5 vocab with long due dates
        final longDueDate = SpacedRepetitionData()..dueDate = 99999999;
        for (int i = 0; i < 5; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = longDueDate);
        }

        // Create 5 vocab due today
        final dueToday = SpacedRepetitionData()..dueDate = now.toInt();
        for (int i = 5; i < 10; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = dueToday);
        }

        // Create 5 vocab that were partially completed
        for (int i = 10; i < 15; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = SpacedRepetitionData());
        }

        // Create 35 new vocab
        for (int i = 15; i < 50; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]);
        }
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 50; i++) {
        await isarService.addVocabToMyDictionaryList(list1, Vocab()..id = i);
      }

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

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
      final now = DateTime.now();
      await isar.writeTxn(() async {
        // Create 5 vocab with long due dates
        final longDueDate = SpacedRepetitionData()..dueDate = 99999999;
        for (int i = 0; i < 5; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = longDueDate);
        }

        // Create 5 vocab due today
        final dueToday = SpacedRepetitionData()..dueDate = now.toInt();
        for (int i = 5; i < 10; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = dueToday);
        }

        // Create 5 vocab that were partially completed
        for (int i = 10; i < 15; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = SpacedRepetitionData());
        }

        // Create 35 new vocab
        for (int i = 15; i < 50; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]);
        }
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 50; i++) {
        await isarService.addVocabToMyDictionaryList(list1, Vocab()..id = i);
      }

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Call initialize using normal mode
      var viewModel = FlashcardsViewModel(
          flashcardSet, FlashcardStartMode.learning,
          randomSeed: 123);
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
      final now = DateTime.now();
      await isar.writeTxn(() async {
        // Create 5 vocab with long due dates
        final longDueDate = SpacedRepetitionData()..dueDate = 99999999;
        for (int i = 0; i < 5; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = longDueDate);
        }

        // Create 5 vocab due today
        final dueToday = SpacedRepetitionData()..dueDate = now.toInt();
        for (int i = 5; i < 10; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = dueToday);
        }

        // Create 5 vocab that were partially completed
        for (int i = 10; i < 15; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]
            ..spacedRepetitionData = SpacedRepetitionData());
        }

        // Create 35 new vocab
        for (int i = 15; i < 50; i++) {
          await isar.vocabs.put(Vocab()
            ..id = i
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..readings = [VocabReading()..reading = i.toString()]
            ]);
        }
      });

      // Create dictionary lists to use
      final list1 = await isarService.createMyDictionaryList('list1');
      for (int i = 0; i < 50; i++) {
        await isarService.addVocabToMyDictionaryList(list1, Vocab()..id = i);
      }

      // Create flashcard set and assign list
      final flashcardSet = await isarService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(list1.id);
      await isarService.updateFlashcardSet(flashcardSet);

      // Call initialize using normal mode
      var viewModel = FlashcardsViewModel(flashcardSet, FlashcardStartMode.skip,
          randomSeed: 123);
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
  });
}
