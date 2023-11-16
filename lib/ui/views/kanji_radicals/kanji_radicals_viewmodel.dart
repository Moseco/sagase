import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiRadicalsViewModel extends FutureViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();

  List<KanjiRadical>? kanjiRadicals;

  RadicalSorting _radicalSorting = RadicalSorting.all;
  RadicalSorting get radicalSorting => _radicalSorting;

  @override
  Future<void> futureToRun() async {
    kanjiRadicals = await _isarService.getAllKanjiRadicals();
    rebuildUi();
  }

  Future<void> handleSortingChanged(RadicalSorting sorting) async {
    if (_radicalSorting == sorting) return;
    _radicalSorting = sorting;
    kanjiRadicals = null;
    rebuildUi();
    switch (_radicalSorting) {
      case RadicalSorting.all:
        kanjiRadicals = await _isarService.getAllKanjiRadicals();
        break;
      case RadicalSorting.classic:
        kanjiRadicals = await _isarService.getClassicKanjiRadicals();
        break;
      case RadicalSorting.important:
        kanjiRadicals = await _isarService.getImportantKanjiRadicals();
        break;
    }

    rebuildUi();
  }

  Future<void> openKanjiRadical(KanjiRadical kanjiRadical) async {
    // If selected radical is a variant, load the parent and open it instead
    KanjiRadical? radicalToOpen;
    if (kanjiRadical.variantOf != null) {
      radicalToOpen =
          await _isarService.getKanjiRadical(kanjiRadical.variantOf!);
    }
    radicalToOpen ??= kanjiRadical;

    _navigationService.navigateTo(
      Routes.kanjiRadicalView,
      arguments: KanjiRadicalViewArguments(kanjiRadical: radicalToOpen),
    );
  }
}

enum RadicalSorting {
  all,
  classic,
  important,
}
