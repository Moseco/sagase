import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiCompoundsViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  final Kanji kanji;

  List<Vocab>? vocabList;

  KanjiCompoundsViewModel(this.kanji) {
    _loadAndSort();
  }

  Future<void> _loadAndSort() async {
    await kanji.compounds.load();

    List<Vocab> onlyKanji = [];
    List<Vocab> leadingKanji = [];
    List<Vocab> other = [];

    for (var vocab in kanji.compounds) {
      if (vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji == kanji.kanji) {
        onlyKanji.add(vocab);
      } else if (vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji
          .startsWith(kanji.kanji)) {
        leadingKanji.add(vocab);
      } else {
        other.add(vocab);
      }
    }

    vocabList = onlyKanji + leadingKanji + other;
    notifyListeners();
  }

  void navigateToVocab(Vocab vocab) {
    _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
  }
}
