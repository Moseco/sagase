import 'dart:async';
import 'dart:io';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/views/lists/lists_view.dart';
import 'package:sagase/utils/constants.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ListsViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _snackbarService = locator<SnackbarService>();

  final ListSelection listSelection;

  List<MyDictionaryList>? myDictionaryLists;

  StreamSubscription<List<MyDictionaryList>>? _myListsWatcher;

  ListsViewModel(this.listSelection);

  @override
  Future<void> futureToRun() async {
    // If opening my lists, load them
    if (listSelection == ListSelection.myLists) await _loadMyLists();
  }

  Future<void> _loadMyLists() async {
    final stream = _dictionaryService.watchMyDictionaryLists();
    _myListsWatcher = stream.listen(
      (event) {
        myDictionaryLists = event;
        rebuildUi();
      },
    );
    await stream.first;
  }

  void navigateToKana() {
    _navigationService.navigateTo(Routes.kanaView);
  }

  void navigateToRadicals() {
    _navigationService.navigateTo(Routes.radicalsView);
  }

  Future<void> setListSelection(ListSelection listSelection) async {
    _navigationService.navigateToView(
      ListsView(listSelection: listSelection),
      id: nestedNavigationKey,
      popGesture: Platform.isIOS,
      preventDuplicates: false,
    );
  }

  void back() {
    _navigationService.back(id: nestedNavigationKey);
  }

  Future<void> navigateToPredefinedDictionaryList(int id) async {
    final list = await _dictionaryService.getPredefinedDictionaryList(id);
    _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(dictionaryList: list),
    );
  }

  Future<void> navigateToMyDictionaryList(DictionaryList list) async {
    await _navigationService.navigateTo(
      Routes.dictionaryListView,
      arguments: DictionaryListViewArguments(dictionaryList: list),
    );
  }

  void handlePopupMenuButton(PopupMenuItemType type) {
    switch (type) {
      case PopupMenuItemType.create:
        createMyDictionaryList();
        break;
      case PopupMenuItemType.import:
        _importMyDictionaryList();
        break;
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

    if (response?.data == null) return;
    final name = (response!.data as String).sanitizeName();
    if (name.isEmpty) return;

    myDictionaryLists!
        .insert(0, await _dictionaryService.createMyDictionaryList(name));

    notifyListeners();
  }

  Future<void> _importMyDictionaryList() async {
    // Ask user for the file they want to import
    String? filePath;
    try {
      filePath = await FlutterFileDialog.pickFile(
        params: const OpenFileDialogParams(fileExtensionsFilter: ['sagase']),
      );
    } catch (_) {
      filePath = null;
    }

    if (filePath == null) {
      _snackbarService.showSnackbar(message: 'Import cancelled');
      return;
    }

    // Show progress indicator dialog
    _dialogService.showCustomDialog(
      variant: DialogType.progressIndicator,
      title: 'Importing list',
      barrierDismissible: false,
    );

    final myList = await _dictionaryService.importMyDictionaryList(filePath);

    _dialogService.completeDialog(DialogResponse());

    if (myList == null) {
      _snackbarService.showSnackbar(message: 'Import failed');
      return;
    }

    myDictionaryLists!.insert(0, myList);
    rebuildUi();

    navigateToMyDictionaryList(myList);
  }

  void showDescriptionDialog(String title, String description) {
    _dialogService.showCustomDialog(
      variant: DialogType.info,
      title: title,
      description: description,
      mainButtonTitle: 'Close',
      barrierDismissible: true,
    );
  }

  @override
  void dispose() {
    _myListsWatcher?.cancel();
    super.dispose();
  }
}

enum ListSelection {
  main,
  vocab,
  kanji,
  myLists,
  jlptKanji,
  schoolKanji,
  kanjiKentei,
}

enum PopupMenuItemType {
  create,
  import,
}
