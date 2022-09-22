import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' show nestedNavigationKey;

class HomeViewModel extends IndexTrackingViewModel {
  final _navigationService = locator<NavigationService>();

  void handleNavigation(int index) {
    setIndex(index);
    switch (index) {
      case 0:
        _navigationService.replaceWith(
          HomeViewRoutes.searchView,
          id: nestedNavigationKey,
        );
        break;
      case 1:
        _navigationService.replaceWith(
          HomeViewRoutes.dictionaryListsView,
          id: nestedNavigationKey,
        );
        break;
      case 2:
        _navigationService.replaceWith(
          HomeViewRoutes.learningView,
          id: nestedNavigationKey,
        );
        break;
      case 3:
        _navigationService.replaceWith(
          HomeViewRoutes.settingsView,
          id: nestedNavigationKey,
        );
        break;
    }
  }
}
