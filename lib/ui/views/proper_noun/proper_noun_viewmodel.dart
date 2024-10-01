import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/utils/constants.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class ProperNounViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _mecabService = locator<MecabService>();

  final ProperNoun properNoun;

  List<dynamic> get kanjiList => isBusy ? _kanjiStringList : _kanjiList;
  late final List<String> _kanjiStringList;
  late final List<Kanji> _kanjiList;

  ProperNounViewModel(this.properNoun) {
    // Get list of kanji to be loaded during initialize function
    Set<String> kanjiStringSet = {};
    if (properNoun.writing != null) {
      final foundKanjiList = kanjiRegExp.allMatches(properNoun.writing!);
      for (var foundKanji in foundKanjiList) {
        kanjiStringSet.add(foundKanji[0]!);
      }
    }
    _kanjiStringList = kanjiStringSet.toList();
  }

  @override
  Future<void> futureToRun() async {
    // Load kanji from database that were found during class constructor
    _kanjiList = await _dictionaryService
        .getKanjiList(_kanjiStringList.map((e) => e.kanjiCodePoint()).toList());
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }

  List<RubyTextPair> getRubyTextPairs(String writing, String reading) {
    return _mecabService.createRubyTextPairs(writing, reading);
  }
}
