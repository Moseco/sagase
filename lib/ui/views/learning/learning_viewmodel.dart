import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class LearningViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _snackbarService = locator<SnackbarService>();

  List<FlashcardSet>? _flashcardSets;
  List<FlashcardSet>? get flashcardSets => _flashcardSets;

  @override
  Future<void> futureToRun() async {
    _flashcardSets = await _dictionaryService.getFlashcardSets();
  }

  Future<void> createFlashcardSet() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textField,
      title: 'Create flashcards',
      description: 'Name',
      mainButtonTitle: 'Create',
      barrierDismissible: true,
    );

    if (response?.data == null) return;
    final name = (response!.data as String).sanitizeName();
    if (name.isEmpty) return;

    final flashcardSet = await _dictionaryService.createFlashcardSet(name);
    if (_flashcardSets != null) {
      _flashcardSets!.insert(0, flashcardSet);
    }

    editFlashcardSet(flashcardSet);
  }

  void openFlashcardSet(FlashcardSet flashcardSet) {
    if (flashcardSet.myDictionaryLists.isEmpty &&
        flashcardSet.predefinedDictionaryLists.isEmpty) {
      _snackbarService.showSnackbar(
        message: 'Add lists to your flashcard set to open flashcards',
      );
      return;
    }

    _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(flashcardSet: flashcardSet),
    );
    // Move flashcard set to top of the list
    _flashcardSets!.remove(flashcardSet);
    _flashcardSets!.insert(0, flashcardSet);
    rebuildUi();
  }

  Future<void> selectFlashcardStartMode(FlashcardSet flashcardSet) async {
    if (!flashcardSet.usingSpacedRepetition) return;

    if (flashcardSet.myDictionaryLists.isEmpty &&
        flashcardSet.predefinedDictionaryLists.isEmpty) {
      _snackbarService.showSnackbar(
        message: 'Add lists to your flashcard set to open flashcards',
      );
      return;
    }

    final response = await _dialogService.showCustomDialog(
      variant: DialogType.flashcardStart,
      barrierDismissible: true,
    );

    if (response?.data == null) return;

    _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(
        flashcardSet: flashcardSet,
        startMode: response!.data,
      ),
    );
  }

  Future<void> editFlashcardSet(FlashcardSet flashcardSet) async {
    DateTime initialDateTime = flashcardSet.timestamp;
    final result = await _navigationService.navigateTo(
      Routes.flashcardSetSettingsView,
      arguments: FlashcardSetSettingsViewArguments(flashcardSet: flashcardSet),
    );
    // If receive true as result, the flashcard set was deleted
    if (result ?? false) {
      _flashcardSets!.remove(flashcardSet);
    } else if (initialDateTime != flashcardSet.timestamp) {
      // If timestamp was changed, move flashcard set to top of the list
      _flashcardSets!.remove(flashcardSet);
      _flashcardSets!.insert(0, flashcardSet);
    }
    rebuildUi();
  }

  void openFlashcardSetInfo(FlashcardSet flashcardSet) async {
    _navigationService.navigateTo(
      Routes.flashcardSetInfoView,
      arguments: FlashcardSetInfoViewArguments(flashcardSet: flashcardSet),
    );
  }
}
