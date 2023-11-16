import 'package:flutter/services.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiRadicalViewModel extends FutureViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final KanjiRadical kanjiRadical;

  List<KanjiRadical>? variants;

  List<Kanji>? kanjiWithRadical;

  bool get strokeDiagramStartExpanded =>
      _sharedPreferencesService.getStrokeDiagramStartExpanded();

  KanjiRadicalViewModel(this.kanjiRadical) {
    // If radical has variants, add temporary versions for smoother loading
    if (kanjiRadical.variants != null) {
      variants = [];
      for (var radicalString in kanjiRadical.variants!) {
        variants!.add(
          KanjiRadical()
            ..radical = radicalString
            ..strokeCount = 0
            ..position = KanjiRadicalPosition.none,
        );
      }
    }
  }

  @override
  Future<void> futureToRun() async {
    if (kanjiRadical.variants != null) {
      // Load variants and replace temporary versions
      for (int i = 0; i < kanjiRadical.variants!.length; i++) {
        final radical =
            await _isarService.getKanjiRadical(kanjiRadical.variants![i]);
        if (radical != null) variants![i] = radical;
      }

      rebuildUi();
    }

    kanjiWithRadical =
        await _isarService.getKanjiWithRadical(kanjiRadical.radical);
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
        title: 'Kanji Using ${kanjiRadical.radical}',
        kanjiList: kanjiWithRadical!,
      ),
    );
  }

  void copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snackbarService.showSnackbar(
      message: 'Copied $text to clipboard',
      duration: const Duration(seconds: 1),
    );
  }

  void setStrokeDiagramStartExpanded(bool value) {
    _sharedPreferencesService.setStrokeDiagramStartExpanded(value);
  }
}
