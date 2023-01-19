import 'package:async/async.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/ui/views/home/home_viewmodel.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class SearchViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _digitalInkService = locator<DigitalInkService>();
  final _snackbarService = locator<SnackbarService>();

  String _searchString = '';
  String get searchString => _searchString;
  List<DictionaryItem> _searchResult = [];
  List<DictionaryItem> get searchResult => _searchResult;

  CancelableOperation<List<DictionaryItem>>? _searchOperation;

  bool _showHandWriting = false;
  bool get showHandWriting => _showHandWriting;

  List<String> _handWritingResult = [];
  List<String> get handWritingResult => _handWritingResult;

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
    String stringToSearch = value.trim();
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

  void toggleHandWriting() {
    if (!_digitalInkService.ready) {
      _snackbarService.showSnackbar(
        message:
            'Hand writing detection is setting up. Please try again later.',
      );
      return;
    }
    _showHandWriting = !showHandWriting;
    handWritingResult.clear();
    locator<HomeViewModel>().setShowNavigationBar(!_showHandWriting);
    notifyListeners();
  }

  Future<void> recognizeWriting(Ink ink) async {
    _handWritingResult = await _digitalInkService.recognizeWriting(ink);
    notifyListeners();
  }
}
