import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DictionaryListsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();

  MainListSelection? _currentList;
  MainListSelection? get currentList => _currentList;

  void navigateToKana() {
    _navigationService.navigateTo(Routes.kanaView);
  }

  void navigateToRadicals() {
    _navigationService.navigateTo(Routes.kanjiRadicalsView);
  }

  void setCurrentList(MainListSelection? selection) {
    _currentList = selection;
    notifyListeners();
  }

  Future<void> navigateToList(int id) async {
    final list = await _isarService.getDictionaryList(id);
    _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(list: list!),
    );
  }
}

enum MainListSelection {
  vocab,
  kanji,
  myLists,
}
