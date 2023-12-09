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
  final _downloadService = locator<DownloadService>();

  SplashScreenStatus _status = SplashScreenStatus.waiting;
  SplashScreenStatus get status => _status;

  double _downloadStatus = 0;
  double get downloadStatus => _downloadStatus;

  DictionaryStatus? _dictionaryStatus;
  bool? _mecabReady;

  bool _downloadApproved = false;

  @override
  Future<void> futureToRun() async {
    await _initialize();
  }

  Future<void> _initialize() async {
    // Navigate to onboarding if needed and keep track of the future
    Future<dynamic>? onboardingNavigation;
    if (!_sharedPreferencesService.getOnboardingFinished()) {
      await Future.delayed(Duration.zero);
      onboardingNavigation = _navigationService.navigateToOnboardingView();
    }

    // Get status of isar and mecab services
    // Don't have to check again if retrying the download
    _dictionaryStatus ??= await _isarService.initialize(validate: !kDebugMode);
    _mecabReady ??= await _mecabService.initialize();

    // If upgrading dictionary make sure user has approved the download
    if (_dictionaryStatus == DictionaryStatus.outOfDate && !_downloadApproved) {
      _status = SplashScreenStatus.downloadRequest;
      rebuildUi();
      return;
    }

    // Download assets if needed
    if (_dictionaryStatus != DictionaryStatus.valid || !_mecabReady!) {
      if (!await _downloadService.hasSufficientFreeSpace()) {
        _status = SplashScreenStatus.downloadFreeSpaceError;
        rebuildUi();
        return;
      }
      late Future<bool> downloadResult;
      if (_dictionaryStatus != DictionaryStatus.valid && !_mecabReady!) {
        downloadResult = _downloadService.downloadRequiredAssets();
      } else if (_dictionaryStatus != DictionaryStatus.valid) {
        downloadResult = _downloadService.downloadBaseDictionary();
      } else {
        downloadResult = _downloadService.downloadMecabDictionary();
      }

      _status = SplashScreenStatus.downloadingAssets;
      rebuildUi();

      _downloadService.progressStream?.listen((event) {
        double newStatus = (event * 100).floorToDouble() / 100;
        if (newStatus != _downloadStatus) {
          _downloadStatus = newStatus;
          rebuildUi();
        }
      });

      if (!(await downloadResult)) {
        _status = SplashScreenStatus.downloadError;
        rebuildUi();
        return;
      }
    }

    // Initialize isar service
    if (_dictionaryStatus != DictionaryStatus.valid) {
      _status = _dictionaryStatus == DictionaryStatus.invalid
          ? SplashScreenStatus.importingDictionary
          : SplashScreenStatus.upgradingDictionary;
      rebuildUi();

      await _isarService.close();

      final importResult = await IsarService.importDatabase(_dictionaryStatus!);
      if (importResult == ImportResult.success) {
        final newIsarService = IsarService();
        final newDictionaryStatus = await newIsarService.initialize();

        if (newDictionaryStatus == DictionaryStatus.valid) {
          locator.removeRegistrationIfExists<IsarService>();
          locator.registerSingleton<IsarService>(newIsarService);
        } else {
          newIsarService.close();
          _status = SplashScreenStatus.databaseError;
          rebuildUi();
          return;
        }
      } else if (importResult == ImportResult.transferDataFailed) {
        _status = SplashScreenStatus.dictionaryUpgradeError;
        rebuildUi();
        return;
      } else {
        _status = SplashScreenStatus.databaseError;
        rebuildUi();
        return;
      }
    }

    // Initialize mecab service
    if (!_mecabReady!) {
      _status = SplashScreenStatus.importingMecab;
      rebuildUi();
      if (await _mecabService.extractFiles()) {
        await _mecabService.initialize();
      }
    }

    if (onboardingNavigation != null) await onboardingNavigation;

    // Initialize digital ink service (after onboarding to avoid jank)
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

    // Finally, navigate to home
    _navigationService.replaceWith(Routes.homeView);
  }

  void startDownload() {
    _downloadApproved = true;
    _status = SplashScreenStatus.waiting;
    _downloadStatus = 0;
    rebuildUi();
    _initialize();
  }
}

enum SplashScreenStatus {
  waiting,
  downloadingAssets,
  importingDictionary,
  importingMecab,
  downloadingDigitalInk,
  upgradingDictionary,
  downloadError,
  databaseError,
  downloadRequest,
  dictionaryUpgradeError,
  downloadFreeSpaceError,
}
