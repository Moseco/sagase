import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiRadicalsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();

  List<KanjiRadical>? kanjiRadicals;

  RadicalSorting _radicalSorting = RadicalSorting.all;
  RadicalSorting get radicalSorting => _radicalSorting;

  KanjiRadicalsViewModel() {
    _getRadicals();
  }

  Future<void> _getRadicals() async {
    kanjiRadicals = await _isarService.getAllKanjiRadicals();
    notifyListeners();
  }

  Future<void> handleSortingChanged(RadicalSorting sorting) async {
    if (_radicalSorting == sorting) return;
    _radicalSorting = sorting;
    kanjiRadicals = null;
    notifyListeners();
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

    notifyListeners();
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
