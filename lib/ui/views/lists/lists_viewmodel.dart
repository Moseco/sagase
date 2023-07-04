import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ListsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  ListSelection? _listSelection;
  ListSelection? get listSelection => _listSelection;

  List<DictionaryList>? get myDictionaryLists => _isarService.myDictionaryLists;

  void navigateToKana() {
    _navigationService.navigateTo(Routes.kanaView);
  }

  void navigateToRadicals() {
    _navigationService.navigateTo(Routes.kanjiRadicalsView);
  }

  Future<void> setListSelection(ListSelection? selection) async {
    _listSelection = selection;
    notifyListeners();
    // If opening my lists and they are not loaded, load them
    if (selection == ListSelection.myLists) {
      await _isarService.getMyDictionaryLists();
      notifyListeners();
    }
  }

  void back() {
    if (_listSelection == null) return;
    if (_listSelection!.index >= ListSelection.jlptKanji.index) {
      _listSelection = ListSelection.kanji;
    } else {
      _listSelection = null;
    }
    notifyListeners();
  }

  Future<void> navigateToPredefinedDictionaryList(int id) async {
    final list = await _isarService.getPredefinedDictionaryList(id);
    _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(dictionaryList: list!),
    );
  }

  Future<void> navigateToMyDictionaryList(DictionaryList list) async {
    await _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(dictionaryList: list),
    );
    notifyListeners();
  }

  Future<void> createMyDictionaryList() async {
    if (listSelection != ListSelection.myLists) return;

    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textField,
      title: 'Create new list',
      description: 'Name',
      mainButtonTitle: 'Create',
      barrierDismissible: true,
    );

    String? name = response?.data?.trim();
    if (name == null || name.isEmpty) return;

    await _isarService.createMyDictionaryList(name);
    notifyListeners();
  }
}

enum ListSelection {
  vocab,
  kanji,
  myLists,
  jlptKanji,
  schoolKanji,
  kanjiKentei,
}
