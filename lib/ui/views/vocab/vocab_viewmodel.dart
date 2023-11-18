import 'dart:async';

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

class VocabViewModel extends FutureViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _mecabService = locator<MecabService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _snackbarService = locator<SnackbarService>();

  final Vocab vocab;

  bool _inMyLists = false;
  bool get inMyLists => _inMyLists;
  StreamSubscription<void>? _myListsWatcher;
  bool _myListsChanged = false;

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

  @override
  Future<void> futureToRun() async {
    _inMyLists = await _isarService.isVocabInMyDictionaryLists(vocab);
    rebuildUi();
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
    rebuildUi();
  }

  void _startWatcher() {
    _myListsWatcher ??= _isarService.watchMyDictionaryLists().listen((event) {
      _myListsChanged = true;
    });
  }

  Future<void> _refreshInMyLists() async {
    if (!_myListsChanged) return;

    _inMyLists = await _isarService.isVocabInMyDictionaryLists(vocab);
    _myListsChanged = false;

    rebuildUi();
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
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
    // Mark lists that the vocab are in and move them to the top
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (bottomSheetItems[i].list.vocab.contains(vocab.id)) {
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
        await _isarService.addVocabToMyDictionaryList(
            bottomSheetItems[i].list, vocab);
      } else {
        await _isarService.removeVocabFromMyDictionaryList(
            bottomSheetItems[i].list, vocab);
      }
    }

    rebuildUi();
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
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.textAnalysisView,
      arguments: TextAnalysisViewArguments(initialText: example.japanese),
    );
    await _refreshInMyLists();
  }

  Future<void> openVocabReference(VocabReference reference) async {
    if (reference.ids != null) {
      _startWatcher();
      if (reference.ids!.length == 1) {
        final vocab = await _isarService.getVocab(reference.ids![0]);
        await _navigationService.navigateToVocabView(vocab: vocab!);
      } else {
        final vocabList = await _isarService.getVocabList(reference.ids!);
        await _bottomSheetService.showCustomSheet(
          variant: BottomSheetType.selectVocabBottom,
          data: vocabList,
        );
      }
      await _refreshInMyLists();
    } else {
      Clipboard.setData(ClipboardData(text: reference.text));
      _snackbarService.showSnackbar(
        message: 'Reference not found. ${reference.text} copied to clipboard.',
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  void dispose() {
    _myListsWatcher?.cancel();
    super.dispose();
  }
}
