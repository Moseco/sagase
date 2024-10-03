import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:in_app_review/in_app_review.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:security_scoped_resource/security_scoped_resource.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart'
    show nestedNavigationKey, currentChangelogVersion;
import 'package:app_links/app_links.dart';
import 'package:uri_to_file/uri_to_file.dart' as uri_to_file;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class HomeViewModel extends IndexTrackingViewModel {
  final _navigationService = locator<NavigationService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _snackbarService = locator<SnackbarService>();
  final _dialogService = locator<DialogService>();
  final _dictionaryService = locator<DictionaryService>();

  bool _showNavigationBar = true;
  bool get showNavigationBar => _showNavigationBar;

  bool get startOnLearningView =>
      _sharedPreferencesService.getStartOnLearningView();

  late StreamSubscription<String> _fileSubscription;

  HomeViewModel() {
    if (startOnLearningView) setIndex(2);
    _checkReviewRequest();
    _checkChangelog();
    _listenForFiles();
  }

  Future<void> _checkReviewRequest() async {
    // Only allow requests once
    if (_sharedPreferencesService.getReviewRequested()) return;

    final inAppReview = InAppReview.instance;
    int startCount = _sharedPreferencesService.getReviewStartCount() + 1;
    // Make sure the user has used the app for a week and opened the app more than 20 times
    if (startCount > 20 &&
        DateTime.now()
                .difference(_sharedPreferencesService.getReviewStartTimestamp())
                .inDays >
            7 &&
        await inAppReview.isAvailable()) {
      inAppReview.requestReview();
      _sharedPreferencesService.setReviewRequested();
    } else {
      _sharedPreferencesService.setReviewStartCount(startCount);
    }
  }

  void _checkChangelog() {
    int? versionShown = _sharedPreferencesService.getChangelogVersionShown();

    if (versionShown == null) {
      // New user, don't show changelog
      _sharedPreferencesService.setChangelogVersionShown();
    } else if (versionShown < currentChangelogVersion) {
      // Existing user, show changelog
      _sharedPreferencesService.setChangelogVersionShown();
      // Zero duration delay to avoid concurrent build/navigation issues
      Future.delayed(
        Duration.zero,
        _navigationService.navigateToChangelogView,
      );
    }
  }

  void _listenForFiles() async {
    _fileSubscription = AppLinks().stringLinkStream.listen(
      _handleFiles,
      onError: (_) {
        _snackbarService.showSnackbar(message: 'Failed to get import file');
      },
    );
  }

  Future<void> _handleFiles(String link) async {
    late File file;
    try {
      file = await uri_to_file.toFile(link);
    } catch (_) {
      _snackbarService.showSnackbar(message: 'Failed to get import file');
      return;
    }

    // Skip if file does not end with .sagase
    if (!file.path.endsWith('.sagase')) return;

    // If iOS, get permission, copy to cache, and release permission
    if (Platform.isIOS) {
      if (await SecurityScopedResource.instance
          .startAccessingSecurityScopedResource(file)) {
        final newFile = await file.copy(
          path.join(
            (await path_provider.getApplicationCacheDirectory()).path,
            'import.sagase',
          ),
        );
        await SecurityScopedResource.instance
            .stopAccessingSecurityScopedResource(file);
        file = newFile;
      }
    }

    // Determine type of sagase file
    late Map<String, dynamic> map;
    try {
      map = jsonDecode(await file.readAsString());
    } catch (_) {
      _snackbarService.showSnackbar(message: 'Import failed');
      return;
    }
    switch (map[SagaseDictionaryConstants.exportType]) {
      case SagaseDictionaryConstants.exportTypeMyList:
        // Show confirmation
        String name =
            (map[SagaseDictionaryConstants.exportMyListName] as String)
                .sanitizeName();
        final response = await _dialogService.showCustomDialog(
          variant: DialogType.confirmation,
          title: 'Import list?',
          description:
              'List to import: $name\nImporting a list will not overwrite existing lists, even those with the same name.',
          mainButtonTitle: 'Import',
          secondaryButtonTitle: 'Cancel',
          barrierDismissible: true,
        );

        if (response != null && response.confirmed) {
          // Show progress indicator dialog
          _dialogService.showCustomDialog(
            variant: DialogType.progressIndicator,
            title: 'Importing list',
            barrierDismissible: false,
          );

          final newList =
              await _dictionaryService.importMyDictionaryList(file.path);

          _dialogService.completeDialog(DialogResponse());

          if (newList != null) {
            _reloadHome();
            _navigationService.navigateTo(
              Routes.dictionaryListView,
              arguments: DictionaryListViewArguments(dictionaryList: newList),
            );
          } else {
            _snackbarService.showSnackbar(message: 'Import failed');
          }
        }
        break;
      case SagaseDictionaryConstants.exportTypeBackup:
        // Show confirmation
        final response = await _dialogService.showCustomDialog(
          variant: DialogType.confirmation,
          title: 'Import from backup?',
          description:
              'This will merge the current app data with the data from the backup file. Conflicting data will be overwritten by the backup data.',
          mainButtonTitle: 'Import',
          secondaryButtonTitle: 'Cancel',
          barrierDismissible: true,
        );

        if (response != null && response.confirmed) {
          // Show progress indicator dialog
          _dialogService.showCustomDialog(
            variant: DialogType.progressIndicator,
            title: 'Importing data',
            barrierDismissible: false,
          );

          bool result = await _dictionaryService.importUserData(file.path);

          _dialogService.completeDialog(DialogResponse());

          if (result) {
            _snackbarService.showSnackbar(message: 'Import successful');
            _reloadHome();
          } else {
            _snackbarService.showSnackbar(message: 'Import failed');
          }
        }
        break;
    }

    // Cleanup files
    uri_to_file.clearTemporaryFiles();
  }

  void _reloadHome() {
    _navigationService.popUntil((route) => route.isFirst);
    handleNavigation(currentIndex, preventDuplicates: false);
  }

  void handleNavigation(int index, {bool preventDuplicates = true}) {
    // Prevent navigation to the same screen
    if (index == currentIndex && preventDuplicates) {
      // If navigating to lists view, clear to base lists view
      if (index == 1) {
        _navigationService.popUntil(
          (route) => route.isFirst,
          id: nestedNavigationKey,
        );
      }
      return;
    }
    setIndex(index);
    switch (index) {
      case 0:
        _navigationService.clearStackAndShow(
          HomeViewRoutes.searchView,
          id: nestedNavigationKey,
        );
        break;
      case 1:
        _navigationService.clearStackAndShow(
          HomeViewRoutes.listsView,
          id: nestedNavigationKey,
        );
        break;
      case 2:
        _navigationService.clearStackAndShow(
          HomeViewRoutes.learningView,
          id: nestedNavigationKey,
        );
        break;
      case 3:
        _navigationService.clearStackAndShow(
          HomeViewRoutes.settingsView,
          id: nestedNavigationKey,
        );
        break;
    }
  }

  void setShowNavigationBar(bool value) {
    _showNavigationBar = value;
    notifyListeners();
  }

  void handleBackButton() {
    if (currentIndex != 0) handleNavigation(0);
  }

  @override
  void dispose() {
    _fileSubscription.cancel();
    super.dispose();
  }
}
