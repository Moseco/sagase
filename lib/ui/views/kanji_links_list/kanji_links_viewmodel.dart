import 'package:isar/isar.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiLinksViewModel extends BaseViewModel {
  final IsarLinks<Kanji> links;
  final _navigationService = locator<NavigationService>();

  bool _loading = true;
  bool get loading => _loading;

  KanjiLinksViewModel(this.links) {
    _loadLinks();
  }

  Future<void> _loadLinks() async {
    await links.load();
    _loading = false;
    notifyListeners();
  }

  void navigateToKanji(Kanji kanji) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }
}
