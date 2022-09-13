import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class SplashScreenViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  bool _importingDictionary = false;
  bool get importingDictionary => _importingDictionary;

  bool _importFailed = false;
  bool get importFailed => _importFailed;

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
        _importingDictionary = true;
        notifyListeners();
        await isarService?.close();
        try {
          await IsarService.importDatabase();
          isarService = await IsarService.initialize();
        } catch (_) {
          // Something went wrong importing database
          _importFailed = true;
          notifyListeners();
          return;
        }
      }
    }

    // Register instance with locator
    StackedLocator.instance.registerSingleton(isarService!);

    // Finally, navigate to home
    _navigationService.replaceWith(Routes.homeView);
  }
}
