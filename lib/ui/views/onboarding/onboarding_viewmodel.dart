import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class OnboardingViewModel extends BaseViewModel {
  void finishOnboarding() {
    locator<SharedPreferencesService>().setOnboardingFinished();
    locator<NavigationService>().back();
  }
}
