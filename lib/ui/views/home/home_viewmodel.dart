import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/views/lists/lists_viewmodel.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' show nestedNavigationKey;

class HomeViewModel extends IndexTrackingViewModel {
  final _navigationService = locator<NavigationService>();

  void handleNavigation(int index) {
    // Prevent navigation to the same screen
    if (index == currentIndex) {
      // If navigating to lists view, reset current list selection
      if (index == 1) locator<ListsViewModel>().setListSelection(null);
      return;
    }
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
          HomeViewRoutes.listsView,
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
