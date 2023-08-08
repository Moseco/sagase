import 'package:async/async.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/datamodels/search_history_item.dart';
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
  final _dialogService = locator<DialogService>();

  String _searchString = '';
  String get searchString => _searchString;
  List<DictionaryItem>? searchResult;

  CancelableOperation<List<DictionaryItem>>? _searchOperation;

  bool _showHandWriting = false;
  bool get showHandWriting => _showHandWriting;

  List<String> _handWritingResult = [];
  List<String> get handWritingResult => _handWritingResult;

  List<SearchHistoryItem> searchHistory = [];
  SearchHistoryItem? _currentSearchHistoryItem;

  SearchFilter _searchFilter = SearchFilter.vocab;

  SearchViewModel() {
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    searchHistory = await _isarService.getSearchHistory();
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

  void searchOnChange(String value, {bool allowSkip = true}) {
    String stringToSearch = value.trim();
    // Prevent duplicate searches
    if (stringToSearch == _searchString && allowSkip) return;
    _searchString = stringToSearch;

    if (_searchOperation != null) _searchOperation!.cancel();

    if (_searchString.isNotEmpty) {
      _searchOperation = CancelableOperation.fromFuture(
        _isarService.searchDictionary(_searchString, _searchFilter),
      );

      _searchOperation!.value.then((value) {
        searchResult = value;
        _searchOperation = null;
        notifyListeners();
      });

      if (_currentSearchHistoryItem == null) {
        _currentSearchHistoryItem = SearchHistoryItem()
          ..searchQuery = _searchString
          ..timestamp = DateTime.now();
        searchHistory.insert(0, _currentSearchHistoryItem!);
        _isarService.setSearchHistoryItem(_currentSearchHistoryItem!);
      } else if (!_currentSearchHistoryItem!.searchQuery
          .startsWith(_searchString)) {
        searchHistory[0].searchQuery = _searchString;
        _isarService.setSearchHistoryItem(_currentSearchHistoryItem!);
      }
    } else {
      _currentSearchHistoryItem = null;
      searchResult = null;
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

  void searchHistoryItemSelected(SearchHistoryItem item) {
    // Remove the selected one form the list
    searchHistory.remove(item);
    // Update in database
    _isarService.deleteSearchHistoryItem(item);
    // Do the actual search
    searchOnChange(item.searchQuery);
  }

  void searchHistoryItemDeleted(SearchHistoryItem item) {
    // Remove the selected one form the list
    searchHistory.remove(item);
    // Update in database
    _isarService.deleteSearchHistoryItem(item);
    notifyListeners();
  }

  void clearSearchHistory() {
    searchHistory.clear();
    _currentSearchHistoryItem = null;
    notifyListeners();
  }

  Future<void> setSearchFilter() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.searchFilter,
      data: _searchFilter,
      barrierDismissible: true,
    );

    if (response?.data != null) {
      // Redo search if filter was changed
      bool redoSearch = _searchFilter != response!.data;
      _searchFilter = response.data;
      if (redoSearch) searchOnChange(_searchString, allowSkip: false);
    }
  }

  void navigateToTextAnalysis() {
    _navigationService.navigateTo(Routes.textAnalysisView);
  }
}
