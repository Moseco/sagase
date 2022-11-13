import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/ui/setup_bottom_sheet_ui.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();

  final Kanji kanji;

  KanjiViewModel(this.kanji);

  Future<void> initialize() async {
    // If my lists have been changed, reload back links
    if (_isarService.myDictionaryListsChanged) {
      final newKanji = await _isarService.getKanji(kanji.kanji);
      kanji.myDictionaryListLinks.clear();
      kanji.myDictionaryListLinks
          .addAll(newKanji!.myDictionaryListLinks.toList());
      notifyListeners();
    }
  }

  void navigateToVocab(Vocab vocab) {
    _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
  }

  void showAllCompounds() {
    _navigationService.navigateTo(
      Routes.kanjiCompoundsView,
      arguments: KanjiCompoundsViewArguments(kanji: kanji),
    );
  }

  Future<void> openMyDictionaryListsSheet() async {
    if (_isarService.myDictionaryLists == null) {
      await _isarService.getMyDictionaryLists();
    }
    // Create list for bottom sheet
    List<MyDictionaryListsSheetItem> list = [];
    for (int i = 0; i < _isarService.myDictionaryLists!.length; i++) {
      list.add(MyDictionaryListsSheetItem(
          _isarService.myDictionaryLists![i], false));
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
      variant: BottomSheetType.myDictionaryLists,
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
      final newKanji = await _isarService.getKanji(kanji.kanji);
      kanji.myDictionaryListLinks.clear();
      kanji.myDictionaryListLinks
          .addAll(newKanji!.myDictionaryListLinks.toList());
      notifyListeners();
    }
  }
}
