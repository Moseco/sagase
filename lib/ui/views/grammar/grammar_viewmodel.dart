import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class GrammarViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  void openLesson() {
    _navigationService.navigateTo(
      Routes.grammarLessonView,
      arguments: GrammarLessonViewArguments(grammarLessonId: 1),
    );
  }
}
