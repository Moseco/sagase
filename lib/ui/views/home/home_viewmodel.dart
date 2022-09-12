import 'package:async/async.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class HomeViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();

  String _searchString = '';
  List<DictionaryItem> _searchResult = [];
  List<DictionaryItem> get searchResult => _searchResult;

  CancelableOperation<List<DictionaryItem>>? _searchOperation;

  void navigateToDev() {
    _navigationService.navigateTo(Routes.devView);
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

  void searchOnChange(String value) {
    String stringToSearch = value.toLowerCase().trim();
    // Prevent duplicate searches
    if (stringToSearch == _searchString) return;
    _searchString = stringToSearch;

    if (_searchString.isNotEmpty) {
      if (_searchOperation != null) {
        _searchOperation!.cancel();
      }

      _searchOperation = CancelableOperation.fromFuture(
        _isarService.searchDictionary(_searchString),
      );

      _searchOperation!.value.then((value) {
        _searchResult = value;
        _searchOperation = null;
        notifyListeners();
      });
    } else {
      _searchResult.clear();
      notifyListeners();
    }
  }
}
