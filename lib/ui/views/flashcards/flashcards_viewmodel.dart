import 'dart:collection';
import 'dart:math';

import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final FlashcardSet flashcardSet;

  late final Random _random;

  List<DictionaryItem>? allFlashcards;
  final List<DictionaryItem> activeFlashcards = [];
  final List<DictionaryItem> dueFlashcards = [];
  final List<DictionaryItem> freshFlashcards = [];

  bool get initialLoading => allFlashcards == null;

  // Use this bool instead of flashcardSet variable because a spaced
  // repetition set can switch to random when out of due words
  bool _usingSpacedRepetition = true;
  bool get usingSpacedRepetition => _usingSpacedRepetition;

  int _initialDueFlashcardCount = 0;
  int get initialDueFlashcardCount => _initialDueFlashcardCount;
  bool _answeringDueFlashcards = false;
  bool get answeringDueFlashcards => _answeringDueFlashcards;

  final ListQueue<_UndoItem> _undoList = ListQueue<_UndoItem>();
  bool get canUndo => _undoList.isNotEmpty;

  FlashcardsViewModel(this.flashcardSet, {int? randomSeed})
      : _random = Random(randomSeed);

  Future<void> initialize() async {
    // Update flashcard set to update timestamp
    _isarService.updateFlashcardSet(flashcardSet);

    _usingSpacedRepetition = flashcardSet.usingSpacedRepetition;
    // Load all vocab and kanji and add to maps to avoid duplicates
    await flashcardSet.predefinedDictionaryListLinks.load();
    await flashcardSet.myDictionaryListLinks.load();

    Map<int, Vocab> vocabMap = {};
    Map<String, Kanji> kanjiMap = {};

    // Get predefined list vocab and kanji
    for (int i = 0;
        i < flashcardSet.predefinedDictionaryListLinks.length;
        i++) {
      await flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .vocabLinks
          .load();
      await flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .kanjiLinks
          .load();

      for (var vocab in flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .vocabLinks) {
        vocabMap[vocab.id] = vocab;
      }
      for (var kanji in flashcardSet.predefinedDictionaryListLinks
          .elementAt(i)
          .kanjiLinks) {
        kanjiMap[kanji.kanji] = kanji;
      }
    }

    // Get my list vocab and kanji
    for (int i = 0; i < flashcardSet.myDictionaryListLinks.length; i++) {
      await flashcardSet.myDictionaryListLinks.elementAt(i).vocabLinks.load();
      await flashcardSet.myDictionaryListLinks.elementAt(i).kanjiLinks.load();

      for (var vocab
          in flashcardSet.myDictionaryListLinks.elementAt(i).vocabLinks) {
        vocabMap[vocab.id] = vocab;
      }
      for (var kanji
          in flashcardSet.myDictionaryListLinks.elementAt(i).kanjiLinks) {
        kanjiMap[kanji.kanji] = kanji;
      }
    }

    // Merge vocab and kanji lists
    allFlashcards = vocabMap.values.toList().cast<DictionaryItem>() +
        kanjiMap.values.toList().cast<DictionaryItem>();

    // If using spaced repetition get due words and not started words
    if (_usingSpacedRepetition) {
      int todayAsInt = DateTime.now().toInt();
      for (var item in allFlashcards!) {
        if (item is Vocab) {
          if (item.spacedRepetitionData == null) {
            freshFlashcards.add(item);
          } else if (item.spacedRepetitionData!.dueDate <= todayAsInt) {
            dueFlashcards.add(item);
          }
        } else {
          if ((item as Kanji).spacedRepetitionData == null) {
            freshFlashcards.add(item);
          } else if (item.spacedRepetitionData!.dueDate <= todayAsInt) {
            dueFlashcards.add(item);
          }
        }
      }
      _initialDueFlashcardCount = dueFlashcards.length;
      _answeringDueFlashcards = true;
    }

    // If have no flashcards tell user and exit
    if (allFlashcards!.isEmpty) {
      await _dialogService.showDialog(
        title: 'No flashcards',
        description: 'Add lists to the flashcard set to practice.',
        buttonTitle: 'Exit',
        barrierDismissible: true,
      );

      _navigationService.back();
    } else {
      await _prepareFlashcards(initial: true);
    }
  }

  Future<void> answerFlashcard(FlashcardAnswer answer) async {
    if (activeFlashcards.isEmpty) return;
    // Remove current flashcard from active list
    final currentFlashcard = activeFlashcards.removeAt(0);
    // Add to the undo list
    _undoList.add(_UndoItem(
      currentFlashcard,
      currentFlashcard.spacedRepetitionData,
    ));

    if (usingSpacedRepetition) {
      if (answer == FlashcardAnswer.repeat) {
        // Put current flashcard at 10th or end of the active flashcard list
        activeFlashcards.insert(
          min(9, activeFlashcards.length),
          currentFlashcard,
        );
        notifyListeners();
      } else if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard at 10th or end of the active flashcard list
        activeFlashcards.insert(
          min(9, activeFlashcards.length),
          currentFlashcard,
        );
        notifyListeners();
        // Only get new spaced repetition date if flashcard has previous data
        if (currentFlashcard.spacedRepetitionData != null) {
          currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
            answer.index,
            currentFlashcard.spacedRepetitionData!,
          );
          // Update in database
          await _isarService.updateSpacedRepetitionData(currentFlashcard);
        }
      } else {
        // Get new spaced repetition date and use enum index as argument
        currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
          answer.index,
          currentFlashcard.spacedRepetitionData ??
              SpacedRepetitionData.initialData(),
        );

        notifyListeners();
        // Update in database
        await _isarService.updateSpacedRepetitionData(currentFlashcard);
      }
    } else {
      if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard at 10th or end of the active flashcard list
        activeFlashcards.insert(
          min(9, activeFlashcards.length),
          currentFlashcard,
        );
      }
      notifyListeners();
    }

    // Limit undo list to 10
    if (_undoList.length > 10) {
      _undoList.removeFirst();
    }

    if (activeFlashcards.isEmpty) await _prepareFlashcards();
  }

  Future<void> _prepareFlashcards({bool initial = false}) async {
    if (_usingSpacedRepetition) {
      // Add due cards
      activeFlashcards.addAll(dueFlashcards);
      dueFlashcards.clear();

      // If active flashcards is still empty then try to add fresh flashcards
      if (activeFlashcards.isEmpty) {
        activeFlashcards.addAll(freshFlashcards);
        freshFlashcards.clear();
        _answeringDueFlashcards = false;
      }

      // Randomize active flashcards
      activeFlashcards.shuffle(_random);

      // If active flashcards is still empty then the user is finished with today's spaced repetition
      // Ask if they want to continue using random order
      if (activeFlashcards.isEmpty) {
        final response = await _dialogService.showDialog(
          title: 'Finished!',
          description:
              'You have completed all flashcards due today. Would you like to continue using random order?',
          buttonTitle: 'Continue',
          cancelTitle: 'Exit',
          barrierDismissible: false,
        );

        if (response!.confirmed) {
          _usingSpacedRepetition = false;
          _prepareFlashcards(initial: true);
        } else {
          _navigationService.back();
        }
        return;
      }
    } else {
      // If initial call, add all flashcards to active list and clear undo list
      if (initial) {
        activeFlashcards.addAll(allFlashcards!);
        activeFlashcards.shuffle(_random);
        _undoList.clear();
      }

      // If active flashcards is empty, ask user if they want to restart
      if (activeFlashcards.isEmpty) {
        final response = await _dialogService.showDialog(
          title: 'Finished!',
          description:
              'You have completed all flashcards. Would you like to restart?',
          buttonTitle: 'Restart',
          cancelTitle: 'Exit',
          barrierDismissible: false,
        );

        if (response!.confirmed) {
          _prepareFlashcards(initial: true);
        } else {
          _navigationService.back();
        }
        return;
      }
    }

    notifyListeners();
  }

  void undo() {
    if (_undoList.isEmpty) return;

    // Current card to go back to
    final current = _undoList.removeLast();

    // Go through the first 10 elements in the active list and
    // remove the same flashcard if present
    int limit = min(10, activeFlashcards.length);
    for (int i = 0; i < limit; i++) {
      if (current.flashcard == activeFlashcards[i]) {
        activeFlashcards.removeAt(i);
        break;
      }
    }

    // Put flashcard at the front of active list with the previous data
    activeFlashcards.insert(0, current.flashcard);
    current.flashcard.spacedRepetitionData = current.previousData;

    notifyListeners();

    // Update in database with old data
    _isarService.updateSpacedRepetitionData(current.flashcard);
  }

  SpacedRepetitionData _calculateSpacedRepetition(
    int quality,
    SpacedRepetitionData currentData,
  ) {
    late int interval;
    late int repetitions;
    late double easeFactor;
    if (quality >= 2) {
      switch (currentData.repetitions) {
        case 0:
          interval = quality == 2
              ? _sharedPreferencesService.getInitialCorrectInterval()
              : _sharedPreferencesService.getInitialVeryCorrectInterval();
          break;
        case 1:
          interval = 2 * quality == 2
              ? _sharedPreferencesService.getInitialCorrectInterval()
              : _sharedPreferencesService.getInitialVeryCorrectInterval();
          break;
        default:
          interval = (currentData.interval * currentData.easeFactor).floor();
          break;
      }

      repetitions = currentData.repetitions + 1;
    } else {
      interval = 0;
      repetitions = 0;
      easeFactor = currentData.easeFactor;
    }

    easeFactor = currentData.easeFactor +
        (0.1 - (3 - quality) * (0.08 + (3 - quality) * 0.02));

    if (easeFactor < 1.3) {
      easeFactor = 1.3;
    }

    return SpacedRepetitionData()
      ..interval = interval
      ..repetitions = repetitions
      ..easeFactor = easeFactor
      ..dueDate = DateTime.now().add(Duration(days: interval)).toInt();
  }

  void back() {
    _navigationService.back();
  }

  void openFlashcardItem() async {
    if (activeFlashcards.isEmpty) return;

    if (activeFlashcards[0] is Vocab) {
      _navigationService.navigateTo(
        Routes.vocabView,
        arguments: VocabViewArguments(vocab: activeFlashcards[0] as Vocab),
      );
    } else {
      _navigationService.navigateTo(
        Routes.kanjiView,
        arguments: KanjiViewArguments(kanji: activeFlashcards[0] as Kanji),
      );
    }
  }

  void openFlashcardSetInfo() async {
    _navigationService.navigateTo(
      Routes.flashcardSetInfoView,
      arguments: FlashcardSetInfoViewArguments(flashcardSet: flashcardSet),
    );
  }
}

enum FlashcardAnswer {
  wrong,
  repeat,
  correct,
  veryCorrect,
}

class _UndoItem {
  final DictionaryItem flashcard;
  final SpacedRepetitionData? previousData;

  const _UndoItem(
    this.flashcard,
    this.previousData,
  );
}
