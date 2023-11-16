import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/lists_bottom_sheet_argument.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetSettingsViewModel extends FutureViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _bottomSheetService = locator<BottomSheetService>();

  final FlashcardSet flashcardSet;

  late List<PredefinedDictionaryList> predefinedDictionaryLists;
  late List<MyDictionaryList> myDictionaryLists;

  FlashcardSetSettingsViewModel(this.flashcardSet);

  @override
  Future<void> futureToRun() async {
    predefinedDictionaryLists = await _isarService.getPredefinedDictionaryLists(
      flashcardSet.predefinedDictionaryLists,
    );
    myDictionaryLists = await _isarService.getMyDictionaryLists(
      flashcardSet.myDictionaryLists,
    );
    rebuildUi();
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
      variant: DialogType.textField,
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
      variant: DialogType.confirmation,
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
      variant: DialogType.confirmation,
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
    // Get included predefined lists
    Map<int, ({bool enabled, bool changed})> predefinedLists = {};
    for (var id in flashcardSet.predefinedDictionaryLists) {
      predefinedLists[id] = (enabled: true, changed: false);
    }

    // Create list for my lists
    List<MyListsBottomSheetItem> myLists = [];
    for (var myList in await _isarService.getAllMyDictionaryLists()) {
      myLists.add(MyListsBottomSheetItem(myList, false));
    }
    // Mark lists that the flashcard set uses and move them to the top
    for (int i = 0; i < myLists.length; i++) {
      if (flashcardSet.myDictionaryLists.contains(myLists[i].list.id)) {
        myLists[i].enabled = true;
        myLists.insert(0, myLists.removeAt(i));
      }
    }

    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignListsBottom,
      data: ListsBottomSheetArgument(predefinedLists, myLists),
    );

    // Add and remove predefined dictionary lists from the flashcard set
    flashcardSet.predefinedDictionaryLists =
        flashcardSet.predefinedDictionaryLists.toList();
    predefinedDictionaryLists = predefinedDictionaryLists.toList();
    for (var entry in predefinedLists.entries) {
      if (!entry.value.changed) continue;
      if (entry.value.enabled) {
        if (!flashcardSet.predefinedDictionaryLists.contains(entry.key)) {
          flashcardSet.predefinedDictionaryLists.add(entry.key);
          predefinedDictionaryLists.add(
              (await _isarService.getPredefinedDictionaryList(entry.key))!);
        }
      } else {
        flashcardSet.predefinedDictionaryLists.remove(entry.key);
        predefinedDictionaryLists
            .removeWhere((element) => element.id == entry.key);
      }
    }
    // Add and remove my dictionary lists from the flashcard set
    flashcardSet.myDictionaryLists = flashcardSet.myDictionaryLists.toList();
    myDictionaryLists = myDictionaryLists.toList();
    for (var myList in myLists) {
      if (!myList.changed) continue;
      if (myList.enabled) {
        if (!flashcardSet.myDictionaryLists.contains(myList.list.id)) {
          flashcardSet.myDictionaryLists.add(myList.list.id);
          myDictionaryLists.add(myList.list);
        }
      } else {
        flashcardSet.myDictionaryLists.remove(myList.list.id);
        myDictionaryLists
            .removeWhere((element) => element.id == myList.list.id);
      }
    }

    await _isarService.updateFlashcardSet(flashcardSet);
    notifyListeners();
  }

  void setOrderType(bool value) {
    flashcardSet.usingSpacedRepetition = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setFrontType(FrontType frontType) {
    flashcardSet.frontType = frontType;
    // Not great solution, but just reset flashcards completed
    flashcardSet.flashcardsCompletedToday = 0;
    flashcardSet.newFlashcardsCompletedToday = 0;
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

  void setVocabShowPitchAccent(bool value) {
    flashcardSet.vocabShowPitchAccent = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setKanjiShowReading(bool value) {
    flashcardSet.kanjiShowReading = value;
    notifyListeners();
    _isarService.updateFlashcardSet(flashcardSet);
  }

  void setVocabShowPartsOfSpeech(bool value) {
    flashcardSet.vocabShowPartsOfSpeech = value;
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
