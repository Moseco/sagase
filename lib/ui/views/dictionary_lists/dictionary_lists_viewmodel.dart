import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DictionaryListsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  void navigateToRadicals() {
    _navigationService.navigateTo(Routes.kanjiRadicalsView);
  }
}
