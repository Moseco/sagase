import 'dart:collection';
import 'dart:math';

import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' show kanjiRegExp;

class FlashcardsViewModel extends FutureViewModel {
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

  @override
  Future<void> futureToRun() async {
    // If flashcard set timestamp is previous day, reset flashcards completed counts
    if (flashcardSet.timestamp.isDifferentDay(DateTime.now())) {
      flashcardSet.flashcardsCompletedToday = 0;
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

    // Add all vocab and kanji ids to maps and then load to prevent duplicates
    Set<int> vocabSet = {};
    Set<int> kanjiSet = {};

    final predefinedLists = await _isarService.getPredefinedDictionaryLists(
      flashcardSet.predefinedDictionaryLists,
    );
    for (var list in predefinedLists) {
      for (var vocab in list.vocab) {
        vocabSet.add(vocab);
      }
      for (var kanji in list.kanji) {
        kanjiSet.add(kanji);
      }
    }

    final myLists = await _isarService.getMyDictionaryLists(
      flashcardSet.myDictionaryLists,
    );
    for (var list in myLists) {
      for (var vocab in list.vocab) {
        vocabSet.add(vocab);
      }
      for (var kanji in list.kanji) {
        kanjiSet.add(kanji);
      }
    }

    // Merge vocab and kanji lists
    allFlashcards = (await _isarService.getVocabList(vocabSet.toList()))
            .cast<DictionaryItem>() +
        (await _isarService.getKanjiList(kanjiSet.toList()))
            .cast<DictionaryItem>();

    // If have no flashcards tell user and exit
    if (allFlashcards!.isEmpty) {
      await _dialogService.showDialog(
        title: 'No flashcards',
        description: 'Add lists to the flashcard set to practice.',
        buttonTitle: 'Exit',
        barrierDismissible: true,
      );

      _navigationService.back();

      return;
    }

    // Go through flashcards and associate flashcards that would have the same front
    if (flashcardSet.frontType == FrontType.japanese) {
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
    }

    // If using spaced repetition get due cards and not started cards
    if (_usingSpacedRepetition) {
      int todayAsInt = DateTime.now().toInt();
      for (var item in allFlashcards!) {
        if (_getSpacedRepetitionData(item) == null) {
          newFlashcards.add(item);
        } else if (_getSpacedRepetitionData(item)!.dueDate! <= todayAsInt) {
          dueFlashcards.add(item);
        }
      }
      // Set initial due flashcard count and add flashcards completed today
      _initialDueFlashcardCount =
          dueFlashcards.length + flashcardSet.flashcardsCompletedToday;
      _answeringDueFlashcards = true;
    }

    await _prepareFlashcards(initial: true);
  }

  Future<void> answerFlashcard(FlashcardAnswer answer) async {
    if (activeFlashcards.isEmpty) return;
    // Remove current flashcard from active list
    final currentFlashcard = activeFlashcards.removeAt(0);
    // Add to the undo list
    _undoList.add(_UndoItem(
      currentFlashcard,
      _getSpacedRepetitionData(currentFlashcard),
    ));

    if (usingSpacedRepetition) {
      if (answer == FlashcardAnswer.repeat) {
        // Put current flashcard at a set amount or end of the active flashcard list
        activeFlashcards.insert(
          min(
            _sharedPreferencesService.getFlashcardDistance() - 1,
            activeFlashcards.length,
          ),
          currentFlashcard,
        );
        notifyListeners();
      } else if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard at a set amount or end of the active flashcard list
        activeFlashcards.insert(
          min(
            _sharedPreferencesService.getFlashcardDistance() - 1,
            activeFlashcards.length,
          ),
          currentFlashcard,
        );
        notifyListeners();
        // Only modify spaced repetition data if flashcard has previous data
        if (_getSpacedRepetitionData(currentFlashcard) != null) {
          // If answering a new card decrease the initial counter
          if (_getSpacedRepetitionData(currentFlashcard)!.dueDate == null) {
            _setSpacedRepetitionData(
              currentFlashcard,
              _getSpacedRepetitionData(currentFlashcard)!
                  .copyWithInitialCorrectCount(-1),
            );
          } else {
            // Not new card, get new spaced repetition data
            _setSpacedRepetitionData(
              currentFlashcard,
              _calculateSpacedRepetition(
                answer.index,
                _getSpacedRepetitionData(currentFlashcard)!,
              ),
            );
            // Update in database
            await _isarService.updateSpacedRepetitionData(currentFlashcard);
          }
        }
      } else if (answer == FlashcardAnswer.correct) {
        _setSpacedRepetitionData(
          currentFlashcard,
          (_getSpacedRepetitionData(currentFlashcard) ?? SpacedRepetitionData())
              .copyWithInitialCorrectCount(1),
        );
        // If answering not new card or have answered new card correctly a set number of times, get new spaced repetition data
        if (_getSpacedRepetitionData(currentFlashcard)!.dueDate != null ||
            _getSpacedRepetitionData(currentFlashcard)!.initialCorrectCount >=
                _sharedPreferencesService
                    .getFlashcardCorrectAnswersRequired()) {
          // If completing a new card, increase new flashcard count
          if (_getSpacedRepetitionData(currentFlashcard)!.dueDate == null) {
            flashcardSet.newFlashcardsCompletedToday++;
          }
          // Increase flashcards completed today and update in database
          flashcardSet.flashcardsCompletedToday++;
          _isarService.updateFlashcardSet(flashcardSet, updateTimestamp: false);
          // Get new spaced repetition date and use enum index as argument
          _setSpacedRepetitionData(
            currentFlashcard,
            _calculateSpacedRepetition(
              answer.index,
              _getSpacedRepetitionData(currentFlashcard)!,
            ),
          );

          notifyListeners();
          // Update in database
          await _isarService.updateSpacedRepetitionData(currentFlashcard);
        } else {
          // Not enough initial correct answers for new cards, reinsert to list
          // at a set amount or end of the list
          activeFlashcards.insert(
            min(
              _sharedPreferencesService.getFlashcardDistance() - 1,
              activeFlashcards.length,
            ),
            currentFlashcard,
          );
          notifyListeners();
        }
      } else {
        // Very correct answer
        // If completing a new card, increase new flashcard count
        if (_getSpacedRepetitionData(currentFlashcard)?.dueDate == null) {
          flashcardSet.newFlashcardsCompletedToday++;
        }
        // Increase flashcards completed today and update in database
        flashcardSet.flashcardsCompletedToday++;
        _isarService.updateFlashcardSet(flashcardSet, updateTimestamp: false);
        // Get new spaced repetition date and use enum index as argument
        _setSpacedRepetitionData(
          currentFlashcard,
          _calculateSpacedRepetition(
            answer.index,
            _getSpacedRepetitionData(currentFlashcard) ??
                SpacedRepetitionData(),
          ),
        );

        notifyListeners();
        // Update in database
        await _isarService.updateSpacedRepetitionData(currentFlashcard);
      }
    } else {
      if (answer == FlashcardAnswer.wrong) {
        // Put current flashcard at a set amount or end of the active flashcard list
        activeFlashcards.insert(
          min(
            _sharedPreferencesService.getFlashcardDistance() - 1,
            activeFlashcards.length,
          ),
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
        if (flashcardsToAdd < 0) flashcardsToAdd = 0;
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

    // Go through the first x elements in the active list and
    // remove the same flashcard if present
    int limit = min(
      _sharedPreferencesService.getFlashcardDistance(),
      activeFlashcards.length,
    );
    for (int i = 0; i < limit; i++) {
      if (current.flashcard == activeFlashcards[i]) {
        activeFlashcards.removeAt(i);
        break;
      }
    }

    // If undoing a newly completed card, decrease flashcards completed counts
    if (current.previousData?.dueDate == null &&
        _getSpacedRepetitionData(current.flashcard)?.dueDate != null) {
      flashcardSet.flashcardsCompletedToday--;
      flashcardSet.newFlashcardsCompletedToday--;
      _isarService.updateFlashcardSet(flashcardSet, updateTimestamp: false);
    }
    // If undoing a not new card, decrease count
    if (current.previousData?.dueDate != null) {
      flashcardSet.flashcardsCompletedToday--;
      _isarService.updateFlashcardSet(flashcardSet, updateTimestamp: false);
    }

    // Put flashcard at the front of active list with the previous data
    activeFlashcards.insert(0, current.flashcard);
    _setSpacedRepetitionData(current.flashcard, current.previousData);

    notifyListeners();

    // Update in database with old data
    // If old data was keeping track of initial correct count for new cards, set to null
    if (current.previousData != null && current.previousData!.dueDate == null) {
      return _isarService.setSpacedRepetitionDataToNull(
          current.flashcard, flashcardSet.frontType);
    } else {
      return _isarService.updateSpacedRepetitionData(current.flashcard);
    }
  }

  String? getNewInterval(FlashcardAnswer answer) {
    if (!_sharedPreferencesService.getShowNewInterval()) return null;
    if (activeFlashcards.isEmpty) return '';

    if (answer == FlashcardAnswer.wrong) {
      if (_getSpacedRepetitionData(activeFlashcards[0]) == null) {
        return '~';
      } else {
        return '0';
      }
    } else if (answer == FlashcardAnswer.repeat) {
      return '~';
    } else {
      int interval = _calculateSpacedRepetition(
        answer.index,
        _getSpacedRepetitionData(activeFlashcards[0]) ?? SpacedRepetitionData(),
      ).interval;

      // Format interval
      if (interval < 28) {
        return '${interval}d';
      } else if (interval < 365) {
        return '${(interval / 28).toStringAsFixed(1)}m';
      } else {
        return '${(interval / 365).toStringAsFixed(1)}y';
      }
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

  // Convenience function for getting the correct spaced repetition data
  SpacedRepetitionData? _getSpacedRepetitionData(DictionaryItem item) {
    return switch (flashcardSet.frontType) {
      FrontType.japanese => item.spacedRepetitionData,
      FrontType.english => item.spacedRepetitionDataEnglish,
    };
  }

  // Convenience function for setting the correct spaced repetition data
  void _setSpacedRepetitionData(
    DictionaryItem item,
    SpacedRepetitionData? data,
  ) {
    switch (flashcardSet.frontType) {
      case FrontType.japanese:
        item.spacedRepetitionData = data;
        break;
      case FrontType.english:
        item.spacedRepetitionDataEnglish = data;
        break;
    }
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
