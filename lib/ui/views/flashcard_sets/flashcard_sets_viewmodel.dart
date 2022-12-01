import 'package:sagase/app/app.dialog.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  List<FlashcardSet>? _flashcardSets;
  List<FlashcardSet>? get flashcardSets => _flashcardSets;

  FlashcardSetsViewModel() {
    _loadFlashcardSets();
  }

  Future<void> _loadFlashcardSets() async {
    _flashcardSets = await _isarService.getFlashcardSets();
    notifyListeners();
  }

  Future<void> createFlashcardSet() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textFieldDialog,
      title: 'Create flashcards',
      description: 'Name',
      mainButtonTitle: 'Create',
      barrierDismissible: true,
    );

    String? name = response?.data?.trim();
    if (name == null || name.isEmpty) return;

    final flashcardSet = await _isarService.createFlashcardSet(name);
    if (_flashcardSets != null) {
      _flashcardSets!.insert(0, flashcardSet);
      notifyListeners();
    }

    editFlashcardSet(flashcardSet);
  }

  Future<void> openFlashcardSet(FlashcardSet flashcardSet) async {
    _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(flashcardSet: flashcardSet),
    );
  }

  Future<void> editFlashcardSet(FlashcardSet flashcardSet) async {
    final result = await _navigationService.navigateTo(
      Routes.flashcardSetInfoView,
      arguments: FlashcardSetInfoViewArguments(flashcardSet: flashcardSet),
    );
    // If receive true as result, the flashcard set was deleted
    if (result ?? false) _flashcardSets!.remove(flashcardSet);
    notifyListeners();
  }
}
