import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.dialog.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/lists_bottom_sheet_argument.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetSettingsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  final FlashcardSet flashcardSet;

  FlashcardSetSettingsViewModel(this.flashcardSet) {
    _loadLists();
  }

  Future<void> _loadLists() async {
    await flashcardSet.predefinedDictionaryListLinks.load();
    await flashcardSet.myDictionaryListLinks.load();
    notifyListeners();
  }

  void handlePopupMenuButton(PopupMenuItemType type) {
    switch (type) {
      case PopupMenuItemType.rename:
        _renameFlashcardSet();
        break;
      case PopupMenuItemType.delete:
        _deleteFlashcardSet();
        break;
      case PopupMenuItemType.reset:
        _resetSpacedRepetitionData();
        break;
      case PopupMenuItemType.statistics:
        _openFlashcardSetInfo();
        break;
    }
  }

  Future<void> _renameFlashcardSet() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textFieldDialog,
      title: 'Rename flashcards',
      description: 'Name',
      mainButtonTitle: 'Update',
      data: flashcardSet.name,
      barrierDismissible: true,
    );

    String? name = response?.data?.trim();
    if (name == null || name.isEmpty) return;

    flashcardSet.name = name;
    _isarService.updateFlashcardSet(flashcardSet);
    notifyListeners();
  }

  Future<void> _deleteFlashcardSet() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmationDialog,
      title: 'Delete flashcards?',
      mainButtonTitle: 'Delete',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      _isarService.deleteFlashcardSet(flashcardSet);
      // Send true as result when deleting
      _navigationService.back(result: true);
    }
  }

  Future<void> _resetSpacedRepetitionData() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmationDialog,
      title: 'Reset spaced repetition data?',
      description:
          'This will effect all items that are part of this flashcard set and the same items that are part of other flashcard sets. This action cannot be undone.',
      mainButtonTitle: 'Reset',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      _isarService.resetFlashcardSetSpacedRepetitionData(flashcardSet);
    }
  }

  void _openFlashcardSetInfo() {
    _navigationService.navigateTo(
      Routes.flashcardSetInfoView,
      arguments: FlashcardSetInfoViewArguments(flashcardSet: flashcardSet),
    );
  }

  Future<void> editIncludedLists() async {
    if (_isarService.myDictionaryLists == null) {
      await _isarService.getMyDictionaryLists();
    }
    // Get included predefined lists
    Map<int, bool> predefinedLists = {};
    for (int i = 0;
        i < flashcardSet.predefinedDictionaryListLinks.length;
        i++) {
      predefinedLists[
          flashcardSet.predefinedDictionaryListLinks.elementAt(i).id!] = true;
    }
    // Create list for my lists
    List<MyListsBottomSheetItem> myDictionaryLists = [];
    for (int i = 0; i < _isarService.myDictionaryLists!.length; i++) {
      myDictionaryLists.add(
          MyListsBottomSheetItem(_isarService.myDictionaryLists![i], false));
    }
    // Mark lists that the flashcard set uses and move them to the top
    for (int i = 0; i < flashcardSet.myDictionaryListLinks.length; i++) {
      for (int j = 0; j < myDictionaryLists.length; j++) {
        if (flashcardSet.myDictionaryListLinks.elementAt(i).id ==
            myDictionaryLists[j].list.id) {
          myDictionaryLists[j].enabled = true;
          final temp = myDictionaryLists.removeAt(j);
          myDictionaryLists.insert(0, temp);
          break;
        }
      }
    }

    final response = await _bottomSheetService.showCustomSheet(
      variant: BottomsheetType.assignListsBottomSheet,
      data: ListsBottomSheetArgument(predefinedLists, myDictionaryLists),
      barrierDismissible: false,
    );

    if (response?.data != null) {
      // Get predefined dictionary lists to add or remove from flashcard set
      List<int> predefinedListsToAdd = [];
      List<int> predefinedListsToRemove = [];
      for (var pairs in response!.data.predefinedLists.entries) {
        if (pairs.value) {
          predefinedListsToAdd.add(pairs.key);
        } else {
          predefinedListsToRemove.add(pairs.key);
        }
      }
      // Get my dictionary lists to add or remove from flashcard set
      List<MyDictionaryList> myListsToAdd = [];
      List<MyDictionaryList> myListsToRemove = [];
      for (int i = 0; i < response.data.myLists.length; i++) {
        if (response.data.myLists[i].enabled) {
          myListsToAdd.add(response.data.myLists[i].list);
        } else {
          myListsToRemove.add(response.data.myLists[i].list);
        }
      }
      // Add and remove from database
      await _isarService.addDictionaryListsToFlashcardSet(
        flashcardSet,
        predefinedDictionaryListIds: predefinedListsToAdd,
        myDictionaryLists: myListsToAdd,
      );
      await _isarService.removeDictionaryListsToFlashcardSet(
        flashcardSet,
        predefinedDictionaryListIds: predefinedListsToRemove,
        myDictionaryLists: myListsToRemove,
      );
      notifyListeners();
    }
  }

  void setOrderType(bool value) {
    flashcardSet.usingSpacedRepetition = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setVocabShowReading(bool value) {
    flashcardSet.vocabShowReading = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setVocabShowReadingIfRareKanji(bool value) {
    flashcardSet.vocabShowReadingIfRareKanji = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setVocabShowAlternatives(bool value) {
    flashcardSet.vocabShowAlternatives = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setKanjiShowReading(bool value) {
    flashcardSet.kanjiShowReading = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void openFlashcardSet() {
    _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(flashcardSet: flashcardSet),
    );
  }
}

enum PopupMenuItemType {
  rename,
  delete,
  reset,
  statistics,
}
