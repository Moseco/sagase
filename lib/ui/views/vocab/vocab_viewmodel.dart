import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/ui/setup_bottom_sheet_ui.dart';
import 'package:sagase/utils/constants.dart' show kanjiRegExp;
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class VocabViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();

  final Vocab vocab;

  final List<Kanji> kanjiList = [];
  bool _kanjiLoaded = false;
  bool get kanjiLoaded => _kanjiLoaded;

  VocabViewModel(this.vocab) {
    // Get list of kanji to be loaded during initialize function
    List<String> kanjiStrings = [];
    for (var pair in vocab.kanjiReadingPairs) {
      if (pair.kanjiWritings == null) continue;
      for (var kanjiWriting in pair.kanjiWritings!) {
        final foundKanjiList = kanjiRegExp.allMatches(kanjiWriting.kanji);
        for (var foundKanji in foundKanjiList) {
          if (kanjiStrings.contains(foundKanji[0]!)) continue;
          kanjiStrings.add(foundKanji[0]!);
          kanjiList.add(Kanji()..kanji = foundKanji[0]!);
        }
      }
    }
  }

  Future<void> initialize() async {
    // Load kanji from database that were found during class constructor
    for (int i = 0; i < kanjiList.length; i++) {
      final kanji = await _isarService.getKanji(kanjiList[i].kanji);
      if (kanji != null) {
        kanjiList[i] = kanji;
      } else {
        kanjiList.removeAt(i);
        i--;
      }
    }

    _kanjiLoaded = true;
    notifyListeners();

    // If my lists have been changed, reload back links
    if (_isarService.myDictionaryListsChanged) {
      final newVocab = await _isarService.getVocab(vocab.id);
      vocab.myDictionaryListLinks.clear();
      vocab.myDictionaryListLinks
          .addAll(newVocab!.myDictionaryListLinks.toList());
      notifyListeners();
    }
  }

  void navigateToKanji(Kanji kanji) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
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
    // Mark lists that the vocab is in and move them to the top
    for (int i = 0; i < vocab.myDictionaryListLinks.length; i++) {
      for (int j = 0; j < list.length; j++) {
        if (vocab.myDictionaryListLinks.elementAt(i).id == list[j].list.id) {
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
          await _isarService.addVocabToMyDictionaryList(
              response.data[i].list, vocab);
        } else {
          await _isarService.removeVocabFromMyDictionaryList(
              response.data[i].list, vocab);
        }
      }

      // Reload back links
      final updatedVocab = await _isarService.getVocab(vocab.id);
      vocab.myDictionaryListLinks.clear();
      vocab.myDictionaryListLinks
          .addAll(updatedVocab!.myDictionaryListLinks.toList());
      notifyListeners();
    }
  }
}
