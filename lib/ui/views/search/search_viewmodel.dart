import 'package:async/async.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/ui/views/home/home_viewmodel.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class SearchViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _digitalInkService = locator<DigitalInkService>();
  final _snackbarService = locator<SnackbarService>();
  final _dialogService = locator<DialogService>();
  final _mecabService = locator<MecabService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final _kanaKit = const KanaKit();

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
  SearchFilter get searchFilter => _searchFilter;

  bool _promptAnalysis = false;
  bool get promptAnalysis => _promptAnalysis;

  @override
  Future<void> futureToRun() async {
    await loadSearchHistory();
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
        _dictionaryService.searchDictionary(_searchString, _searchFilter),
      );

      _searchOperation!.value.then((value) async {
        searchResult = value;
        _searchOperation = null;
        _promptAnalysis = false;

        // If no results found for vocab search, try to analyze
        if (_searchFilter == SearchFilter.vocab &&
            searchResult!.isEmpty &&
            (_kanaKit.isJapanese(stringToSearch) ||
                _kanaKit.isMixed(stringToSearch))) {
          final analysisResult = _mecabService.parseText(stringToSearch);
          if (analysisResult.length == 1) {
            // Try to search using the identified token (could be conjugated word)
            searchResult = await _dictionaryService.searchDictionary(
                analysisResult[0].base, _searchFilter);
          } else if (analysisResult.isNotEmpty) {
            // Search could be for sentence/phrase, offer to analyze
            _promptAnalysis = true;
          }
        }

        notifyListeners();
      });

      if (_currentSearchHistoryItem == null) {
        _currentSearchHistoryItem = SearchHistoryItem(
          id: searchHistory.isEmpty ? 0 : searchHistory[0].id + 1,
          searchText: _searchString,
        );
        searchHistory.insert(0, _currentSearchHistoryItem!);
        _dictionaryService.setSearchHistoryItem(_currentSearchHistoryItem!);
      } else if (!_currentSearchHistoryItem!.searchText
          .startsWith(_searchString)) {
        _currentSearchHistoryItem =
            _currentSearchHistoryItem!.copyWith(searchText: _searchString);
        searchHistory[0] = _currentSearchHistoryItem!;
        _dictionaryService.setSearchHistoryItem(_currentSearchHistoryItem!);
      }
    } else {
      _currentSearchHistoryItem = null;
      searchResult = null;
      notifyListeners();
    }
  }

  void toggleHandWriting() {
    if (!_digitalInkService.ready) {
      if (!_snackbarService.isSnackbarOpen) {
        _snackbarService.showSnackbar(
          message:
              'Hand writing detection is setting up. Please try again later.',
        );
      }
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
    _dictionaryService.deleteSearchHistoryItem(item);
    // Do the actual search
    searchOnChange(item.searchText);
  }

  void searchHistoryItemDeleted(SearchHistoryItem item) {
    // Remove the selected one form the list
    searchHistory.remove(item);
    // Update in database
    _dictionaryService.deleteSearchHistoryItem(item);
    notifyListeners();
  }

  Future<void> loadSearchHistory() async {
    searchHistory = await _dictionaryService.getSearchHistory();
    _currentSearchHistoryItem = null;
    notifyListeners();
  }

  Future<void> setSearchFilter() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.searchFilter,
      data: (_searchFilter, _sharedPreferencesService.getProperNounsEnabled()),
      barrierDismissible: true,
    );

    if (response?.data != null) {
      // Redo search if filter was changed
      bool redoSearch = _searchFilter != response!.data;
      _searchFilter = response.data;
      if (redoSearch) searchOnChange(_searchString, allowSkip: false);
    }
  }

  void navigateToTextAnalysis({String? text}) {
    if (text != null && _currentSearchHistoryItem != null) {
      searchHistory.removeAt(0);
      _dictionaryService.deleteSearchHistoryItem(_currentSearchHistoryItem!);
      _currentSearchHistoryItem = null;
    }

    _navigationService.navigateTo(
      Routes.textAnalysisView,
      arguments: TextAnalysisViewArguments(initialText: text),
    );
  }

  void navigateToProperNoun(ProperNoun properNoun) {
    _navigationService.navigateTo(
      Routes.properNounView,
      arguments: ProperNounViewArguments(properNoun: properNoun),
    );
  }
}
