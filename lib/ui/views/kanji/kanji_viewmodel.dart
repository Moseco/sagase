import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class KanjiViewModel extends FutureViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _snackbarService = locator<SnackbarService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final Kanji kanji;

  bool _inMyLists = false;
  bool get inMyLists => _inMyLists;
  StreamSubscription<void>? _myListsWatcher;
  bool _myListsChanged = false;

  bool get strokeDiagramStartExpanded =>
      _sharedPreferencesService.getStrokeDiagramStartExpanded();

  KanjiRadical? kanjiRadical;
  List<Kanji>? components;
  List<Vocab>? compoundPreviewList;

  KanjiViewModel(this.kanji);

  @override
  Future<void> futureToRun() async {
    _inMyLists = await _isarService.isKanjiInMyDictionaryLists(kanji);
    rebuildUi();
    kanjiRadical = await _isarService.getKanjiRadical(kanji.radical);
    rebuildUi();
    if (kanji.components != null) {
      components = await _isarService.getKanjiList(
          kanji.components!.map((e) => e.kanjiCodePoint()).toList());
      rebuildUi();
    }

    // Load the first 10 compounds
    if (kanji.compounds != null) {
      compoundPreviewList = await _isarService.getVocabList(
          kanji.compounds!.sublist(0, min(10, kanji.compounds!.length)));
      rebuildUi();
    }
  }

  void _startWatcher() {
    _myListsWatcher ??= _isarService.watchMyDictionaryLists().listen((event) {
      _myListsChanged = true;
    });
  }

  Future<void> _refreshInMyLists() async {
    if (!_myListsChanged) return;

    _inMyLists = await _isarService.isKanjiInMyDictionaryLists(kanji);
    _myListsChanged = false;

    rebuildUi();
  }

  Future<void> navigateToKanjiRadical() async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiRadicalView,
      arguments: KanjiRadicalViewArguments(kanjiRadical: kanjiRadical!),
    );
    await _refreshInMyLists();
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
    await _refreshInMyLists();
  }

  Future<void> navigateToVocab(Vocab vocab) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
    await _refreshInMyLists();
  }

  Future<void> showAllCompounds() async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiCompoundsView,
      arguments: KanjiCompoundsViewArguments(kanji: kanji),
    );
    await _refreshInMyLists();
  }

  Future<void> openMyDictionaryListsSheet() async {
    final myDictionaryLists = await _isarService.getAllMyDictionaryLists();

    // Create list for bottom sheet
    List<MyListsBottomSheetItem> bottomSheetItems = [];
    for (var myList in myDictionaryLists) {
      bottomSheetItems.add(MyListsBottomSheetItem(myList, false));
    }
    // Mark lists that the kanji is in and move them to the top
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (bottomSheetItems[i].list.kanji.contains(kanji.id)) {
        bottomSheetItems[i].enabled = true;
        bottomSheetItems.insert(0, bottomSheetItems.removeAt(i));
      }
    }

    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignMyListsBottom,
      data: bottomSheetItems,
    );

    _inMyLists = false;
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (bottomSheetItems[i].enabled) _inMyLists = true;
      if (!bottomSheetItems[i].changed) continue;
      if (bottomSheetItems[i].enabled) {
        await _isarService.addKanjiToMyDictionaryList(
            bottomSheetItems[i].list, kanji);
      } else {
        await _isarService.removeKanjiFromMyDictionaryList(
            bottomSheetItems[i].list, kanji);
      }
    }

    rebuildUi();
  }

  void copyKanji() {
    Clipboard.setData(ClipboardData(text: kanji.kanji));
    _snackbarService.showSnackbar(
      message: '${kanji.kanji} copied to clipboard',
      duration: const Duration(seconds: 1),
    );
  }

  void setStrokeDiagramStartExpanded(bool value) {
    _sharedPreferencesService.setStrokeDiagramStartExpanded(value);
  }

  @override
  void dispose() {
    _myListsWatcher?.cancel();
    super.dispose();
  }
}
