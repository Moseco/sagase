import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/conjugation_result.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/datamodels/writing_reading_pair.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase/utils/conjugation_utils.dart';
import 'package:sagase/utils/constants.dart' show kanjiRegExp;
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

import 'vocab_view.dart';

class VocabViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _mecabService = locator<MecabService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();
  final _snackbarService = locator<SnackbarService>();
  final _conjugationUtils = const ConjugationUtils();

  final Vocab vocab;
  final int? vocabListIndex;
  final List<Vocab>? vocabList;

  late final List<WritingReadingPair> writingReadingPairs;
  List<dynamic> get kanjiList => isBusy ? _kanjiStringList : _kanjiList;
  late final List<String> _kanjiStringList;
  late final List<Kanji> _kanjiList;

  List<int> _myDictionaryListsContainingVocab = [];
  bool get inMyDictionaryList => _myDictionaryListsContainingVocab.isNotEmpty;
  StreamSubscription<void>? _myDictionaryListsWatcher;

  List<ConjugationResult>? conjugations;

  bool get showPitchAccent => _sharedPreferencesService.getShowPitchAccent();

  VocabViewModel(this.vocab, this.vocabListIndex, this.vocabList) {
    // Create writing reading pairs
    writingReadingPairs = WritingReadingPair.fromVocab(vocab);

    // Get list of kanji to be loaded during initialize function
    Set<String> kanjiStringSet = {};
    if (vocab.writings != null) {
      for (var writing in vocab.writings!) {
        final foundKanjiList = kanjiRegExp.allMatches(writing.writing);
        for (var foundKanji in foundKanjiList) {
          kanjiStringSet.add(foundKanji[0]!);
        }
      }
    }
    _kanjiStringList = kanjiStringSet.toList();

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
    _myDictionaryListsContainingVocab = await _dictionaryService
        .getMyDictionaryListsContainingDictionaryItem(vocab);
    rebuildUi();

    // Load kanji from database that were found during class constructor
    _kanjiList = await _dictionaryService
        .getKanjiList(_kanjiStringList.map((e) => e.kanjiCodePoint()).toList());
  }

  void _startWatcher() {
    _myDictionaryListsWatcher ??= _dictionaryService
        .watchMyDictionaryListsContainingDictionaryItem(vocab)
        .listen((event) {
      _myDictionaryListsContainingVocab = event;
      rebuildUi();
    });
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }

  Future<void> openMyDictionaryListsSheet() async {
    // Make sure my dictionary lists containing vocab has been loaded
    if (isBusy) {
      _myDictionaryListsContainingVocab = await _dictionaryService
          .getMyDictionaryListsContainingDictionaryItem(vocab);
    }

    final myDictionaryLists =
        await _dictionaryService.getAllMyDictionaryLists();

    // Create list for bottom sheet
    List<MyListsBottomSheetItem> bottomSheetItems = [];
    for (var myDictionaryList in myDictionaryLists) {
      bottomSheetItems.add(MyListsBottomSheetItem(myDictionaryList, false));
    }
    // Mark lists that the vocab are in and move them to the top
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (_myDictionaryListsContainingVocab
          .contains(bottomSheetItems[i].list.id)) {
        bottomSheetItems[i].enabled = true;
        bottomSheetItems.insert(0, bottomSheetItems.removeAt(i));
      }
    }

    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignMyListsBottom,
      data: bottomSheetItems,
    );

    _myDictionaryListsContainingVocab.clear();
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (bottomSheetItems[i].enabled) {
        _myDictionaryListsContainingVocab.add(bottomSheetItems[i].list.id);
      }
      if (!bottomSheetItems[i].changed) continue;
      if (bottomSheetItems[i].enabled) {
        await _dictionaryService.addToMyDictionaryList(
            bottomSheetItems[i].list, vocab);
      } else {
        await _dictionaryService.removeFromMyDictionaryList(
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
      arguments: TextAnalysisViewArguments(
        initialText: example.japanese,
        addToHistory: false,
      ),
    );
  }

  Future<void> openVocabReference(VocabReference reference) async {
    if (reference.ids != null) {
      _startWatcher();
      if (reference.ids!.length == 1) {
        final vocab = await _dictionaryService.getVocab(reference.ids![0]);
        await _navigationService.navigateToVocabView(vocab: vocab);
      } else {
        final vocabList = await _dictionaryService.getVocabList(reference.ids!);
        await _bottomSheetService.showCustomSheet(
          variant: BottomSheetType.dictionaryItemsBottom,
          data: vocabList,
        );
      }
    } else {
      Clipboard.setData(ClipboardData(text: reference.text));
      _snackbarService.showSnackbar(
        message: 'Reference not found. ${reference.text} copied to clipboard.',
      );
    }
  }

  bool shouldShowTutorial() {
    if (vocab.readings[0].pitchAccents != null) {
      return _sharedPreferencesService.getAndSetTutorialVocab();
    } else {
      return false;
    }
  }

  void navigateToPreviousVocab() {
    _navigationService.replaceWithTransition(
      VocabView(
        vocabList![vocabListIndex! - 1],
        vocabListIndex: vocabListIndex! - 1,
        vocabList: vocabList,
      ),
      transitionStyle: Transition.noTransition,
      popGesture: Platform.isIOS,
    );
  }

  void navigateToNextVocab() {
    _navigationService.replaceWithTransition(
      VocabView(
        vocabList![vocabListIndex! + 1],
        vocabListIndex: vocabListIndex! + 1,
        vocabList: vocabList,
      ),
      transitionStyle: Transition.noTransition,
      popGesture: Platform.isIOS,
    );
  }

  @override
  void dispose() {
    _myDictionaryListsWatcher?.cancel();
    super.dispose();
  }
}
