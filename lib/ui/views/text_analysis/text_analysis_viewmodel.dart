import 'package:flutter/services.dart';
import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class TextAnalysisViewModel extends BaseViewModel {
  final _mecabService = locator<MecabService>();
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _bottomSheetService = locator<BottomSheetService>();
  final _snackbarService = locator<SnackbarService>();

  TextAnalysisState _state = TextAnalysisState.editing;
  TextAnalysisState get state => _state;

  String _text = '';
  String get text => _text;

  List<JapaneseTextToken>? tokens;

  TextAnalysisViewModel(String? initialText) {
    if (initialText != null) {
      analyzeText(initialText);
    }
  }

  Future<void> analyzeText(String text) async {
    String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    _text = trimmed;
    _state = TextAnalysisState.loading;
    rebuildUi();

    tokens = _mecabService.parseText(_text);

    // Look up vocab for each token
    for (var token in tokens!) {
      token.associatedVocab =
          await _isarService.getVocabByJapaneseTextToken(token);
    }

    _state = TextAnalysisState.viewing;
    rebuildUi();
  }

  void editText() {
    _state = TextAnalysisState.editing;
    rebuildUi();
  }

  void copyText() {
    Clipboard.setData(ClipboardData(text: _text));
  }

  void openTokenVocab(JapaneseTextToken token) {
    if (token.associatedVocab!.isEmpty) return;
    if (token.associatedVocab!.length == 1) {
      _navigationService.navigateTo(
        Routes.vocabView,
        arguments: VocabViewArguments(vocab: token.associatedVocab![0]),
      );
      return;
    } else {
      _bottomSheetService.showCustomSheet(
        variant: BottomSheetType.selectVocabBottom,
        data: token.associatedVocab,
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

    _snackbarService.showSnackbar(
      message: '$buffer copied to clipboard',
      duration: const Duration(seconds: 1),
    );
  }
}

enum TextAnalysisState {
  editing,
  loading,
  viewing,
}
