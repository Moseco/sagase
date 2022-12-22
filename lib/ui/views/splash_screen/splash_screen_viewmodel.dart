import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SplashScreenViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _digitalInkService = locator<DigitalInkService>();

  _Status _status = _Status.waiting;

  Future<void> initialize() async {
    IsarService? isarService;
    late DictionaryStatus status;
    if (kDebugMode) {
      // Debug mode, just open IsarService
      isarService = await IsarService.initialize();
    } else {
      // Not debug mode, validate and import database
      try {
        isarService = await IsarService.initialize();
        status = await isarService.validateDictionary();
      } catch (_) {
        // Something went wrong opening the database
        status = DictionaryStatus.invalid;
      }

      // If database is not valid, import new version
      if (status != DictionaryStatus.valid) {
        _status = status == DictionaryStatus.invalid
            ? _Status.importingDatabase
            : _Status.upgradingDatabase;
        notifyListeners();
        await isarService?.close();
        try {
          await IsarService.importDatabase();
          isarService = await IsarService.initialize();
        } catch (_) {
          // Something went wrong importing database
          _status = _Status.databaseError;
          notifyListeners();
          return;
        }
      }
    }

    // Initialize digital ink service
    if (!_digitalInkService.ready) {
      _status = _Status.downloadingModel;
      notifyListeners();
      // Don't keep user waiting a long time for model to download
      // The model will download in the background after 5 seconds if not finished
      await Future.any([
        _digitalInkService.downloadModel(),
        Future.delayed(const Duration(seconds: 5)),
      ]);
    }

    // Register instance with locator
    StackedLocator.instance.registerSingleton(isarService!);

    // Finally, navigate to home
    _navigationService.replaceWith(Routes.homeView);
  }

  String getStatusText() {
    switch (_status) {
      case _Status.waiting:
        return '';
      case _Status.importingDatabase:
        return 'Preparing dictionary';
      case _Status.upgradingDatabase:
        return 'Upgrading dictionary';
      case _Status.downloadingModel:
        return 'Preparing handwriting recognition';
      case _Status.databaseError:
        return 'Something is wrong with the dictionary';
    }
  }
}

enum _Status {
  waiting,
  importingDatabase,
  upgradingDatabase,
  downloadingModel,
  databaseError,
}
