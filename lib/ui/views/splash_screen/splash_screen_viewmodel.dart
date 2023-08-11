import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/digital_ink_service.dart';
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

    // Initialize isar service and skip validation if in debug mode
    DictionaryStatus status =
        await _isarService.initialize(validate: !kDebugMode);
    if (status != DictionaryStatus.valid) {
      _status = status == DictionaryStatus.invalid
          ? SplashScreenStatus.importingDictionary
          : SplashScreenStatus.upgradingDictionary;
      rebuildUi();

      await _isarService.close();
      try {
        await IsarService.importDatabase(status);
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
    if (!(await _mecabService.initialize())) {
      _status = SplashScreenStatus.importingMecab;
      rebuildUi();
      await _mecabService.extractFiles();
      await _mecabService.initialize();
    }

    if (onboardingNavigation != null) await onboardingNavigation;

    // Finally, navigate to home
    _navigationService.replaceWith(Routes.homeView);
  }
}

enum SplashScreenStatus {
  waiting,
  importingDictionary,
  downloadingDigitalInk,
  importingMecab,
  upgradingDictionary,
  databaseError,
}
