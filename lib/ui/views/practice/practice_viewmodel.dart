import 'dart:collection';
import 'dart:math';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

/// Base view model for practice tools that go through a deck of items.
///
/// Wrong answers are put back into the deck based on the flashcard distance
/// setting and the session ends once every item has been answered correctly.
/// Typed answers are checked with [isCorrectAnswer] and a wrong typed answer
/// shows the correct answer until the user submits again. A correct typed
/// answer does the same if [showAnswerWhenCorrect] is true.
abstract class PracticeViewModel<T> extends BaseViewModel {
  final navigationService = locator<NavigationService>();
  final dialogService = locator<DialogService>();
  final sharedPreferencesService = locator<SharedPreferencesService>();

  final Random random;

  bool _showingAnswer = false;
  bool get showingAnswer => _showingAnswer;

  bool _answerCorrect = false;
  bool get answerCorrect => _answerCorrect;

  List<T> _allItems = [];
  List<T> get allItems => _allItems;
  final List<T> activeItems = [];

  final ListQueue<T> _undoList = ListQueue<T>();
  bool get canUndo => _undoList.isNotEmpty;

  PracticeViewModel({int? randomSeed}) : random = Random(randomSeed);

  /// Creates the items for a new session.
  List<T> createItems();

  /// Returns whether [answer] is a correct typed answer for [item].
  bool isCorrectAnswer(T item, String answer);

  /// Description shown in the dialog when all items are completed.
  String get finishedDescription;

  /// Whether a correct typed answer shows the answer before moving on.
  bool get showAnswerWhenCorrect => false;

  void startSession() {
    _allItems = createItems();
    activeItems
      ..clear()
      ..addAll(_allItems)
      ..shuffle(random);
    _undoList.clear();
    _showingAnswer = false;
    notifyListeners();
  }

  void resetAnswerState() {
    _showingAnswer = false;
    _undoList.clear();
  }

  Future<void> submitAnswer(String answer) async {
    if (activeItems.isEmpty) return;

    if (_showingAnswer) {
      _showingAnswer = false;
      return answerItem(_answerCorrect);
    }

    _answerCorrect = isCorrectAnswer(activeItems[0], answer);
    if (_answerCorrect && !showAnswerWhenCorrect) {
      return answerItem(true);
    }

    _showingAnswer = true;
    notifyListeners();
  }

  void retryAnswer() {
    if (!_showingAnswer || _answerCorrect) return;
    _showingAnswer = false;
    notifyListeners();
  }

  Future<void> answerItem(bool correct) async {
    if (activeItems.isEmpty) return;

    final current = activeItems.removeAt(0);
    _undoList.add(current);

    if (!correct) {
      activeItems.insert(
        min(
          sharedPreferencesService.getFlashcardDistance() - 1,
          activeItems.length,
        ),
        current,
      );
    }
    notifyListeners();

    if (_undoList.length > 10) {
      _undoList.removeFirst();
    }

    if (activeItems.isEmpty) {
      final response = await dialogService.showCustomDialog(
        variant: DialogType.confirmation,
        title: 'Finished!',
        description: finishedDescription,
        mainButtonTitle: 'Restart',
        secondaryButtonTitle: 'Exit',
        barrierDismissible: false,
      );

      if (response != null && response.confirmed) {
        startSession();
      } else {
        navigationService.back();
      }
    }
  }

  void undo() {
    if (_undoList.isEmpty) return;

    final current = _undoList.removeLast();
    activeItems.remove(current);
    activeItems.insert(0, current);

    notifyListeners();
  }
}
