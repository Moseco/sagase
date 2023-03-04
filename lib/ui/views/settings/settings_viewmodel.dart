import 'package:sagase/app/app.dialog.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class SettingsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _snackbarService = locator<SnackbarService>();

  bool get showNewInterval => _sharedPreferencesService.getShowNewInterval();
  bool get flashcardLearningModeEnabled =>
      _sharedPreferencesService.getFlashcardLearningModeEnabled();
  int get newFlashcardsPerDay =>
      _sharedPreferencesService.getNewFlashcardsPerDay();
  int get flashcardDistance => _sharedPreferencesService.getFlashcardDistance();
  int get flashcardCorrectAnswersRequired =>
      _sharedPreferencesService.getFlashcardCorrectAnswersRequired();

  void navigateToDev() {
    _navigationService.navigateTo(Routes.devView);
  }

  void setInitialCorrectInterval(int value) {
    _sharedPreferencesService.setInitialCorrectInterval(value);
    notifyListeners();
  }

  Future<void> setInitialSpacedRepetitionInterval() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.initialIntervalDialog,
      barrierDismissible: true,
      data: [
        _sharedPreferencesService.getInitialCorrectInterval().toString(),
        _sharedPreferencesService.getInitialVeryCorrectInterval().toString(),
      ],
    );

    if (response?.data == null) return;

    _sharedPreferencesService.setInitialCorrectInterval(response!.data![0]);
    _sharedPreferencesService.setInitialVeryCorrectInterval(response.data![1]);
  }

  void setShowNewInterval(bool value) {
    _sharedPreferencesService.setShowNewInterval(value);
    notifyListeners();
  }

  void setFlashcardLearningModeEnabled(bool value) {
    _sharedPreferencesService.setFlashcardLearningModeEnabled(value);
    notifyListeners();
  }

  Future<void> setNewFlashcardsPerDay() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.numberTextFieldDialog,
      title: 'New Flashcards Per Day',
      description: 'Amount',
      mainButtonTitle: 'Set',
      data: newFlashcardsPerDay.toString(),
      barrierDismissible: true,
    );

    String? data = response?.data?.trim();
    if (data == null || data.isEmpty) return;

    try {
      int amount = int.parse(data);
      if (amount <= 0) {
        _snackbarService.showSnackbar(message: 'Must be greater than 0');
        return;
      }
      _sharedPreferencesService.setNewFlashcardsPerDay(amount);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setFlashcardDistance() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.numberTextFieldDialog,
      title: 'Flashcard Distance',
      description: 'Amount',
      mainButtonTitle: 'Set',
      data: flashcardDistance.toString(),
      barrierDismissible: true,
    );

    String? data = response?.data?.trim();
    if (data == null || data.isEmpty) return;

    try {
      int amount = int.parse(data);
      if (amount <= 0) {
        _snackbarService.showSnackbar(message: 'Must be greater than 0');
        return;
      }
      _sharedPreferencesService.setFlashcardDistance(amount);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setFlashcardCorrectAnswersRequired() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.numberTextFieldDialog,
      title: 'Correct Answers Required',
      description: 'Amount',
      mainButtonTitle: 'Set',
      data: flashcardCorrectAnswersRequired.toString(),
      barrierDismissible: true,
    );

    String? data = response?.data?.trim();
    if (data == null || data.isEmpty) return;

    try {
      int amount = int.parse(data);
      if (amount <= 0) {
        _snackbarService.showSnackbar(message: 'Must be greater than 0');
        return;
      }
      _sharedPreferencesService.setFlashcardCorrectAnswersRequired(amount);
      notifyListeners();
    } catch (_) {}
  }
}
