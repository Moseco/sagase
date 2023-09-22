import 'package:sagase/app/app.locator.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutViewModel extends BaseViewModel {
  final _snackbarService = locator<SnackbarService>();

  Future<void> openUrl(String url) async {
    try {
      if (!await launchUrl(Uri.parse(url))) {
        _snackbarService.showSnackbar(
          message: 'Failed to open link',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      _snackbarService.showSnackbar(
        message: 'Failed to open link',
        duration: const Duration(seconds: 2),
      );
    }
  }
}
