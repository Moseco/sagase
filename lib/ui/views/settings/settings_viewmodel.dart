import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/firebase_service.dart';
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
  final _firebaseService = locator<FirebaseService>();

  bool get showNewInterval => _sharedPreferencesService.getShowNewInterval();
  bool get flashcardLearningModeEnabled =>
      _sharedPreferencesService.getFlashcardLearningModeEnabled();
  int get newFlashcardsPerDay =>
      _sharedPreferencesService.getNewFlashcardsPerDay();
  int get flashcardDistance => _sharedPreferencesService.getFlashcardDistance();
  int get flashcardCorrectAnswersRequired =>
      _sharedPreferencesService.getFlashcardCorrectAnswersRequired();
  bool get analyticsEnabled => _sharedPreferencesService.getAnalyticsEnabled();
  bool get crashlyticsEnabled => _firebaseService.crashlyticsEnabled;
  bool get startOnLearningView =>
      _sharedPreferencesService.getStartOnLearningView();
  bool get showPitchAccent => _sharedPreferencesService.getShowPitchAccent();
  bool get showDetailedProgress =>
      _sharedPreferencesService.getShowDetailedProgress();

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
        _snackbarService.showSnackbar(message: 'Amount must be greater than 0');
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
        _snackbarService.showSnackbar(message: 'Amount must be greater than 0');
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
        _snackbarService.showSnackbar(message: 'Amount must be greater than 0');
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

    String? path = await _isarService.exportUserData();

    _dialogService.completeDialog(DialogResponse());

    if (path == null) {
      _snackbarService.showSnackbar(message: 'Failed to export data');
      return;
    }

    // Ask user to save file to a location
    String? newPath;
    try {
      newPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(sourceFilePath: path),
      );
    } catch (_) {
      newPath = null;
    }

    _snackbarService.showSnackbar(
      message: newPath == null ? 'Failed to save file' : 'Export successful',
    );

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

  void navigateToAbout() {
    _navigationService.navigateTo(Routes.aboutView);
  }

  void setAnalyticsEnabled(bool value) {
    _firebaseService.setAnalyticsEnabled(value);
    _sharedPreferencesService.setAnalyticsEnabled(value);
    notifyListeners();
  }

  void setCrashlyticsEnabled(bool value) {
    _firebaseService.setCrashlyticsEnabled(value);
    notifyListeners();
  }

  void setStartOnLearningView(bool value) {
    _sharedPreferencesService.setStartOnLearningView(value);
    notifyListeners();
  }

  void setShowPitchAccent(bool value) {
    _sharedPreferencesService.setShowPitchAccent(value);
    notifyListeners();
  }

  void setShowDetailedProgress(bool value) {
    _sharedPreferencesService.setShowDetailedProgress(value);
    notifyListeners();
  }

  Future<void> requestDataDeletion() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Request data deletion',
      description:
          'If enabled, this app collects analytics relating to app usage and crash reports. You can request to have all your analytics related data deleted. If you choose to, your unique ID will be copied to your clipboard which you need to submit in the form that will be opened in a browser.',
      mainButtonTitle: 'Open',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      final id = await _firebaseService.getAppInstanceId();
      if (id == null) {
        _snackbarService.showSnackbar(message: 'Failed to get ID');
      } else {
        Clipboard.setData(ClipboardData(text: id));
        try {
          if (!await launchUrl(
            Uri.parse(
                r'https://docs.google.com/forms/d/e/1FAIpQLSdZ2wEkhsVNjFcHh7XpJjdETF9JFPxfn16x_KHCiFWhrbsrmg/viewform?usp=sf_link'),
          )) {
            _snackbarService.showSnackbar(message: 'Failed to open form');
          }
        } catch (_) {
          _snackbarService.showSnackbar(message: 'Failed to open form');
        }
      }
    }
  }

  Future<void> openPrivacyPolicy() async {
    try {
      if (!await launchUrl(
        Uri.parse(r'https://hammarlund.dev/sagase/privacy'),
      )) {
        _snackbarService.showSnackbar(message: 'Failed to open privacy policy');
      }
    } catch (_) {
      _snackbarService.showSnackbar(message: 'Failed to open privacy policy');
    }
  }
}
