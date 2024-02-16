import 'package:sagase/app/app.locator.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ChangelogViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  bool _showCurrentChangelog = true;
  bool get showCurrentChangelog => _showCurrentChangelog;

  void toggleShowCurrentChangelog() {
    _showCurrentChangelog = !_showCurrentChangelog;
    rebuildUi();
  }

  void closeChangelog() {
    _navigationService.back();
  }
}
