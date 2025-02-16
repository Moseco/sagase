import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import 'kanji_view.dart';

class KanjiViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _snackbarService = locator<SnackbarService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _dialogService = locator<DialogService>();

  final Kanji kanji;
  final int? kanjiListIndex;
  final List<Kanji>? kanjiList;

  Radical? radical;
  List<Kanji>? components;
  List<Vocab>? compoundPreviewList;

  List<int> _myDictionaryListsContainingKanji = [];
  bool get inMyDictionaryList => _myDictionaryListsContainingKanji.isNotEmpty;
  StreamSubscription<void>? _myDictionaryListsWatcher;

  bool get strokeDiagramStartExpanded =>
      _sharedPreferencesService.getStrokeDiagramStartExpanded();

  KanjiViewModel(this.kanji, this.kanjiListIndex, this.kanjiList);

  @override
  Future<void> futureToRun() async {
    _myDictionaryListsContainingKanji = await _dictionaryService
        .getMyDictionaryListsContainingDictionaryItem(kanji);
    rebuildUi();

    radical = await _dictionaryService.getRadical(kanji.radical);
    rebuildUi();

    if (kanji.components != null) {
      components = await _dictionaryService.getKanjiList(
          kanji.components!.map((e) => e.kanjiCodePoint()).toList());
      rebuildUi();
    }

    if (kanji.compounds != null) {
      compoundPreviewList =
          await _dictionaryService.getVocabList(kanji.compounds!);
      rebuildUi();
    }
  }

  void _startWatcher() {
    _myDictionaryListsWatcher ??= _dictionaryService
        .watchMyDictionaryListsContainingDictionaryItem(kanji)
        .listen((event) {
      _myDictionaryListsContainingKanji = event;
      rebuildUi();
    });
  }

  Future<void> navigateToRadical() async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.radicalView,
      arguments: RadicalViewArguments(radical: radical!),
    );
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }

  Future<void> navigateToVocab(Vocab vocab) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
  }

  Future<void> showAllCompounds() async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiCompoundsView,
      arguments: KanjiCompoundsViewArguments(kanji: kanji),
    );
  }

  Future<void> openMyDictionaryListsSheet() async {
    // Make sure my dictionary lists containing kanji has been loaded
    if (isBusy) {
      _myDictionaryListsContainingKanji = await _dictionaryService
          .getMyDictionaryListsContainingDictionaryItem(kanji);
    }

    final myDictionaryLists =
        await _dictionaryService.getAllMyDictionaryLists();

    // Create list for bottom sheet
    List<MyListsBottomSheetItem> bottomSheetItems = [];
    for (var myDictionaryList in myDictionaryLists) {
      bottomSheetItems.add(MyListsBottomSheetItem(myDictionaryList, false));
    }
    // Mark lists that the kanji is in and move them to the top
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (_myDictionaryListsContainingKanji
          .contains(bottomSheetItems[i].list.id)) {
        bottomSheetItems[i].enabled = true;
        bottomSheetItems.insert(0, bottomSheetItems.removeAt(i));
      }
    }

    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignMyListsBottom,
      data: bottomSheetItems,
    );

    _myDictionaryListsContainingKanji.clear();
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (bottomSheetItems[i].enabled) {
        _myDictionaryListsContainingKanji.add(bottomSheetItems[i].list.id);
      }
      if (!bottomSheetItems[i].changed) continue;
      if (bottomSheetItems[i].enabled) {
        await _dictionaryService.addToMyDictionaryList(
            bottomSheetItems[i].list, kanji);
      } else {
        await _dictionaryService.removeFromMyDictionaryList(
            bottomSheetItems[i].list, kanji);
      }
    }

    rebuildUi();
  }

  void copyKanji() {
    Clipboard.setData(ClipboardData(text: kanji.kanji));
    if (!_snackbarService.isSnackbarOpen) {
      _snackbarService.showSnackbar(
        message: '${kanji.kanji} copied to clipboard',
        duration: const Duration(seconds: 1),
      );
    }
  }

  void setStrokeDiagramStartExpanded(bool value) {
    _sharedPreferencesService.setStrokeDiagramStartExpanded(value);
  }

  void navigateToPreviousKanji() {
    _navigationService.replaceWithTransition(
      KanjiView(
        kanjiList![kanjiListIndex! - 1],
        kanjiListIndex: kanjiListIndex! - 1,
        kanjiList: kanjiList,
      ),
      transitionStyle: Transition.noTransition,
      popGesture: Platform.isIOS,
    );
  }

  void navigateToNextKanji() {
    _navigationService.replaceWithTransition(
      KanjiView(
        kanjiList![kanjiListIndex! + 1],
        kanjiListIndex: kanjiListIndex! + 1,
        kanjiList: kanjiList,
      ),
      transitionStyle: Transition.noTransition,
      popGesture: Platform.isIOS,
    );
  }

  Future<void> editNote() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.noteEdit,
      data: kanji.note,
      barrierDismissible: true,
    );

    if (response?.data == null) return;

    if (response!.data == '') {
      kanji.note = null;
      _dictionaryService.deleteKanjiNote(kanji.id);
    } else {
      kanji.note = response.data;
      _dictionaryService.setKanjiNote(kanji.id, kanji.note!);
    }

    rebuildUi();
  }

  @override
  void dispose() {
    _myDictionaryListsWatcher?.cancel();
    super.dispose();
  }
}
