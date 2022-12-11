import 'dart:math';

import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  final FlashcardSet flashcardSet;

  late final Random _random;

  List<DictionaryItem>? allFlashcards;
  final List<DictionaryItem> _activeFlashcards = [];
  List<DictionaryItem> get activeFlashcards => _activeFlashcards;
  final List<DictionaryItem> dueFlashcards = [];
  final List<DictionaryItem> freshFlashcards = [];

  bool get initialLoading => allFlashcards == null;

  // Use this bool instead of flashcardSet variable because a spaced
  // repetition set can switch to random when out of due words
  bool _usingSpacedRepetition = true;
  bool get usingSpacedRepetition => _usingSpacedRepetition;

  // Used to keep track of spaced repetition flashcards that are in
  // the rotation (answered correctly at least once).
  int _nonFreshFlashcardCount = 0;
  int get nonFreshFlashcardCount => _nonFreshFlashcardCount;
  int _initialDueFlashcardCount = 0;
  int get initialDueFlashcardCount => _initialDueFlashcardCount;
  int _dueFlashcardCount = 0;
  int get dueFlashcardCount => _dueFlashcardCount;

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
      _nonFreshFlashcardCount = allFlashcards!.length - freshFlashcards.length;
      _initialDueFlashcardCount = dueFlashcards.length;
      _dueFlashcardCount = dueFlashcards.length;
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
    final currentFlashcard = _activeFlashcards.removeAt(0);

    if (usingSpacedRepetition) {
      if (answer == FlashcardAnswer.repeat) {
        // Put current flashcard to the end of the active flashcard list
        _activeFlashcards.insert(_activeFlashcards.length, currentFlashcard);
        notifyListeners();
      } else if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard to the end of the active flashcard list
        _activeFlashcards.insert(_activeFlashcards.length, currentFlashcard);
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
        // If current card has not been answered previously, increase completed counter
        _dueFlashcardCount--;
        if (currentFlashcard.spacedRepetitionData == null) {
          _nonFreshFlashcardCount++;
        }
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
        // Put current flashcard to the end of the active flashcard list
        _activeFlashcards.insert(_activeFlashcards.length, currentFlashcard);
      }
      notifyListeners();
    }

    if (_activeFlashcards.isEmpty) await _prepareFlashcards();
  }

  Future<void> _prepareFlashcards({bool initial = false}) async {
    if (_usingSpacedRepetition) {
      // Check if need to add cards to active list
      while (_activeFlashcards.length < 10 && dueFlashcards.isNotEmpty) {
        final flashcard =
            dueFlashcards.removeAt(_random.nextInt(dueFlashcards.length));
        _activeFlashcards.insert(_activeFlashcards.length, flashcard);
      }
      // If active flashcards is still empty and try to add fresh flashcards
      if (_activeFlashcards.isEmpty) {
        while (_activeFlashcards.length < 10 && freshFlashcards.isNotEmpty) {
          final flashcard =
              freshFlashcards.removeAt(_random.nextInt(freshFlashcards.length));
          _activeFlashcards.insert(_activeFlashcards.length, flashcard);
        }
      }
      // If active flashcards is still empty then the user is finished with today's spaced repetition
      // Ask if they want to continue using random order
      if (_activeFlashcards.isEmpty) {
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
          return;
        }
      }
    } else {
      // If initial call, just add all flashcards to active list
      if (initial) {
        _activeFlashcards.addAll(allFlashcards!);
        _activeFlashcards.shuffle(_random);
      }

      // If active flashcards is empty, ask user if they want to restart
      if (_activeFlashcards.isEmpty) {
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
          return;
        }
      }
    }

    notifyListeners();
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
          interval = 1;
          break;
        case 1:
          interval = 2;
          break;
        default:
          interval = (currentData.interval * currentData.easeFactor).floor();
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
    if (_activeFlashcards[0] is Vocab) {
      _navigationService.navigateTo(
        Routes.vocabView,
        arguments: VocabViewArguments(vocab: _activeFlashcards[0] as Vocab),
      );
    } else {
      _navigationService.navigateTo(
        Routes.kanjiView,
        arguments: KanjiViewArguments(kanji: _activeFlashcards[0] as Kanji),
      );
    }
  }
}

enum FlashcardAnswer {
  wrong,
  repeat,
  correct,
  veryCorrect,
}
