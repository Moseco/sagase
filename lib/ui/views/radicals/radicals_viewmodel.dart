import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class RadicalsViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();

  List<Radical>? radicals;

  RadicalSorting _radicalSorting = RadicalSorting.all;
  RadicalSorting get radicalSorting => _radicalSorting;

  @override
  Future<void> futureToRun() async {
    radicals = await _dictionaryService.getAllRadicals();
  }

  Future<void> handleSortingChanged(RadicalSorting sorting) async {
    if (_radicalSorting == sorting) return;
    _radicalSorting = sorting;
    radicals = null;
    rebuildUi();
    switch (_radicalSorting) {
      case RadicalSorting.all:
        radicals = await _dictionaryService.getAllRadicals();
        break;
      case RadicalSorting.classic:
        radicals = await _dictionaryService.getClassicRadicals();
        break;
      case RadicalSorting.important:
        radicals = await _dictionaryService.getImportantRadicals();
        break;
    }

    rebuildUi();
  }

  Future<void> openRadical(Radical radical) async {
    // If selected radical is a variant, load the parent and open it instead
    Radical? radicalToOpen;
    if (radical.variantOf != null) {
      radicalToOpen = await _dictionaryService.getRadical(radical.variantOf!);
    }
    radicalToOpen ??= radical;

    _navigationService.navigateTo(
      Routes.radicalView,
      arguments: RadicalViewArguments(radical: radicalToOpen),
    );
  }
}

enum RadicalSorting {
  all,
  classic,
  important,
}
