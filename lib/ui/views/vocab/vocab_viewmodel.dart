import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/conjugation_result.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase/utils/conjugation_utils.dart';
import 'package:sagase/utils/constants.dart' show kanjiRegExp;
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class VocabViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _mecabService = locator<MecabService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _snackbarService = locator<SnackbarService>();

  final Vocab vocab;

  final List<Kanji> kanjiList = [];
  bool _kanjiLoaded = false;
  bool get kanjiLoaded => _kanjiLoaded;

  final _conjugationUtils = const ConjugationUtils();
  List<ConjugationResult>? conjugations;

  bool get showPitchAccent => _sharedPreferencesService.getShowPitchAccent();

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

    // Get conjugations
    conjugations = _conjugationUtils.getConjugations(vocab);

    // Tokenize example sentences
    for (var definition in vocab.definitions) {
      if (definition.examples != null) {
        for (var example in definition.examples!) {
          example.tokens = _mecabService.parseText(example.japanese);
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

    await _refreshMyDictionaryListLinks();
  }

  Future<void> _refreshMyDictionaryListLinks() async {
    // If my lists have been changed, reload back links
    if (_isarService.myDictionaryListsChanged) {
      final updatedVocab = await _isarService.getVocab(vocab.id);
      vocab.myDictionaryListLinks.clear();
      vocab.myDictionaryListLinks
          .addAll(updatedVocab!.myDictionaryListLinks.toList());
      notifyListeners();
    }
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
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

    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignMyListsBottom,
      data: list,
    );

    for (int i = 0; i < list.length; i++) {
      if (!list[i].changed) continue;
      if (list[i].enabled) {
        await _isarService.addVocabToMyDictionaryList(list[i].list, vocab);
      } else {
        await _isarService.removeVocabFromMyDictionaryList(list[i].list, vocab);
      }
    }

    // Reload back links
    await _refreshMyDictionaryListLinks();
  }

  List<RubyTextPair> getRubyTextPairs(String writing, String reading) {
    return _mecabService.createRubyTextPairs(writing, reading);
  }

  void toggleShowPitchAccent() {
    _sharedPreferencesService.setShowPitchAccent(!showPitchAccent);
    notifyListeners();
  }

  PartOfSpeech getConjugationPos() {
    return _conjugationUtils.getPartOfSpeech(vocab)!;
  }

  Future<void> openExampleInAnalysis(VocabExample example) async {
    await _navigationService.navigateTo(
      Routes.textAnalysisView,
      arguments: TextAnalysisViewArguments(initialText: example.japanese),
    );
    await _refreshMyDictionaryListLinks();
  }

  Future<void> openVocabReference(VocabReference reference) async {
    if (reference.id != null) {
      final vocab = await _isarService.getVocab(reference.id!);
      await _navigationService.navigateToVocabView(vocab: vocab!);
      await _refreshMyDictionaryListLinks();
    } else {
      Clipboard.setData(ClipboardData(text: reference.text));
      _snackbarService.showSnackbar(
        message:
            'Single vocab not found. ${reference.text} copied to clipboard.',
        duration: const Duration(seconds: 2),
      );
    }
  }
}
