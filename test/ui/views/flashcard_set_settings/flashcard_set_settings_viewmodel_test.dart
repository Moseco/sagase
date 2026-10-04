import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/ui/views/flashcard_set_settings/flashcard_set_settings_viewmodel.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/common/flashcard_set_data.dart';
import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('FlashcardSetSettingsViewModelTest', () {
    late DictionaryService dictionaryService;

    setUp(() async {
      registerServices();
      dictionaryService = await getAndRegisterRealDictionaryService();
    });

    tearDown(() async {
      await dictionaryService.close();
      unregisterServices();
    });

    test('Space out due flashcards with started flashcards', () async {
      // Due flashcard
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
                  dictionaryItem: getVocab1(), frontType: FrontType.japanese)
              .copyWith(
                  interval: 1,
                  repetitions: 1,
                  dueDate: DateTime.now().toInt(),
                  totalAnswers: 1));
      // Started flashcard that has spaced repetition data without a due date
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
              dictionaryItem: getVocab2(), frontType: FrontType.japanese));

      // Create dictionary list to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab2());

      // Create flashcard set and assign list
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);
      when(dialogService.completeDialog(any)).thenReturn(null);

      final viewModel = FlashcardSetSettingsViewModel(flashcardSet);
      viewModel.handlePopupMenuButton(PopupMenuItemType.spaceOut);

      // Progress dialog should be closed
      await untilCalled(dialogService.completeDialog(any));
    });

    test('Space out due flashcards failed', () async {
      final mockDictionaryService =
          getAndRegisterDictionaryService(getFlashcardSetFlashcards: []);
      when(mockDictionaryService.spaceOutFlashcards(any))
          .thenThrow(Exception('Database error'));

      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);
      when(dialogService.completeDialog(any)).thenReturn(null);

      final snackbarService = getAndRegisterSnackbarService();
      when(snackbarService.showSnackbar(message: anyNamed('message')))
          .thenReturn(null);

      final viewModel =
          FlashcardSetSettingsViewModel(createDefaultFlashcardSet());
      viewModel.handlePopupMenuButton(PopupMenuItemType.spaceOut);

      // Progress dialog should be closed and the error shown
      await untilCalled(
          snackbarService.showSnackbar(message: anyNamed('message')));
      verify(dialogService.completeDialog(any));
      verify(snackbarService.showSnackbar(
        message: 'Failed to update flashcards',
      ));
    });

    test('Reset flashcard set', () async {
      // Started flashcard
      await dictionaryService.setSpacedRepetitionData(
          SpacedRepetitionData.initial(
              dictionaryItem: getVocab1(), frontType: FrontType.japanese));

      // Create dictionary list to use
      final dictionaryList =
          await dictionaryService.createMyDictionaryList('list1');
      await dictionaryService.addToMyDictionaryList(
          dictionaryList, getVocab1());

      // Create flashcard set and assign list
      final flashcardSet = await dictionaryService.createFlashcardSet('name');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await dictionaryService.updateFlashcardSet(flashcardSet);

      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);
      when(dialogService.completeDialog(any)).thenReturn(null);

      final viewModel = FlashcardSetSettingsViewModel(flashcardSet);
      viewModel.handlePopupMenuButton(PopupMenuItemType.reset);

      // Progress dialog should be closed after the reset finished
      await untilCalled(dialogService.completeDialog(any));
      final flashcards =
          await dictionaryService.getFlashcardSetFlashcards(flashcardSet);
      expect(flashcards[0].spacedRepetitionData, null);
    });

    test('Reset flashcard set failed', () async {
      final mockDictionaryService = getAndRegisterDictionaryService();
      when(mockDictionaryService.resetFlashcardSetSpacedRepetitionData(any))
          .thenAnswer((_) async => false);

      final dialogService =
          getAndRegisterDialogService(dialogResponseConfirmed: true);
      when(dialogService.completeDialog(any)).thenReturn(null);

      final snackbarService = getAndRegisterSnackbarService();
      when(snackbarService.showSnackbar(message: anyNamed('message')))
          .thenReturn(null);

      final viewModel =
          FlashcardSetSettingsViewModel(createDefaultFlashcardSet());
      viewModel.handlePopupMenuButton(PopupMenuItemType.reset);

      // Progress dialog should be closed and the error shown
      await untilCalled(
          snackbarService.showSnackbar(message: anyNamed('message')));
      verify(dialogService.completeDialog(any));
      verify(snackbarService.showSnackbar(
        message: 'Failed to reset flashcard set',
      ));
    });
  });
}
