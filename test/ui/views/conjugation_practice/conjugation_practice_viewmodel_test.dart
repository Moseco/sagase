import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:sagase/ui/views/conjugation_practice/conjugation_practice_viewmodel.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:stacked_services/stacked_services.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('ConjugationPracticeViewModelTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    test('Default selection', () {
      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);

      expect(
        viewModel.allItems.length,
        ConjugationPracticeViewModel.questionsPerSession,
      );
      expect(viewModel.activeItems.length, viewModel.allItems.length);
      for (final question in viewModel.allItems) {
        expect(
          constants.defaultConjugationPracticeWordTypes.contains(question.type),
          true,
        );
        expect(
          constants.defaultConjugationPracticeForms.contains(question.form),
          true,
        );
      }
    });

    test('Correct typed answer', () async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {ConjugationPracticeForm.past},
      );
      final dialogService = getAndRegisterDialogService();
      final navigationService = getAndRegisterNavigationService();

      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);
      expect(viewModel.allItems.length, 1);

      // Correct answer typed in romaji shows the answer
      await viewModel.submitAnswer('shinda');
      expect(viewModel.showingAnswer, true);
      expect(viewModel.answerCorrect, true);
      expect(viewModel.activeItems.length, 1);

      // Deleting a correct answer does not retry
      viewModel.retryAnswer();
      expect(viewModel.showingAnswer, true);

      // Submitting again moves on
      await viewModel.submitAnswer('');
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeItems.length, 0);

      // Session finished
      verify(dialogService.showCustomDialog(
        variant: DialogType.confirmation,
        title: 'Finished!',
        description: anyNamed('description'),
        mainButtonTitle: 'Restart',
        secondaryButtonTitle: 'Exit',
        barrierDismissible: false,
      )).called(1);
      verify(navigationService.back()).called(1);
    });

    test('Wrong typed answer', () async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {
          ConjugationPracticeForm.past,
          ConjugationPracticeForm.negative,
        },
      );

      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);
      expect(viewModel.allItems.length, 2);

      final current = viewModel.activeItems[0];
      await viewModel.submitAnswer('shinu');
      expect(viewModel.showingAnswer, true);
      expect(viewModel.answerCorrect, false);
      expect(viewModel.activeItems[0], current);

      // Submitting again moves on and keeps the question in the deck
      await viewModel.submitAnswer('');
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeItems.length, 2);
      expect(viewModel.activeItems.last, current);
    });

    test('Retry wrong typed answer', () async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {
          ConjugationPracticeForm.past,
          ConjugationPracticeForm.negative,
        },
      );

      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);
      final current = viewModel.activeItems[0];
      final other = viewModel.activeItems[1];

      await viewModel.submitAnswer('shinu');
      expect(viewModel.showingAnswer, true);

      // Retrying hides the answer without counting it as wrong
      viewModel.retryAnswer();
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeItems, [current, other]);
      expect(viewModel.canUndo, false);

      // The same question can be answered correctly
      await viewModel.submitAnswer(current.readingAnswer);
      expect(viewModel.showingAnswer, true);
      expect(viewModel.answerCorrect, true);
      await viewModel.submitAnswer('');
      expect(viewModel.showingAnswer, false);
      expect(viewModel.activeItems, [other]);
    });

    test('Answers accept kana, kanji and trailing n', () async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {ConjugationPracticeForm.politeNegative},
      );
      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);
      final question = viewModel.activeItems[0];

      expect(viewModel.isCorrectAnswer(question, 'しにません'), true);
      expect(viewModel.isCorrectAnswer(question, '死にません'), true);
      expect(viewModel.isCorrectAnswer(question, 'shinimasen'), true);
      expect(viewModel.isCorrectAnswer(question, 'しにませn'), true);
      expect(viewModel.isCorrectAnswer(question, 'SHINIMASEN'), true);
      expect(viewModel.isCorrectAnswer(question, 'しにます'), false);
    });

    test('Edit selection', () async {
      final sharedPreferencesService = getAndRegisterSharedPreferencesService();
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.conjugationPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer(
        (_) async => DialogResponse(
          data: (
            {ConjugationPracticeWordType.adjectiveNa},
            {ConjugationPracticeForm.polite},
          ),
        ),
      );

      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);
      expect(await viewModel.editSelection(), true);

      expect(
        viewModel.allItems.length,
        ConjugationPracticeWordType.adjectiveNa.words.length,
      );
      for (final question in viewModel.allItems) {
        expect(question.type, ConjugationPracticeWordType.adjectiveNa);
        expect(question.form, ConjugationPracticeForm.polite);
      }
      verify(sharedPreferencesService.setConjugationPracticeWordTypes(
        {ConjugationPracticeWordType.adjectiveNa},
      )).called(1);
      verify(sharedPreferencesService.setConjugationPracticeForms(
        {ConjugationPracticeForm.polite},
      )).called(1);
    });

    test('Edit selection cancelled', () async {
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.conjugationPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer((_) async => null);

      final viewModel = ConjugationPracticeViewModel(randomSeed: 123);
      final items = viewModel.allItems;
      expect(await viewModel.editSelection(), false);
      expect(viewModel.allItems, items);
    });
  });
}
