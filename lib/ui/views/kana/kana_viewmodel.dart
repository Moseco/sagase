import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanaViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  bool showHiragana = true;

  void toggleKana() {
    showHiragana = !showHiragana;
    notifyListeners();
  }

  void navigateToKanaPractice() {
    _navigationService.navigateTo(Routes.kanaPracticeView);
  }
}
