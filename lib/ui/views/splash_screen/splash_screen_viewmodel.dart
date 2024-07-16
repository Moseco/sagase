import 'dart:io';

import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/download_service.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sagase/utils/constants.dart' as constants;

class SplashScreenViewModel extends FutureViewModel {
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _navigationService = locator<NavigationService>();
  final _dictionaryService = locator<DictionaryService>();
  final _digitalInkService = locator<DigitalInkService>();
  final _mecabService = locator<MecabService>();
  final _downloadService = locator<DownloadService>();

  SplashScreenStatus _status = SplashScreenStatus.waiting;
  SplashScreenStatus get status => _status;

  Future<dynamic>? onboardingNavigation;
  late final DictionaryStatus _dictionaryStatus;
  late final bool _mecabReady;

  double _downloadStatus = 0;
  double get downloadStatus => _downloadStatus;

  @override
  Future<void> futureToRun() async {
    await _dictionaryService.initialize();

    // Navigate to onboarding if needed and keep track of the future
    if (!_sharedPreferencesService.getOnboardingFinished()) {
      // Need zero duration wait to avoid initial build conflict
      await Future.delayed(Duration.zero);
      onboardingNavigation = _navigationService.navigateToOnboardingView();
    }

    // Get status of dictionary and mecab services
    _dictionaryStatus = await _dictionaryService.open(validate: !kDebugMode);
    _mecabReady = await _mecabService.initialize();

    // If something is wrong with the dictionary show error
    if (_dictionaryStatus == DictionaryStatus.invalid) {
      _status = SplashScreenStatus.databaseError;
      rebuildUi();
      return;
    }

    // If upgrading or migrating dictionary get permission from user first
    if (_dictionaryStatus == DictionaryStatus.outOfDate ||
        _dictionaryStatus == DictionaryStatus.migrationRequired ||
        _dictionaryStatus == DictionaryStatus.transferInterrupted) {
      _status = SplashScreenStatus.downloadRequest;
      rebuildUi();
      return;
    }

    // Download assets if needed
    if (_dictionaryStatus != DictionaryStatus.valid || !_mecabReady) {
      return startDownload();
    }

    // Continue with initialization
    return _initializeServices();
  }

  Future<void> startDownload() async {
    _status = SplashScreenStatus.downloadingAssets;
    _downloadStatus = 0;
    rebuildUi();

    if (!await _downloadService.hasSufficientFreeSpace()) {
      _status = SplashScreenStatus.downloadFreeSpaceError;
      rebuildUi();
      return;
    }
    late Future<bool> downloadResult;
    if (_dictionaryStatus != DictionaryStatus.valid && !_mecabReady) {
      downloadResult = _downloadService.downloadRequiredAssets();
    } else if (_dictionaryStatus != DictionaryStatus.valid) {
      downloadResult = _downloadService.downloadDictionary();
    } else {
      downloadResult = _downloadService.downloadMecab();
    }

    _downloadService.progressStream?.listen((event) {
      double newStatus = (event * 100).floorToDouble() / 100;
      if (newStatus != _downloadStatus) {
        _downloadStatus = newStatus;
        rebuildUi();
      }
    });

    if (!await downloadResult) {
      _status = SplashScreenStatus.downloadError;
      rebuildUi();
      return;
    }

    return _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize dictionary service
    if (_dictionaryStatus != DictionaryStatus.valid) {
      _status = _dictionaryStatus == DictionaryStatus.initialInstall
          ? SplashScreenStatus.importingDictionary
          : SplashScreenStatus.upgradingDictionary;
      rebuildUi();

      final importResult =
          await _dictionaryService.importDatabase(_dictionaryStatus);
      switch (importResult) {
        case ImportResult.success:
          // Service is ready to be used. Do nothing.
          break;
        case ImportResult.failed:
          _status = SplashScreenStatus.databaseError;
          rebuildUi();
          return;
        case ImportResult.transferFailed:
          _status = SplashScreenStatus.dictionaryUpgradeError;
          rebuildUi();
          return;
      }
    }

    // Initialize mecab service
    if (!_mecabReady) {
      _status = SplashScreenStatus.importingMecab;
      rebuildUi();
      if (await _mecabService.extractFiles()) await _mecabService.initialize();
    }

    // Wait for onboarding before initializing digital ink service (to avoid ui lag)
    if (onboardingNavigation != null) await onboardingNavigation;

    // Initialize digital ink service
    if (!await _digitalInkService.initialize()) {
      _status = SplashScreenStatus.downloadingDigitalInk;
      rebuildUi();
      // Don't keep user waiting a long time for model to download
      // The model will download in the background after 5 seconds if not finished
      await Future.any([
        _digitalInkService.downloadModel(),
        Future.delayed(const Duration(seconds: 5)),
      ]);
    }

    // Clean up cache files
    _cleanCache();

    // Finally, navigate to home
    _navigationService.replaceWith(Routes.homeView);
  }

  Future<void> _cleanCache() async {
    try {
      final dir =
          Directory((await path_provider.getApplicationCacheDirectory()).path);

      // Matches files ending in .sagase or related to initial setup
      final filesToDeleteRegExp = RegExp(
        r'(.+\.sagase$)|(^' +
            RegExp.escape(constants.requiredAssetsTar) +
            r'$)|(^' +
            RegExp.escape(constants.dictionaryZip) +
            r'$)|(^' +
            RegExp.escape(constants.mecabZip) +
            r'$)',
      );

      for (var entity in (await dir.list().toList())) {
        if (entity is Directory) {
          // Delete share_plus directory which temporarily stores files for sharing
          if (entity.path.endsWith('${Platform.pathSeparator}share_plus')) {
            entity.delete(recursive: true);
          }
        } else if (entity is File) {
          // Delete files that match the regex and are a day old
          if (filesToDeleteRegExp.hasMatch(entity.uri.pathSegments.last) &&
              DateTime.now().difference(await entity.lastModified()).inDays >
                  0) {
            entity.delete();
          }
        }
      }
    } catch (_) {}
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
