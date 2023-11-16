import 'dart:async';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/views/lists/lists_view.dart';
import 'package:sagase/utils/constants.dart';
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

  List<DictionaryList>? myDictionaryLists;

  StreamSubscription<void>? _myListsWatcher;
  bool _myListsChanged = false;

  ListsViewModel(ListSelection? listSelection) {
    _listSelection = listSelection;
    // If opening my lists, load them
    if (listSelection == ListSelection.myLists) _loadMyLists();
  }

  Future<void> _loadMyLists() async {
    myDictionaryLists = await _isarService.getAllMyDictionaryLists();
    notifyListeners();
  }

  void navigateToKana() {
    _navigationService.navigateTo(Routes.kanaView);
  }

  void navigateToRadicals() {
    _navigationService.navigateTo(Routes.kanjiRadicalsView);
  }

  Future<void> setListSelection(ListSelection? selection) async {
    _navigationService.navigateToView(
      ListsView(selection: selection),
      id: nestedNavigationKey,
      popGesture: true,
      preventDuplicates: false,
    );
  }

  void back() {
    _navigationService.back(id: nestedNavigationKey);
  }

  Future<void> navigateToPredefinedDictionaryList(int id) async {
    final list = await _isarService.getPredefinedDictionaryList(id);
    _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(dictionaryList: list!),
    );
  }

  Future<void> navigateToMyDictionaryList(DictionaryList list) async {
    _myListsWatcher ??= _isarService.watchMyDictionaryLists().listen((event) {
      _myListsChanged = true;
    });
    await _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(dictionaryList: list),
    );
    if (_myListsChanged) {
      _myListsChanged = false;
      await _loadMyLists();
    }
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

    myDictionaryLists!
        .insert(0, await _isarService.createMyDictionaryList(name));

    notifyListeners();
  }

  @override
  void dispose() {
    _myListsWatcher?.cancel();
    super.dispose();
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
