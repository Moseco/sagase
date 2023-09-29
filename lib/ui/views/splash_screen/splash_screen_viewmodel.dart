import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/download_service.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SplashScreenViewModel extends FutureViewModel {
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _navigationService = locator<NavigationService>();
  final _isarService = locator<IsarService>();
  final _digitalInkService = locator<DigitalInkService>();
  final _mecabService = locator<MecabService>();

  SplashScreenStatus _status = SplashScreenStatus.waiting;
  SplashScreenStatus get status => _status;

  double _downloadStatus = 0;
  double get downloadStatus => _downloadStatus;

  @override
  Future<void> futureToRun() async {
    await initialize();
  }

  Future<void> initialize() async {
    // Navigate to onboarding if needed and keep track of the future
    Future<dynamic>? onboardingNavigation;
    if (!_sharedPreferencesService.getOnboardingFinished()) {
      await Future.delayed(Duration.zero);
      onboardingNavigation = _navigationService.navigateToOnboardingView();
    }

    // Get status of isar and mecab services
    DictionaryStatus dictionaryStatus =
        await _isarService.initialize(validate: !kDebugMode);
    bool mecabReady = await _mecabService.initialize();

    // Download assets if needed
    if (dictionaryStatus != DictionaryStatus.valid || !mecabReady) {
      late Future<bool> downloadFuture;
      if (dictionaryStatus != DictionaryStatus.valid && !mecabReady) {
        downloadFuture = locator<DownloadService>().downloadRequiredAssets();
      } else if (dictionaryStatus != DictionaryStatus.valid) {
        downloadFuture = locator<DownloadService>().downloadBaseDictionary();
      } else {
        downloadFuture = locator<DownloadService>().downloadMecabDictionary();
      }

      _status = SplashScreenStatus.downloadingAssets;
      rebuildUi();

      locator<DownloadService>().progressStream?.listen((event) {
        double newStatus = (event * 100).floorToDouble() / 100;
        if (newStatus != _downloadStatus) {
          _downloadStatus = newStatus;
          rebuildUi();
        }
      });

      final result = await downloadFuture;

      if (!result) {
        _status = SplashScreenStatus.downloadError;
        rebuildUi();
        return;
      }
    }

    // Initialize isar service and skip validation if in debug mode
    if (dictionaryStatus != DictionaryStatus.valid) {
      _status = dictionaryStatus == DictionaryStatus.invalid
          ? SplashScreenStatus.importingDictionary
          : SplashScreenStatus.upgradingDictionary;
      rebuildUi();

      await _isarService.close();
      try {
        await IsarService.importDatabase(dictionaryStatus);
        final isarService = IsarService();
        await isarService.initialize();

        locator.removeRegistrationIfExists<IsarService>();
        locator.registerSingleton<IsarService>(isarService);
      } catch (_) {
        // Something went wrong importing database
        _status = SplashScreenStatus.databaseError;
        rebuildUi();
        return;
      }
    }

    // Initialize digital ink service
    if (!(await _digitalInkService.initialize())) {
      _status = SplashScreenStatus.downloadingDigitalInk;
      rebuildUi();
      // Don't keep user waiting a long time for model to download
      // The model will download in the background after 5 seconds if not finished
      await Future.any([
        _digitalInkService.downloadModel(),
        Future.delayed(const Duration(seconds: 5)),
      ]);
    }

    // Initialize mecab service;
    if (!mecabReady) {
      _status = SplashScreenStatus.importingMecab;
      rebuildUi();
      await _mecabService.extractFiles();
      await _mecabService.initialize();
    }

    if (onboardingNavigation != null) await onboardingNavigation;

    // Finally, navigate to home
    _navigationService.replaceWith(Routes.homeView);
  }

  void retryDownload() {
    _status = SplashScreenStatus.waiting;
    _downloadStatus = 0;
    rebuildUi();
    initialize();
  }
}

enum SplashScreenStatus {
  waiting,
  downloadingAssets,
  importingDictionary,
  downloadingDigitalInk,
  importingMecab,
  upgradingDictionary,
  downloadError,
  databaseError,
}
