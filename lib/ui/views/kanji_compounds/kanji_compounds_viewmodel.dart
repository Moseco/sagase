import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiCompoundsViewModel extends FutureViewModel {
  final _navigationService = locator<NavigationService>();
  final _dictionaryService = locator<DictionaryService>();

  final Kanji kanji;

  late List<Vocab> vocabList;

  KanjiCompoundsViewModel(this.kanji);

  @override
  Future<void> futureToRun() async {
    vocabList = await _dictionaryService.getVocabUsingKanji(kanji.kanji);

    List<Vocab> onlyKanji = [];
    List<Vocab> inPrimaryWriting = [];
    List<Vocab> other = [];

    for (var vocab in vocabList) {
      // Sort by where in compound kanji appears
      if (vocab.writings![0].writing == kanji.kanji) {
        onlyKanji.add(vocab);
      } else if (vocab.writings![0].writing.contains(kanji.kanji)) {
        inPrimaryWriting.add(vocab);
      } else {
        other.add(vocab);
      }
    }

    vocabList = onlyKanji + inPrimaryWriting + other;
  }

  void navigateToVocab(Vocab vocab) {
    _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
  }
}
