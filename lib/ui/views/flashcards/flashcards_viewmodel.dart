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
import 'package:sagase/utils/constants.dart' show kanjiRegExp;

class FlashcardsViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final FlashcardSet flashcardSet;
  FlashcardStartMode? startMode;

  late final Random _random;

  List<DictionaryItem>? allFlashcards;
  final List<DictionaryItem> activeFlashcards = [];
  final List<DictionaryItem> dueFlashcards = [];
  final List<DictionaryItem> newFlashcards = [];

  bool get initialLoading => allFlashcards == null;

  // Use this bool instead of flashcardSet variable because a spaced
  // repetition set can switch to random when out of due cards
  bool _usingSpacedRepetition = true;
  bool get usingSpacedRepetition => _usingSpacedRepetition;

  int _initialDueFlashcardCount = 0;
  int get initialDueFlashcardCount => _initialDueFlashcardCount;
  bool _answeringDueFlashcards = false;
  bool get answeringDueFlashcards => _answeringDueFlashcards;

  final ListQueue<_UndoItem> _undoList = ListQueue<_UndoItem>();
  bool get canUndo => _undoList.isNotEmpty;

  FlashcardsViewModel(
    this.flashcardSet,
    this.startMode, {
    int? randomSeed,
  }) : _random = Random(randomSeed);

  Future<void> initialize() async {
    // If flashcard set timestamp is previous day, reset new flashcard completed count
    if (flashcardSet.timestamp.isDifferentDay(DateTime.now())) {
      flashcardSet.newFlashcardsCompletedToday = 0;
    }
    // Update flashcard set to also update timestamp
    _isarService.updateFlashcardSet(flashcardSet);
    // Set if using spaced repetition
    _usingSpacedRepetition = flashcardSet.usingSpacedRepetition;
    // If not given start mode in constructor, get default start mode
    startMode ??= _sharedPreferencesService.getFlashcardLearningModeEnabled()
        ? FlashcardStartMode.learning
        : FlashcardStartMode.normal;
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

    // Go through flashcards and associate flashcards that would have the same front
    Map<String, List<DictionaryItem>> flashcardMap = {};
    for (var flashcard in allFlashcards!) {
      // Create string that represents the front of a flashcard
      final front = StringBuffer();
      if (flashcard is Vocab) {
        if (flashcard.kanjiReadingPairs[0].kanjiWritings != null) {
          front.write(flashcard.kanjiReadingPairs[0].kanjiWritings![0].kanji);
        }
        if (flashcardSet.vocabShowReading ||
            flashcard.kanjiReadingPairs[0].kanjiWritings == null ||
            (flashcard.isUsuallyKanaAlone() &&
                flashcardSet.vocabShowReadingIfRareKanji)) {
          front.write(flashcard.kanjiReadingPairs[0].readings[0].reading);
        }
      } else {
        front.write((flashcard as Kanji).kanji);
      }

      // Check if similar flashcard already found
      final frontString = front.toString();
      if (flashcardMap.containsKey(frontString)) {
        flashcard.similarFlashcards = [];
        final similarFlashcards = flashcardMap[frontString]!;
        for (var similarFlashcard in similarFlashcards) {
          flashcard.similarFlashcards!.add(similarFlashcard);
          if (similarFlashcard.similarFlashcards == null) {
            similarFlashcard.similarFlashcards = [flashcard];
          } else {
            similarFlashcard.similarFlashcards!.add(flashcard);
          }
        }
        similarFlashcards.add(flashcard);
      } else {
        flashcardMap[frontString] = [flashcard];
      }
    }

    // If using spaced repetition get due cards and not started cards
    if (_usingSpacedRepetition) {
      int todayAsInt = DateTime.now().toInt();
      for (var item in allFlashcards!) {
        if (item is Vocab) {
          if (item.spacedRepetitionData == null) {
            newFlashcards.add(item);
          } else if (item.spacedRepetitionData!.dueDate! <= todayAsInt) {
            dueFlashcards.add(item);
          }
        } else {
          if ((item as Kanji).spacedRepetitionData == null) {
            newFlashcards.add(item);
          } else if (item.spacedRepetitionData!.dueDate! <= todayAsInt) {
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
        // Put current flashcard at 15th or end of the active flashcard list
        activeFlashcards.insert(
          min(14, activeFlashcards.length),
          currentFlashcard,
        );
        notifyListeners();
      } else if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard at 15th or end of the active flashcard list
        activeFlashcards.insert(
          min(14, activeFlashcards.length),
          currentFlashcard,
        );
        notifyListeners();
        // Only modify spaced repetition data if flashcard has previous data
        if (currentFlashcard.spacedRepetitionData != null) {
          // If answering a new card decrease the initial counter
          if (currentFlashcard.spacedRepetitionData!.dueDate == null) {
            currentFlashcard.spacedRepetitionData = currentFlashcard
                .spacedRepetitionData!
                .copyWithInitialCorrectCount(-1);
          } else {
            // Not new card, get new spaced repetition data
            currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
              answer.index,
              currentFlashcard.spacedRepetitionData!,
            );
            // Update in database
            await _isarService.updateSpacedRepetitionData(currentFlashcard);
          }
        }
      } else if (answer == FlashcardAnswer.correct) {
        currentFlashcard.spacedRepetitionData ??= SpacedRepetitionData();
        currentFlashcard.spacedRepetitionData = currentFlashcard
            .spacedRepetitionData!
            .copyWithInitialCorrectCount(1);
        // If answering not new card or have answered new card correctly 3 times, get new spaced repetition data
        if (currentFlashcard.spacedRepetitionData!.dueDate != null ||
            currentFlashcard.spacedRepetitionData!.initialCorrectCount >= 3) {
          // If completing a new card, increase count
          if (currentFlashcard.spacedRepetitionData!.dueDate == null) {
            flashcardSet.newFlashcardsCompletedToday++;
            _isarService.updateFlashcardSet(flashcardSet);
          }
          // Get new spaced repetition date and use enum index as argument
          currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
            answer.index,
            currentFlashcard.spacedRepetitionData!,
          );

          notifyListeners();
          // Update in database
          await _isarService.updateSpacedRepetitionData(currentFlashcard);
        } else {
          // Not enough initial correct answers for new cards, reinsert to list
          // at 15th or end of the list
          activeFlashcards.insert(
            min(14, activeFlashcards.length),
            currentFlashcard,
          );
          notifyListeners();
        }
      } else {
        // Very correct answer
        // If completing a new card, increase count
        if (currentFlashcard.spacedRepetitionData?.dueDate == null) {
          flashcardSet.newFlashcardsCompletedToday++;
          _isarService.updateFlashcardSet(flashcardSet);
        }
        // Get new spaced repetition date and use enum index as argument
        currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
          answer.index,
          currentFlashcard.spacedRepetitionData ?? SpacedRepetitionData(),
        );

        notifyListeners();
        // Update in database
        await _isarService.updateSpacedRepetitionData(currentFlashcard);
      }
    } else {
      if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard at 15th or end of the active flashcard list
        activeFlashcards.insert(
          min(14, activeFlashcards.length),
          currentFlashcard,
        );
      }
      notifyListeners();
    }

    // Limit undo list to 10
    if (_undoList.length > 10) {
      _undoList.removeFirst();
    }

    if (activeFlashcards.isEmpty) {
      await _prepareFlashcards();
    } else if (activeFlashcards[0] is Vocab) {
      _loadVocabFlashcardKanji(activeFlashcards[0] as Vocab);
    }
  }

  Future<void> _prepareFlashcards({bool initial = false}) async {
    if (_usingSpacedRepetition) {
      // Add due cards if not in skip start mode
      if (startMode != FlashcardStartMode.skip) {
        activeFlashcards.addAll(dueFlashcards);
      }
      dueFlashcards.clear();

      // If active flashcards is still empty then try to add new flashcards
      if (activeFlashcards.isEmpty) {
        activeFlashcards.addAll(newFlashcards);
        newFlashcards.clear();
        _answeringDueFlashcards = false;
      } else if (startMode == FlashcardStartMode.learning) {
        // If active list was not empty and in learning mode, add new cards with the due cards
        int flashcardsToAdd = min(
          _sharedPreferencesService.getNewFlashcardsPerDay() -
              flashcardSet.newFlashcardsCompletedToday,
          newFlashcards.length,
        );
        for (int i = 0; i < flashcardsToAdd; i++) {
          activeFlashcards.add(
              newFlashcards.removeAt(_random.nextInt(newFlashcards.length)));
        }
        // Also change initial due flashcard count
        _initialDueFlashcardCount += flashcardsToAdd;
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

    if (activeFlashcards.isNotEmpty && activeFlashcards[0] is Vocab) {
      _loadVocabFlashcardKanji(activeFlashcards[0] as Vocab);
    }
  }

  Future<void> undo() async {
    if (_undoList.isEmpty) return;

    // Current card to go back to
    final current = _undoList.removeLast();

    // Go through the first 15 elements in the active list and
    // remove the same flashcard if present
    int limit = min(15, activeFlashcards.length);
    for (int i = 0; i < limit; i++) {
      if (current.flashcard == activeFlashcards[i]) {
        activeFlashcards.removeAt(i);
        break;
      }
    }

    // If undoing a newly completed card, decrease new flashcard completed count
    if (current.previousData?.dueDate == null &&
        current.flashcard.spacedRepetitionData?.dueDate != null) {
      flashcardSet.newFlashcardsCompletedToday--;
      _isarService.updateFlashcardSet(flashcardSet);
    }

    // Put flashcard at the front of active list with the previous data
    activeFlashcards.insert(0, current.flashcard);
    current.flashcard.spacedRepetitionData = current.previousData;

    notifyListeners();

    // Update in database with old data
    // If old data was keeping track of initial correct count for new cards, set to null
    if (current.previousData != null && current.previousData!.dueDate == null) {
      return _isarService.setSpacedRepetitionDataToNull(current.flashcard);
    } else {
      return _isarService.updateSpacedRepetitionData(current.flashcard);
    }
  }

  String? getNewInterval(FlashcardAnswer answer) {
    if (!_sharedPreferencesService.getShowNewInterval()) return null;
    if (activeFlashcards.isEmpty) return '';

    if (answer == FlashcardAnswer.wrong) {
      if (activeFlashcards[0].spacedRepetitionData == null) {
        return '~';
      } else {
        return '0';
      }
    } else if (answer == FlashcardAnswer.repeat) {
      return '~';
    } else {
      return _calculateSpacedRepetition(
        answer.index,
        activeFlashcards[0].spacedRepetitionData ?? SpacedRepetitionData(),
      ).interval.toString();
    }
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
          interval = 2 *
              (quality == 2
                  ? _sharedPreferencesService.getInitialCorrectInterval()
                  : _sharedPreferencesService.getInitialVeryCorrectInterval());
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

    // Give a slight bump if have a low ease factor for correct answer
    if (quality == 2 && easeFactor < 1.85) easeFactor += 0.15;

    if (easeFactor < 1.3) {
      easeFactor = 1.3;
    }

    // If current repetitions is 0 and answer was incorrect then the previous answer was also incorrect
    // Use previous ease factor so it is not further decreased before a correct answer
    return SpacedRepetitionData()
      ..interval = interval
      ..repetitions = repetitions
      ..easeFactor = currentData.repetitions == 0 && quality == 0
          ? currentData.easeFactor
          : easeFactor
      ..dueDate = DateTime.now().add(Duration(days: interval)).toInt()
      ..totalAnswers = currentData.totalAnswers + 1
      ..totalWrongAnswers =
          currentData.totalWrongAnswers + (quality == 0 ? 1 : 0);
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

  Future<void> _loadVocabFlashcardKanji(Vocab vocab) async {
    // Don't load included kanji again
    if (vocab.includedKanji != null) return;

    vocab.includedKanji = [];
    List<String> kanjiStrings = [];
    if (vocab.kanjiReadingPairs[0].kanjiWritings != null) {
      final foundKanjiList = kanjiRegExp
          .allMatches(vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji);
      for (var foundKanji in foundKanjiList) {
        // Prevent duplicate kanji
        if (kanjiStrings.contains(foundKanji[0]!)) continue;
        kanjiStrings.add(foundKanji[0]!);
        // Load from database
        final kanji = await _isarService.getKanji(foundKanji[0]!);
        if (kanji != null) vocab.includedKanji!.add(kanji);
      }
    }

    notifyListeners();
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

enum FlashcardStartMode {
  normal,
  learning,
  skip,
}
