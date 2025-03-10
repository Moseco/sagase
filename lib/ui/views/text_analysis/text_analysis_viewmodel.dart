import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class TextAnalysisViewModel extends FutureViewModel {
  final _mecabService = locator<MecabService>();
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _snackbarService = locator<SnackbarService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  TextAnalysisState _state = TextAnalysisState.editing;
  TextAnalysisState get state => _state;

  final String? _initialText;
  String _text = '';
  String get text => _text;

  bool _addToHistory;

  List<JapaneseTextToken>? tokens;

  bool _analysisFailed = true;
  bool get analysisFailed => _analysisFailed;

  TextAnalysisViewModel(this._initialText, this._addToHistory);

  @override
  Future<void> futureToRun() async {
    if (_initialText != null) await analyzeText(_initialText!);
  }

  void textChanged(String value) {
    if (_text.isEmpty && value.isNotEmpty) rebuildUi();
    if (_text.isNotEmpty && value.isEmpty) rebuildUi();
    _text = value;
  }

  Future<void> analyzeText(String text) async {
    String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _text = trimmed;
    _state = TextAnalysisState.loading;
    rebuildUi();

    _analysisFailed = true;

    tokens = _mecabService.parseText(_text);

    for (var token in tokens!) {
      if (token.pos == PartOfSpeech.nounProper &&
          _sharedPreferencesService.getProperNounsEnabled()) {
        token.associatedDictionaryItems =
            await _dictionaryService.getProperNounByJapaneseTextToken(token);
      }

      if (token.associatedDictionaryItems == null ||
          token.associatedDictionaryItems!.isEmpty) {
        token.associatedDictionaryItems =
            await _dictionaryService.getVocabByJapaneseTextToken(token);
      }
      if (token.associatedDictionaryItems!.isNotEmpty) {
        _analysisFailed = false;
      }
    }

    _state = TextAnalysisState.viewing;
    rebuildUi();

    if (_addToHistory) {
      await _dictionaryService.createTextAnalysisHistoryItem(text);
    }
    _addToHistory = true;
  }

  void editText() {
    _state = TextAnalysisState.editing;
    rebuildUi();
  }

  void copyText() {
    Clipboard.setData(ClipboardData(text: _text));
  }

  void openAssociatedDictionaryItem(JapaneseTextToken token) {
    if (token.associatedDictionaryItems!.isEmpty) return;
    if (token.associatedDictionaryItems!.length == 1) {
      if (token.associatedDictionaryItems![0] is Vocab) {
        _navigationService.navigateTo(
          Routes.vocabView,
          arguments: VocabViewArguments(
            vocab: token.associatedDictionaryItems![0] as Vocab,
          ),
        );
      } else {
        _navigationService.navigateTo(
          Routes.properNounView,
          arguments: ProperNounViewArguments(
            properNoun: token.associatedDictionaryItems![0] as ProperNoun,
          ),
        );
      }
    } else {
      _bottomSheetService.showCustomSheet(
        variant: BottomSheetType.dictionaryItemsBottom,
        data: token.associatedDictionaryItems,
      );
    }
  }

  void copyToken(JapaneseTextToken token) {
    // Get writing from token
    final buffer = StringBuffer();
    for (var pair in token.rubyTextPairs) {
      buffer.write(pair.writing);
    }
    if (token.trailing != null) {
      for (var trailing in token.trailing!) {
        for (var pair in trailing.rubyTextPairs) {
          buffer.write(pair.writing);
        }
      }
    }

    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: buffer.toString()));

    if (!_snackbarService.isSnackbarOpen) {
      _snackbarService.showSnackbar(
        message: '$buffer copied to clipboard',
        duration: const Duration(seconds: 1),
      );
    }
  }

  Future<void> navigateToOcr(bool cameraStart) async {
    final result =
        await _navigationService.navigateToOcrView(cameraStart: cameraStart);

    if (result == null) return;

    analyzeText(result);
  }

  Future<void> openHistory() async {
    final response = await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.textAnalysisHistoryBottom,
      data: (
        _dictionaryService.getTextAnalysisHistory(),
        _dictionaryService.deleteTextAnalysisHistoryItem,
      ),
    );

    if (response?.data == null) return;

    _dictionaryService.deleteTextAnalysisHistoryItem(response!.data);
    analyzeText(response.data.analysisText);
  }
}

enum TextAnalysisState {
  editing,
  loading,
  viewing,
}
