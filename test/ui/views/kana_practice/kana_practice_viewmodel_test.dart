import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/ui/views/kana_practice/kana_practice_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('KanaPracticeViewModelTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    test('Default selection', () async {
      final viewModel = KanaPracticeViewModel(randomSeed: 123);

      // Hiragana basic
      expect(viewModel.allFlashcards.length, 46);
      expect(viewModel.activeFlashcards.length, 46);
      expect(viewModel.canUndo, false);
      for (final kana in viewModel.allFlashcards) {
        expect(kana.script, KanaScript.hiragana);
        expect(kana.type, KanaType.basic);
      }
    });

    test('Wrong answers repeat', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final navigationService = getAndRegisterNavigationService();

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.allFlashcards.length, 5);
      expect(viewModel.activeFlashcards.length, 5);

      // Wrong
      var tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(KanaPracticeAnswer.wrong);
      expect(tempFlashcard, viewModel.activeFlashcards.last);
      expect(viewModel.activeFlashcards.length, 5);

      // Correct
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.activeFlashcards.contains(tempFlashcard), false);
      expect(viewModel.activeFlashcards.length, 4);

      // Finish the rest except for the last one
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.activeFlashcards.length, 1);

      // Wrong with only one flashcard left
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(KanaPracticeAnswer.wrong);
      expect(viewModel.activeFlashcards, [tempFlashcard]);
      verifyNever(navigationService.back());

      // Back should now be called because exit dialog was accepted
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.activeFlashcards.length, 0);
      verify(navigationService.back());
    });

    test('Wrong answers repeat at flashcard distance', () async {
      getAndRegisterSharedPreferencesService(
        getFlashcardDistance: 3,
        getKanaPracticeTypes: {KanaType.voiced},
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.activeFlashcards.length, 20);

      final tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.answerFlashcard(KanaPracticeAnswer.wrong);
      expect(viewModel.activeFlashcards[2], tempFlashcard);
      expect(viewModel.activeFlashcards.length, 20);

      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.activeFlashcards[0], tempFlashcard);
      expect(viewModel.activeFlashcards.length, 18);
    });

    test('Restart', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeScripts: {KanaScript.katakana},
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDialogService(dialogResponseConfirmed: true);

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.activeFlashcards.length, 5);

      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);

      // Back should not have been called because restart dialog was accepted
      verifyNever(navigationService.back());
      expect(viewModel.allFlashcards.length, 5);
      expect(viewModel.activeFlashcards.length, 5);
      expect(viewModel.canUndo, false);
    });

    test('Undo', () async {
      getAndRegisterSharedPreferencesService(
        getFlashcardDistance: 4,
        getKanaPracticeTypes: {KanaType.voiced},
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      final initialFlashcards = List.of(viewModel.activeFlashcards);

      // Undo should do nothing with no answers
      viewModel.undo();
      expect(viewModel.activeFlashcards, initialFlashcards);

      // Answer the first flashcard wrong then correct when it reappears
      await viewModel.answerFlashcard(KanaPracticeAnswer.wrong);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.activeFlashcards[0], initialFlashcards[0]);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.activeFlashcards.length, 16);

      // Undo everything
      for (int i = 0; i < 5; i++) {
        expect(viewModel.canUndo, true);
        viewModel.undo();
      }
      expect(viewModel.canUndo, false);
      expect(viewModel.activeFlashcards, initialFlashcards);

      // Undo is limited to 10 answers
      for (int i = 0; i < 12; i++) {
        await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      }
      expect(viewModel.activeFlashcards.length, 8);
      for (int i = 0; i < 10; i++) {
        expect(viewModel.canUndo, true);
        viewModel.undo();
      }
      expect(viewModel.canUndo, false);
      expect(viewModel.activeFlashcards.length, 18);
    });

    test('Submit answer', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.showingAnswer, false);

      // Wrong answer should show the answer without moving on
      var tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.submitAnswer('ka');
      expect(viewModel.showingAnswer, true);
      expect(viewModel.activeFlashcards[0], tempFlashcard);
      expect(viewModel.activeFlashcards.length, 5);

      // Submitting again moves on and repeats the flashcard
      await viewModel.submitAnswer(tempFlashcard.romaji);
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeFlashcards.last, tempFlashcard);
      expect(viewModel.activeFlashcards.length, 5);

      // Correct answer moves on right away
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.submitAnswer(tempFlashcard.romaji);
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeFlashcards.contains(tempFlashcard), false);
      expect(viewModel.activeFlashcards.length, 4);

      // Capitalization and surrounding whitespace is ignored
      tempFlashcard = viewModel.activeFlashcards[0];
      await viewModel.submitAnswer(' ${tempFlashcard.romaji.toUpperCase()} ');
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeFlashcards.length, 3);

      // Empty answer is wrong
      await viewModel.submitAnswer('');
      expect(viewModel.showingAnswer, true);
      expect(viewModel.activeFlashcards.length, 3);
    });

    test('Submit answer with other romanizations', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeScripts: {KanaScript.hiragana, KanaScript.katakana},
        getKanaPracticeTypes: {KanaType.basic, KanaType.combination},
      );
      final navigationService = getAndRegisterNavigationService();

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.activeFlashcards.length, 158);

      const otherRomanizations = {
        'shi': 'si',
        'chi': 'ti',
        'tsu': 'tu',
        'fu': 'hu',
        'o': 'wo',
        'sha': 'sya',
        'chu': 'tyu',
        'ja': 'zya',
        'jo': 'jyo',
      };

      for (int i = 157; i >= 0; i--) {
        final romaji = viewModel.activeFlashcards[0].romaji;
        // お and を are both o but only を can be wo
        final answer = viewModel.activeFlashcards[0].kana == 'お' ||
                viewModel.activeFlashcards[0].kana == 'オ'
            ? romaji
            : otherRomanizations[romaji] ?? romaji;
        await viewModel.submitAnswer(answer);
        expect(viewModel.showingAnswer, false);
        expect(viewModel.activeFlashcards.length, i);
      }

      verify(navigationService.back());
    });

    test('Submit answer with romanization for a different kana', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.voiced},
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);

      // Answer correctly until ぢ which is di or ji but not zi
      while (viewModel.activeFlashcards[0].kana != 'ぢ') {
        await viewModel.submitAnswer(viewModel.activeFlashcards[0].romaji);
      }
      final remaining = viewModel.activeFlashcards.length;

      await viewModel.submitAnswer('zi');
      expect(viewModel.showingAnswer, true);
      await viewModel.submitAnswer('');
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeFlashcards.length, remaining);
    });

    test('Toggle typing', () async {
      final sharedPreferencesService = getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.typingEnabled, false);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.canUndo, true);

      // Enabling should not affect flashcards but undo is no longer available
      viewModel.toggleTypingEnabled();
      expect(viewModel.typingEnabled, true);
      expect(viewModel.canUndo, false);
      expect(viewModel.activeFlashcards.length, 4);
      verify(sharedPreferencesService.setKanaPracticeTypingEnabled(true))
          .called(1);

      // Disabling while showing answer should hide it
      await viewModel.submitAnswer('ka');
      expect(viewModel.showingAnswer, true);
      viewModel.toggleTypingEnabled();
      expect(viewModel.typingEnabled, false);
      expect(viewModel.showingAnswer, false);
      expect(viewModel.canUndo, false);
      expect(viewModel.activeFlashcards.length, 4);
      verify(sharedPreferencesService.setKanaPracticeTypingEnabled(false))
          .called(1);
    });

    test('Typing enabled from shared preferences', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypingEnabled: true,
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.typingEnabled, true);
    });

    test('Edit selection', () async {
      final sharedPreferencesService = getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.kanaPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer(
        (_) async => DialogResponse(
          data: (
            {KanaScript.hiragana, KanaScript.katakana},
            {KanaType.voiced, KanaType.semiVoiced},
          ),
        ),
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      expect(viewModel.activeFlashcards.length, 5);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);
      expect(viewModel.canUndo, true);

      expect(await viewModel.editSelection(), true);

      // Session should be restarted with the new selection
      expect(viewModel.allFlashcards.length, 50);
      expect(viewModel.activeFlashcards.length, 50);
      expect(viewModel.canUndo, false);
      verify(sharedPreferencesService.setKanaPracticeScripts(
        {KanaScript.hiragana, KanaScript.katakana},
      )).called(1);
      verify(sharedPreferencesService.setKanaPracticeTypes(
        {KanaType.voiced, KanaType.semiVoiced},
      )).called(1);
    });

    test('Edit selection cancelled', () async {
      final sharedPreferencesService = getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);

      // Default dialog response has no data
      expect(await viewModel.editSelection(), false);

      expect(viewModel.allFlashcards.length, 5);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.canUndo, true);
      verifyNever(sharedPreferencesService.setKanaPracticeScripts(any));
      verifyNever(sharedPreferencesService.setKanaPracticeTypes(any));
    });

    test('Edit selection passes current selection to dialog', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeScripts: {KanaScript.hiragana},
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.kanaPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer(
        (_) async => DialogResponse(
          data: ({KanaScript.katakana}, {KanaType.voiced}),
        ),
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      await viewModel.editSelection();
      await viewModel.editSelection();

      final captured = verify(dialogService.showCustomDialog(
        variant: DialogType.kanaPracticeSelection,
        data: captureAnyNamed('data'),
        barrierDismissible: true,
      )).captured;
      expect(captured.length, 2);

      // First from shared preferences, then the previously chosen selection
      final (Set<KanaScript> scripts1, Set<KanaType> types1) = captured[0];
      expect(scripts1, {KanaScript.hiragana});
      expect(types1, {KanaType.semiVoiced});
      final (Set<KanaScript> scripts2, Set<KanaType> types2) = captured[1];
      expect(scripts2, {KanaScript.katakana});
      expect(types2, {KanaType.voiced});
    });

    test('Edit selection with nothing selected is ignored', () async {
      final sharedPreferencesService = getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.kanaPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer(
        (_) async => DialogResponse(
          data: (<KanaScript>{}, {KanaType.voiced}),
        ),
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      await viewModel.answerFlashcard(KanaPracticeAnswer.correct);

      expect(await viewModel.editSelection(), false);

      expect(viewModel.allFlashcards.length, 5);
      expect(viewModel.activeFlashcards.length, 4);
      expect(viewModel.canUndo, true);
      verifyNever(sharedPreferencesService.setKanaPracticeScripts(any));
      verifyNever(sharedPreferencesService.setKanaPracticeTypes(any));
    });

    test('Edit selection while showing answer', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
        getKanaPracticeTypingEnabled: true,
      );
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.kanaPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer(
        (_) async => DialogResponse(
          data: ({KanaScript.katakana}, {KanaType.semiVoiced}),
        ),
      );

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      await viewModel.submitAnswer('ka');
      expect(viewModel.showingAnswer, true);

      expect(await viewModel.editSelection(), true);

      // New session should start on a new flashcard without the answer shown
      expect(viewModel.showingAnswer, false);
      expect(viewModel.typingEnabled, true);
      expect(viewModel.activeFlashcards.length, 5);
      for (final kana in viewModel.activeFlashcards) {
        expect(kana.script, KanaScript.katakana);
      }
    });

    test('Submit answer on the last flashcard', () async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
        getKanaPracticeTypingEnabled: true,
      );
      final navigationService = getAndRegisterNavigationService();
      final dialogService = getAndRegisterDialogService();

      final viewModel = KanaPracticeViewModel(randomSeed: 123);
      for (int i = 0; i < 4; i++) {
        await viewModel.submitAnswer(viewModel.activeFlashcards[0].romaji);
      }
      expect(viewModel.activeFlashcards.length, 1);
      final lastFlashcard = viewModel.activeFlashcards[0];

      // Wrong answer on the last flashcard should repeat it and not finish
      await viewModel.submitAnswer('ka');
      expect(viewModel.showingAnswer, true);
      await viewModel.submitAnswer('');
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeFlashcards, [lastFlashcard]);
      verifyNever(dialogService.showCustomDialog(
        variant: DialogType.confirmation,
        title: anyNamed('title'),
        description: anyNamed('description'),
        mainButtonTitle: anyNamed('mainButtonTitle'),
        secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
        barrierDismissible: anyNamed('barrierDismissible'),
      ));

      // Correct answer finishes and exits because restart was not confirmed
      await viewModel.submitAnswer(lastFlashcard.romaji);
      expect(viewModel.activeFlashcards, isEmpty);
      verify(dialogService.showCustomDialog(
        variant: DialogType.confirmation,
        title: anyNamed('title'),
        description: anyNamed('description'),
        mainButtonTitle: anyNamed('mainButtonTitle'),
        secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
        barrierDismissible: anyNamed('barrierDismissible'),
      )).called(1);
      verify(navigationService.back()).called(1);
    });
  });
}
