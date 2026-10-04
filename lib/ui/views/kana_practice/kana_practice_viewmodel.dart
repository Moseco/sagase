import 'dart:collection';
import 'dart:math';

import 'package:kana_kit/kana_kit.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class KanaPracticeViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final _kanaKit = const KanaKit();

  final Random _random;

  late Set<KanaScript> _scripts;
  late Set<KanaType> _types;

  late bool _typingEnabled;
  bool get typingEnabled => _typingEnabled;

  bool _showingAnswer = false;
  bool get showingAnswer => _showingAnswer;

  List<Kana> _allFlashcards = [];
  List<Kana> get allFlashcards => _allFlashcards;
  final List<Kana> activeFlashcards = [];

  final ListQueue<Kana> _undoList = ListQueue<Kana>();
  bool get canUndo => _undoList.isNotEmpty;

  KanaPracticeViewModel({int? randomSeed}) : _random = Random(randomSeed) {
    _scripts = _sharedPreferencesService.getKanaPracticeScripts();
    _types = _sharedPreferencesService.getKanaPracticeTypes();
    _typingEnabled = _sharedPreferencesService.getKanaPracticeTypingEnabled();
    _startSession();
  }

  void _startSession() {
    _allFlashcards = Kana.getKana(scripts: _scripts, types: _types);
    activeFlashcards
      ..clear()
      ..addAll(_allFlashcards)
      ..shuffle(_random);
    _undoList.clear();
    _showingAnswer = false;
    notifyListeners();
  }

  void toggleTypingEnabled() {
    _typingEnabled = !_typingEnabled;
    _sharedPreferencesService.setKanaPracticeTypingEnabled(_typingEnabled);
    _showingAnswer = false;
    _undoList.clear();
    notifyListeners();
  }

  Future<void> submitAnswer(String answer) async {
    if (activeFlashcards.isEmpty) return;

    if (_showingAnswer) {
      _showingAnswer = false;
      return answerFlashcard(KanaPracticeAnswer.wrong);
    }

    if (_isCorrectAnswer(activeFlashcards[0], answer)) {
      return answerFlashcard(KanaPracticeAnswer.correct);
    }

    _showingAnswer = true;
    notifyListeners();
  }

  bool _isCorrectAnswer(Kana kana, String answer) {
    answer = answer.trim().toLowerCase();
    if (answer.isEmpty) return false;
    if (answer == kana.romaji) return true;
    return _kanaKit.toHiragana(answer) == _kanaKit.toHiragana(kana.kana);
  }

  Future<void> answerFlashcard(KanaPracticeAnswer answer) async {
    if (activeFlashcards.isEmpty) return;

    final currentFlashcard = activeFlashcards.removeAt(0);
    _undoList.add(currentFlashcard);

    if (answer == KanaPracticeAnswer.wrong) {
      activeFlashcards.insert(
        min(
          _sharedPreferencesService.getFlashcardDistance() - 1,
          activeFlashcards.length,
        ),
        currentFlashcard,
      );
    }
    notifyListeners();

    if (_undoList.length > 10) {
      _undoList.removeFirst();
    }

    if (activeFlashcards.isEmpty) {
      final response = await _dialogService.showCustomDialog(
        variant: DialogType.confirmation,
        title: 'Finished!',
        description: 'You have completed all kana. Would you like to restart?',
        mainButtonTitle: 'Restart',
        secondaryButtonTitle: 'Exit',
        barrierDismissible: false,
      );

      if (response != null && response.confirmed) {
        _startSession();
      } else {
        _navigationService.back();
      }
    }
  }

  void undo() {
    if (_undoList.isEmpty) return;

    final current = _undoList.removeLast();
    activeFlashcards.remove(current);
    activeFlashcards.insert(0, current);

    notifyListeners();
  }

  Future<bool> editSelection() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.kanaPracticeSelection,
      data: (_scripts, _types),
      barrierDismissible: true,
    );

    if (response?.data == null) return false;

    final (Set<KanaScript> scripts, Set<KanaType> types) = response!.data;
    if (scripts.isEmpty || types.isEmpty) return false;

    _scripts = scripts;
    _types = types;
    _sharedPreferencesService.setKanaPracticeScripts(scripts);
    _sharedPreferencesService.setKanaPracticeTypes(types);

    _startSession();

    return true;
  }
}

enum KanaPracticeAnswer {
  wrong,
  correct,
}
