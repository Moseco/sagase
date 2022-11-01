import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DictionaryListViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  final DictionaryList list;

  bool _loading = true;
  bool get loading => _loading;

  DictionaryListViewModel(this.list) {
    _loadList();
  }

  Future<void> _loadList() async {
    if (!list.vocab.isLoaded) await list.vocab.load();
    if (!list.kanji.isLoaded) await list.kanji.load();
    _loading = false;
    notifyListeners();
  }

  void navigateToVocab(Vocab vocab) {
    _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
  }

  void navigateToKanji(Kanji kanji) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }
}
