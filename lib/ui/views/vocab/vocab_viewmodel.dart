import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/utils/constants.dart' show kanjiRegExp;
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class VocabViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();

  final Vocab vocab;

  final List<Kanji> kanjiList = [];
  bool _kanjiLoaded = false;
  bool get kanjiLoaded => _kanjiLoaded;

  VocabViewModel(this.vocab) {
    // Get list of kanji to be loaded during initialize function
    List<String> kanjiStrings = [];
    for (var pair in vocab.kanjiReadingPairs) {
      if (pair.kanjiWritings == null) continue;
      for (var kanjiWriting in pair.kanjiWritings!) {
        final foundKanjiList = kanjiRegExp.allMatches(kanjiWriting.kanji);
        for (var foundKanji in foundKanjiList) {
          if (kanjiStrings.contains(foundKanji[0]!)) continue;
          kanjiStrings.add(foundKanji[0]!);
          kanjiList.add(Kanji()..kanji = foundKanji[0]!);
        }
      }
    }
  }

  Future<void> initialize() async {
    // Load kanji from database that were found during class constructor
    for (int i = 0; i < kanjiList.length; i++) {
      final kanji = await _isarService.getKanji(kanjiList[i].kanji);
      if (kanji != null) {
        kanjiList[i] = kanji;
      }
    }

    _kanjiLoaded = true;
    notifyListeners();
  }

  void navigateToKanji(Kanji kanji) {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }
}
