import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/firebase_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class OnboardingViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _firebaseService = locator<FirebaseService>();

  bool get analyticsEnabled => _sharedPreferencesService.getAnalyticsEnabled();
  bool get crashlyticsEnabled => _firebaseService.crashlyticsEnabled;

  void finishOnboarding() {
    _sharedPreferencesService.setOnboardingFinished();
    _navigationService.back();
  }

  void setAnalyticsEnabled(bool value) {
    _firebaseService.setAnalyticsEnabled(value);
    _sharedPreferencesService.setAnalyticsEnabled(value);
    rebuildUi();
  }

  void setCrashlyticsEnabled(bool value) {
    _firebaseService.setCrashlyticsEnabled(value);
    rebuildUi();
  }
}
