import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/kanji_radical.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiRadicalViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();

  final KanjiRadical kanjiRadical;

  List<KanjiRadical>? variants;

  KanjiRadicalViewModel(this.kanjiRadical) {
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    if (kanjiRadical.variants == null) return;

    variants = [];
    for (var radicalString in kanjiRadical.variants!) {
      final radical = await _isarService.getKanjiRadical(radicalString);
      if (radical != null) {
        variants!.add(radical);
      }
    }

    notifyListeners();
  }

  void navigateToKanji(Kanji kanji) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }

  void showAllKanji() {
    _navigationService.navigateTo(
      Routes.kanjiLinksView,
      arguments: KanjiLinksViewArguments(
        title: kanjiRadical.radical,
        links: kanjiRadical.kanjiWithRadical,
      ),
    );
  }
}
