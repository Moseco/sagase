import 'package:sagase/app/app.dialog.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class LearningViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _isarService = locator<IsarService>();
  final _dialogService = locator<DialogService>();

  FlashcardSet? _recentFlashcardSet;
  FlashcardSet? get recentFlashcardSet => _recentFlashcardSet;

  LearningViewModel() {
    _loadRecentFlashcardSet();
  }

  Future<void> _loadRecentFlashcardSet() async {
    _recentFlashcardSet = await _isarService.getRecentFlashcardSet();
    notifyListeners();
  }

  Future<void> navigateToFlashcardSets() async {
    await _navigationService.navigateTo(Routes.flashcardSetsView);
    // Reload recent flashcard set
    _recentFlashcardSet = null;
    _loadRecentFlashcardSet();
  }

  void openRecentFlashcardSet() {
    if (recentFlashcardSet == null) return;

    _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(flashcardSet: recentFlashcardSet!),
    );
  }

  Future<void> selectFlashcardStartMode() async {
    if (recentFlashcardSet == null ||
        !recentFlashcardSet!.usingSpacedRepetition) return;

    final response = await _dialogService.showCustomDialog(
      variant: DialogType.flashcardStartDialog,
      barrierDismissible: true,
    );

    if (response?.data == null) return;

    _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(
        flashcardSet: recentFlashcardSet!,
        startMode: response!.data,
      ),
    );
  }

  Future<void> editRecentFlashcardSet() async {
    if (recentFlashcardSet == null) return;

    final result = await _navigationService.navigateTo(
      Routes.flashcardSetSettingsView,
      arguments:
          FlashcardSetSettingsViewArguments(flashcardSet: recentFlashcardSet!),
    );
    // If receive true as result, the flashcard set was deleted
    if (result ?? false) {
      _recentFlashcardSet = null;
      notifyListeners();
    }
  }

  void openRecentFlashcardSetInfo() async {
    if (recentFlashcardSet == null) return;

    _navigationService.navigateTo(
      Routes.flashcardSetInfoView,
      arguments:
          FlashcardSetInfoViewArguments(flashcardSet: recentFlashcardSet!),
    );
  }
}
