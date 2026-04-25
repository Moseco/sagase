import 'package:async/async.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';
import 'package:image_picker/image_picker.dart';
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

  CancelableOperation<(List<DictionaryItem>, bool)>? _searchOperation;

  InputMode _inputMode = InputMode.text;
  InputMode get inputMode => _inputMode;

  List<String> _handWritingResult = [];
  List<String> get handWritingResult => _handWritingResult;

  List<Radical> _radicals = [];
  List<Radical> get radicals => _radicals;

  final Set<String> _selectedRadicals = {};
  Set<String> get selectedRadicals => _selectedRadicals;

  List<Kanji> _radicalKanjiResult = [];
  List<Kanji> get radicalKanjiResult => _radicalKanjiResult;

  Set<String> _viableRadicals = {};
  Set<String> get viableRadicals => _viableRadicals;

  List<SearchHistoryItem> searchHistory = [];
  SearchHistoryItem? _currentSearchHistoryItem;

  SearchFilter _searchFilter = SearchFilter.vocab;
  SearchFilter get searchFilter => _searchFilter;

  void Function()? _onRequestKeyboardFocus;
  set onRequestKeyboardFocus(void Function() callback) {
    _onRequestKeyboardFocus = callback;
  }

  bool _promptAnalysis = false;
  bool get promptAnalysis => _promptAnalysis;

  XFile? _image;
  XFile? get image => _image;

  bool _ocrError = false;
  bool get ocrError => _ocrError;

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
    if (stringToSearch == _searchString && allowSkip) return;
    _searchString = stringToSearch;

    _searchOperation?.cancel();

    if (_searchString.isNotEmpty) {
      _searchOperation = CancelableOperation.fromFuture(
        _search(_searchString, _searchFilter),
      );

      _searchOperation!.then((value) {
        searchResult = value.$1;
        _promptAnalysis = value.$2;
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
      _promptAnalysis = false;
      searchResult = null;
      notifyListeners();
    }
  }

  Future<(List<DictionaryItem>, bool)> _search(
    String query,
    SearchFilter filter,
  ) async {
    final results = await _dictionaryService.searchDictionary(query, filter);

    bool promptAnalysis = false;

    if (filter == SearchFilter.vocab &&
        results.isEmpty &&
        !_kanaKit.isRomaji(query)) {
      final tokens = _mecabService.parseText(query);

      for (final token in tokens) {
        final tokenResults =
            await _dictionaryService.getVocabByJapaneseTextToken(token);

        if (tokenResults.isNotEmpty) {
          results.add(tokenResults[0]);
        }
      }

      promptAnalysis = results.isNotEmpty;
    }

    return (results, promptAnalysis);
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

  void setInputMode(InputMode mode) {
    if (_inputMode == mode) return;

    if (mode == InputMode.handWriting) {
      if (!_digitalInkService.ready) {
        if (!_snackbarService.isSnackbarOpen) {
          _snackbarService.showSnackbar(
            message:
                'Hand writing detection is setting up. Please try again later.',
          );
        }
        return;
      }

      handWritingResult.clear();
    }

    if (mode == InputMode.radical) {
      _loadRadicals();
    }

    _inputMode = mode;
    _image = null;
    _ocrError = false;
    locator<HomeViewModel>().setShowNavigationBar(mode == InputMode.text);

    rebuildUi();
  }

  Future<void> _loadRadicals() async {
    if (_radicals.isNotEmpty) return;
    _radicals = await _dictionaryService.getClassicRadicals();
    _viableRadicals = _radicals.map((r) => r.radical).toSet();
    rebuildUi();
  }

  Future<void> toggleRadical(String radical) async {
    if (_selectedRadicals.contains(radical)) {
      _selectedRadicals.remove(radical);
    } else {
      if (!_viableRadicals.contains(radical)) return;
      _selectedRadicals.add(radical);
    }

    if (_selectedRadicals.isEmpty) {
      _radicalKanjiResult = [];
      _viableRadicals = _radicals.map((r) => r.radical).toSet();
    } else {
      _radicalKanjiResult = await _dictionaryService
          .getKanjiWithComponents(_selectedRadicals.toList());
      // Viable = any component that appears in at least one result kanji
      final viable = <String>{};
      for (final kanji in _radicalKanjiResult) {
        final components = kanji.components;
        if (components != null) viable.addAll(components);
      }
      _viableRadicals = viable;
    }

    rebuildUi();
  }

  void clearSelectedRadicals() {
    if (_selectedRadicals.isEmpty) return;
    _selectedRadicals.clear();
    _radicalKanjiResult = [];
    _viableRadicals = _radicals.map((r) => r.radical).toSet();
    rebuildUi();
  }

  Future<void> handlePictureTaken(XFile image) async {
    _image = image;
    rebuildUi();
  }

  void handleImageError() {
    _image = null;
    _snackbarService.showSnackbar(message: 'Failed to process image');
    _ocrError = true;
    rebuildUi();
  }

  void handleTextSelected(String text) {
    searchOnChange(text);
  }

  void resetImage() {
    _image = null;
    _ocrError = false;
    rebuildUi();
  }

  void handleNavBarTap() {
    _onRequestKeyboardFocus?.call();
  }
}

enum InputMode {
  text,
  handWriting,
  ocr,
  radical,
}
