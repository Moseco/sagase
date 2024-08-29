import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/firebase_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:url_launcher/url_launcher.dart';

class OnboardingViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _firebaseService = locator<FirebaseService>();
  final _snackbarService = locator<SnackbarService>();

  bool get properNounsEnabled =>
      _sharedPreferencesService.getProperNounsEnabled();
  bool get analyticsEnabled => _sharedPreferencesService.getAnalyticsEnabled();
  bool get crashlyticsEnabled => _firebaseService.crashlyticsEnabled;

  void finishOnboarding() {
    _sharedPreferencesService.setOnboardingFinished();
    _navigationService.back();
  }

  void setProperNounsEnabled(bool value) {
    _sharedPreferencesService.setProperNounsEnabled(value);
    rebuildUi();
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
