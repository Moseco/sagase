import 'package:in_app_review/in_app_review.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' show nestedNavigationKey;

class HomeViewModel extends IndexTrackingViewModel {
  final _navigationService = locator<NavigationService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  bool _showNavigationBar = true;
  bool get showNavigationBar => _showNavigationBar;

  bool get startOnLearningView =>
      _sharedPreferencesService.getStartOnLearningView();

  HomeViewModel() {
    if (startOnLearningView) setIndex(2);
    _tryRequestReview();
  }

  Future<void> _tryRequestReview() async {
    final inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable() &&
        _sharedPreferencesService.shouldRequestAppReview()) {
      inAppReview.requestReview();
    }
  }

  void handleNavigation(int index) {
    // Prevent navigation to the same screen
    if (index == currentIndex) {
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

  bool handleBackButton() {
    if (currentIndex != 0) {
      handleNavigation(0);
      return false;
    } else {
      return true;
    }
  }
}
