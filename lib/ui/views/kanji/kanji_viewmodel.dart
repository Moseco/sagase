import 'dart:math';

import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class KanjiViewModel extends FutureViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _snackbarService = locator<SnackbarService>();

  final Kanji kanji;

  KanjiViewModel(this.kanji);

  @override
  Future<void> futureToRun() async {
    await _refreshMyDictionaryListLinks();
    await kanji.radical.load();
    rebuildUi();
    await kanji.componentLinks.load();
    rebuildUi();

    // Load the first 10 compounds
    for (int i = 0; i < min(10, kanji.compounds.length); i++) {
      kanji.compounds.elementAt(i);
    }
  }

  Future<void> _refreshMyDictionaryListLinks() async {
    // If my lists have been changed, reload back links
    if (_isarService.myDictionaryListsChanged) {
      final newKanji = await _isarService.getKanji(kanji.kanji);
      kanji.myDictionaryListLinks.clear();
      kanji.myDictionaryListLinks
          .addAll(newKanji!.myDictionaryListLinks.toList());
      rebuildUi();
    }
  }

  Future<void> navigateToKanjiRadical() async {
    await _navigationService.navigateTo(
      Routes.kanjiRadicalView,
      arguments: KanjiRadicalViewArguments(kanjiRadical: kanji.radical.value!),
    );
    await _refreshMyDictionaryListLinks();
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
    await _refreshMyDictionaryListLinks();
  }

  Future<void> navigateToVocab(Vocab vocab) async {
    await _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
    await _refreshMyDictionaryListLinks();
  }

  Future<void> showAllCompounds() async {
    await _navigationService.navigateTo(
      Routes.kanjiCompoundsView,
      arguments: KanjiCompoundsViewArguments(kanji: kanji),
    );
    await _refreshMyDictionaryListLinks();
  }

  Future<void> openMyDictionaryListsSheet() async {
    if (_isarService.myDictionaryLists == null) {
      await _isarService.getMyDictionaryLists();
    }
    // Create list for bottom sheet
    List<MyListsBottomSheetItem> list = [];
    for (int i = 0; i < _isarService.myDictionaryLists!.length; i++) {
      list.add(
          MyListsBottomSheetItem(_isarService.myDictionaryLists![i], false));
    }
    // Mark lists that the kanji is in and move them to the top
    for (int i = 0; i < kanji.myDictionaryListLinks.length; i++) {
      for (int j = 0; j < list.length; j++) {
        if (kanji.myDictionaryListLinks.elementAt(i).id == list[j].list.id) {
          list[j].enabled = true;
          final temp = list.removeAt(j);
          list.insert(0, temp);
          break;
        }
      }
    }

    final response = await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignMyListsBottom,
      data: list,
      barrierDismissible: false,
    );

    if (response?.data != null) {
      for (int i = 0; i < response!.data.length; i++) {
        if (response.data[i].enabled) {
          await _isarService.addKanjiToMyDictionaryList(
              response.data[i].list, kanji);
        } else {
          await _isarService.removeKanjiFromMyDictionaryList(
              response.data[i].list, kanji);
        }
      }

      // Reload back links
      await _refreshMyDictionaryListLinks();
    }
  }

  void copyKanji() {
    Clipboard.setData(ClipboardData(text: kanji.kanji));
    _snackbarService.showSnackbar(
      message: 'Copied to clipboard',
      duration: const Duration(seconds: 1),
    );
  }
}
