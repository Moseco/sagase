import 'package:in_app_review/in_app_review.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart'
    show nestedNavigationKey, currentChangelogVersion;

class HomeViewModel extends IndexTrackingViewModel {
  final _navigationService = locator<NavigationService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  bool _showNavigationBar = true;
  bool get showNavigationBar => _showNavigationBar;

  bool get startOnLearningView =>
      _sharedPreferencesService.getStartOnLearningView();

  HomeViewModel() {
    if (startOnLearningView) setIndex(2);
    _checkReviewRequest();
    _checkChangelog();
  }

  Future<void> _checkReviewRequest() async {
    // Only allow requests once
    if (_sharedPreferencesService.getReviewRequested()) return;

    final inAppReview = InAppReview.instance;
    int startCount = _sharedPreferencesService.getReviewStartCount() + 1;
    // Make sure the user has used the app for a week and opened the app more than 20 times
    if (startCount > 20 &&
        DateTime.now()
                .difference(_sharedPreferencesService.getReviewStartTimestamp())
                .inDays >
            7 &&
        await inAppReview.isAvailable()) {
      inAppReview.requestReview();
      _sharedPreferencesService.setReviewRequested();
    } else {
      _sharedPreferencesService.setReviewStartCount(startCount);
    }
  }

  void _checkChangelog() {
    int? versionShown = _sharedPreferencesService.getChangelogVersionShown();

    if (versionShown == null) {
      // New user, don't show changelog
      _sharedPreferencesService.setChangelogVersionShown();
    } else if (versionShown < currentChangelogVersion) {
      // Existing user, show changelog
      _sharedPreferencesService.setChangelogVersionShown();
      // Zero duration delay to avoid concurrent build/navigation issues
      Future.delayed(
        Duration.zero,
        _navigationService.navigateToChangelogView,
      );
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

  void handleBackButton() {
    if (currentIndex != 0) handleNavigation(0);
  }
}
