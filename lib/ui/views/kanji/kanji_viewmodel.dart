import 'package:sagase/datamodels/kanji.dart';
import 'package:stacked/stacked.dart';

class KanjiViewModel extends BaseViewModel {
  final Kanji kanji;

  bool _linksLoaded = false;
  bool get linksLoaded => _linksLoaded;

  KanjiViewModel(this.kanji);

  Future<void> initialize() async {
    // Load variants
    await kanji.variants.load();

    // Load compounds
    await kanji.compounds.load();

    _linksLoaded = true;
    notifyListeners();
  }
}
