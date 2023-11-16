import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanjiCompoundsViewModel extends FutureViewModel {
  final _navigationService = locator<NavigationService>();
  final _isarService = locator<IsarService>();

  final Kanji kanji;

  List<Vocab>? vocabList;

  KanjiCompoundsViewModel(this.kanji);

  @override
  Future<void> futureToRun() async {
    if (kanji.compounds != null) {
      vocabList = await _isarService.getVocabList(kanji.compounds!);
    } else {
      vocabList = [];
    }

    rebuildUi();
  }

  void navigateToVocab(Vocab vocab) {
    _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
  }
}
