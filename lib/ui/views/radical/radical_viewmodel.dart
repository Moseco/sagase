import 'package:flutter/services.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class RadicalViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final Radical radical;

  List<Radical>? variants;

  List<Kanji>? kanjiWithRadical;

  bool get strokeDiagramStartExpanded =>
      _sharedPreferencesService.getStrokeDiagramStartExpanded();

  RadicalViewModel(this.radical) {
    // If radical has variants, add temporary versions for smoother loading
    if (radical.variants != null) {
      variants = [];
      for (var radicalString in radical.variants!) {
        variants!.add(
          Radical(
            id: 0,
            radical: radicalString,
            strokeCount: 0,
            meaning: '',
            reading: '',
          ),
        );
      }
    }
  }

  @override
  Future<void> futureToRun() async {
    if (radical.variants != null) {
      // Load variants and replace temporary versions
      for (int i = 0; i < radical.variants!.length; i++) {
        variants![i] =
            await _dictionaryService.getRadical(radical.variants![i]);
      }

      rebuildUi();
    }

    kanjiWithRadical =
        await _dictionaryService.getKanjiWithRadical(radical.radical);
    rebuildUi();
  }

  void navigateToKanji(Kanji kanji) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }

  void showAllKanji() {
    _navigationService.navigateTo(
      Routes.kanjiListView,
      arguments: KanjiListViewArguments(
        title: 'Kanji Using ${radical.radical}',
        kanjiList: kanjiWithRadical!,
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snackbarService.showSnackbar(
      message: '$text copied to clipboard',
      duration: const Duration(seconds: 1),
    );
  }

  void setStrokeDiagramStartExpanded(bool value) {
    _sharedPreferencesService.setStrokeDiagramStartExpanded(value);
  }
}
