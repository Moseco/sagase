import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiListViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  final List<Kanji> kanjiList;

  KanjiListViewModel(this.kanjiList);

  void navigateToKanji(Kanji kanji, int index) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(
        kanji: kanji,
        kanjiListIndex: index,
        kanjiList: kanjiList,
      ),
    );
  }
}
