import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase/ui/themes.dart';
import 'package:sagase/ui/views/search/search_viewmodel.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_themes/stacked_themes.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _snackbarService = locator<SnackbarService>();
  final _isarService = locator<IsarService>();
  final _themeService = locator<ThemeService>();

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
      variant: DialogType.initialInterval,
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
      variant: DialogType.numberTextField,
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
      variant: DialogType.numberTextField,
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
      variant: DialogType.numberTextField,
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

  Future<void> deleteSearchHistory() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Delete search history?',
      mainButtonTitle: 'Delete',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      _isarService.deleteSearchHistory();
      locator<SearchViewModel>().clearSearchHistory();
    }
  }

  Future<void> backupData() async {
    // Show progress indicator dialog
    _dialogService.showCustomDialog(
      variant: DialogType.progressIndicator,
      title: 'Exporting data',
      barrierDismissible: false,
    );

    String path = await _isarService.exportUserData();

    _dialogService.completeDialog(DialogResponse());

    // Ask user to save file to a location
    String? newPath;
    try {
      newPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(sourceFilePath: path),
      );
    } catch (_) {
      newPath = null;
    }

    if (newPath == null) {
      _snackbarService.showSnackbar(message: 'Failed to save file');
    }

    // Delete the original file
    await File(path).delete();
  }

  Future<void> importData() async {
    // Ask user for the file they want to import
    String? filePath;
    try {
      filePath = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(fileExtensionsFilter: ['sagase']),
      );
    } catch (_) {
      filePath = null;
    }

    if (filePath != null) {
      // Show progress indicator dialog
      _dialogService.showCustomDialog(
        variant: DialogType.progressIndicator,
        title: 'Importing data',
        barrierDismissible: false,
      );

      bool result = await _isarService.importUserData(filePath);

      _dialogService.completeDialog(DialogResponse());

      if (result) {
        _snackbarService.showSnackbar(message: 'Import successful');
      } else {
        _snackbarService.showSnackbar(message: 'Import failed');
      }
    } else {
      _snackbarService.showSnackbar(message: 'Import cancelled');
    }
  }

  Future<void> setJapaneseFont() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.fontSelection,
      data: _sharedPreferencesService.getUseJapaneseSerifFont(),
      barrierDismissible: true,
    );

    if (response?.data != null) {
      _sharedPreferencesService.setUseJapaneseSerifFont(response!.data);

      _themeService.setThemes(
        lightTheme: getLightTheme(response.data),
        darkTheme: getDarkTheme(response.data),
      );
    }
  }

  Future<void> setAppTheme() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.themeSelection,
      data: _themeService.selectedThemeMode,
      barrierDismissible: true,
    );

    if (response?.data != null) {
      _themeService.setThemeMode(response!.data);
    }
  }

  Future<void> openFeedback() async {
    try {
      if (!await launchUrl(
        Uri.parse(
            r'https://docs.google.com/forms/d/e/1FAIpQLSeXqXf_b4Xvi_t5JuhpwTYsYmVLnQ9AwV7aIHwvvFFT25j42Q/viewform?usp=sf_link'),
      )) {
        _snackbarService.showSnackbar(message: 'Failed to open form');
      }
    } catch (_) {
      _snackbarService.showSnackbar(message: 'Failed to open form');
    }
  }
}
