import 'dart:collection';
import 'dart:math';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' show kanjiRegExp;

class FlashcardsViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _sharedPreferencesService = locator<SharedPreferencesService>();

  final FlashcardSet flashcardSet;
  FlashcardStartMode? startMode;

  late final FlashcardSetReport flashcardSetReport;

  late final Random _random;

  List<DictionaryItem>? allFlashcards;
  final List<DictionaryItem> activeFlashcards = [];
  final List<DictionaryItem> dueFlashcards = [];
  final List<DictionaryItem> startedFlashcards = [];
  final List<DictionaryItem> newFlashcards = [];

  // Use this bool instead of flashcardSet variable because a spaced
  // repetition set can switch to random when out of due cards
  bool _usingSpacedRepetition = true;
  bool get usingSpacedRepetition => _usingSpacedRepetition;

  int _initialDueFlashcardCount = 0;
  int get initialDueFlashcardCount => _initialDueFlashcardCount;
  int _newFlashcardsAdded = 0;
  int get newFlashcardsAdded => _newFlashcardsAdded;
  int _initialNewFlashcardsCompleted = 0;
  int get initialNewFlashcardsCompleted => _initialNewFlashcardsCompleted;
  bool _answeringDueFlashcards = false;
  bool get answeringDueFlashcards => _answeringDueFlashcards;

  final ListQueue<_UndoItem> _undoList = ListQueue<_UndoItem>();
  bool get canUndo => _undoList.isNotEmpty;

  late DateTime sessionDateTime;

  bool? _showDetailedProgress;
  bool get showDetailedProgress {
    _showDetailedProgress ??=
        _sharedPreferencesService.getShowDetailedProgress();
    return _showDetailedProgress!;
  }

  bool _reportDialogShown = false;

  FlashcardsViewModel(
    this.flashcardSet,
    this.startMode, {
    int? randomSeed,
  }) : _random = Random(randomSeed);

  @override
  Future<void> futureToRun() async {
    sessionDateTime = DateTime.now();
    int daysSincePreviousSession =
        sessionDateTime.difference(flashcardSet.timestamp).inDays;
    // Get or create flashcard set report for today and set streak accordingly
    final recentFlashcardSetReport =
        await _dictionaryService.getRecentFlashcardSetReport(flashcardSet);
    if (recentFlashcardSetReport == null) {
      flashcardSetReport = await _dictionaryService.createFlashcardSetReport(
          flashcardSet, sessionDateTime.toInt());
    } else if (sessionDateTime.toInt() == recentFlashcardSetReport.date) {
      flashcardSetReport = recentFlashcardSetReport;
    } else if (sessionDateTime.subtract(const Duration(days: 1)).toInt() ==
        recentFlashcardSetReport.date) {
      flashcardSet.streak++;
      flashcardSetReport = await _dictionaryService.createFlashcardSetReport(
          flashcardSet, sessionDateTime.toInt());
    } else {
      flashcardSet.streak = 0;
      flashcardSetReport = await _dictionaryService.createFlashcardSetReport(
          flashcardSet, sessionDateTime.toInt());
    }
    // Update flashcard set to also update timestamp
    _dictionaryService.updateFlashcardSet(flashcardSet);
    // Set if using spaced repetition
    _usingSpacedRepetition = flashcardSet.usingSpacedRepetition;
    // If not given start mode in constructor, get default start mode
    startMode ??= _sharedPreferencesService.getFlashcardLearningModeEnabled()
        ? FlashcardStartMode.learning
        : FlashcardStartMode.normal;

    // Get all the flashcards
    allFlashcards =
        await _dictionaryService.getFlashcardSetFlashcards(flashcardSet);

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
          if (flashcard.writings != null) {
            front.write(flashcard.writings![0].writing);
          }
          if (flashcardSet.vocabShowReading ||
              flashcard.writings == null ||
              (flashcard.isUsuallyKanaAlone() &&
                  flashcardSet.vocabShowReadingIfRareKanji)) {
            front.write(flashcard.readings[0].reading);
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
      int todayAsInt = sessionDateTime.toInt();
      for (var item in allFlashcards!) {
        if (item.spacedRepetitionData == null) {
          newFlashcards.add(item);
        } else if (item.spacedRepetitionData!.dueDate == null) {
          startedFlashcards.add(item);
        } else if (item.spacedRepetitionData!.dueDate! <= todayAsInt) {
          dueFlashcards.add(item);
        }
      }

      // If user has not done flashcards for several days and has a large
      // amount due offer to spread them out over next 2 weeks
      if (daysSincePreviousSession > 4 && dueFlashcards.length > 300) {
        await _spreadOutDueFlashcards();
      }

      // Set initial due flashcard count and add flashcards completed today
      _initialDueFlashcardCount = dueFlashcards.length +
          flashcardSetReport.dueFlashcardsCompleted +
          flashcardSetReport.newFlashcardsCompleted;
      _initialNewFlashcardsCompleted =
          flashcardSetReport.newFlashcardsCompleted;
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
      currentFlashcard.spacedRepetitionData,
    ));

    if (usingSpacedRepetition) {
      if (answer == FlashcardAnswer.repeat) {
        // Reinsert current flashcard
        activeFlashcards.insert(
          min(
            _sharedPreferencesService.getFlashcardDistance() - 1,
            activeFlashcards.length,
          ),
          currentFlashcard,
        );
        notifyListeners();
      } else if (answer == FlashcardAnswer.wrong) {
        // Reinsert current flashcard
        activeFlashcards.insert(
          min(
            _sharedPreferencesService.getFlashcardDistance() - 1,
            activeFlashcards.length,
          ),
          currentFlashcard,
        );
        notifyListeners();
        // Only modify spaced repetition data if flashcard has previous data
        if (currentFlashcard.spacedRepetitionData != null) {
          // First add to report wrong count if first wrong answer for not new flashcard
          if (currentFlashcard.spacedRepetitionData!.dueDate != null &&
              currentFlashcard.spacedRepetitionData!.interval != 0) {
            flashcardSetReport.dueFlashcardsGotWrong++;
            _dictionaryService.setFlashcardSetReport(flashcardSetReport);
          }
          // Get new spaced repetition data
          currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
            answer,
            currentFlashcard.spacedRepetitionData!,
          );
          // Only update in database if completed flashcard
          if (currentFlashcard.spacedRepetitionData!.dueDate != null) {
            await _dictionaryService.setSpacedRepetitionData(
                currentFlashcard.spacedRepetitionData!);
          }
        }
      } else if (answer == FlashcardAnswer.correct) {
        bool isNewFlashcard =
            currentFlashcard.spacedRepetitionData?.dueDate == null;
        currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
          answer,
          currentFlashcard.spacedRepetitionData ??
              SpacedRepetitionData.initial(
                dictionaryItem: currentFlashcard,
                frontType: flashcardSet.frontType,
              ),
        );

        if (currentFlashcard.spacedRepetitionData!.dueDate != null) {
          // Increase appropriate flashcards completed count
          if (isNewFlashcard) {
            flashcardSetReport.newFlashcardsCompleted++;
          } else {
            flashcardSetReport.dueFlashcardsCompleted++;
          }
          _dictionaryService.setFlashcardSetReport(flashcardSetReport);
        } else {
          // New flashcard is not completed, reinsert current flashcard
          activeFlashcards.insert(
            min(
              _sharedPreferencesService.getFlashcardDistance() - 1,
              activeFlashcards.length,
            ),
            currentFlashcard,
          );
        }

        notifyListeners();
        // Update in database
        await _dictionaryService
            .setSpacedRepetitionData(currentFlashcard.spacedRepetitionData!);
      } else {
        // Very correct answer
        // Increase appropriate flashcards completed count
        if (currentFlashcard.spacedRepetitionData?.dueDate == null) {
          flashcardSetReport.newFlashcardsCompleted++;
        } else {
          flashcardSetReport.dueFlashcardsCompleted++;
        }
        _dictionaryService.setFlashcardSetReport(flashcardSetReport);
        // Get new spaced repetition date and use enum index as argument

        currentFlashcard.spacedRepetitionData = _calculateSpacedRepetition(
          answer,
          currentFlashcard.spacedRepetitionData ??
              SpacedRepetitionData.initial(
                dictionaryItem: currentFlashcard,
                frontType: flashcardSet.frontType,
              ),
        );

        notifyListeners();
        // Update in database
        await _dictionaryService
            .setSpacedRepetitionData(currentFlashcard.spacedRepetitionData!);
      }

      // Reload session if different day and past 3am
      // Could happen if flashcards kept open until the next day
      // 3am rule allows for finishing flashcards last minute
      final now = DateTime.now();
      if (sessionDateTime.isDifferentDay(now) &&
          (now.hour > 3 || now.difference(sessionDateTime).inDays > 0)) {
        _reloadSession();
        return;
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
      await _loadVocabFlashcardKanji(activeFlashcards[0] as Vocab);
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
      Future<DialogResponse<dynamic>?>? reportDialogResponse;
      if (activeFlashcards.isEmpty) {
        activeFlashcards.addAll(newFlashcards);
        newFlashcards.clear();
        _answeringDueFlashcards = false;
        // Randomize
        activeFlashcards.shuffle(_random);
        // Add any started flashcards
        activeFlashcards.insertAll(0, startedFlashcards..shuffle(_random));
        startedFlashcards.clear();
        // If finished due flashcards show report report
        if (!_reportDialogShown &&
            !initial &&
            flashcardSetReport.dueFlashcardsCompleted != 0) {
          _reportDialogShown = true;
          reportDialogResponse = _dialogService.showCustomDialog(
            variant: DialogType.flashcardSetReport,
            data: (flashcardSetReport, flashcardSet.streak),
            barrierDismissible: true,
          );
        }
      } else if (startMode == FlashcardStartMode.learning) {
        // If active list was not empty and in learning mode, add new cards with the due cards
        _newFlashcardsAdded = min(
          _sharedPreferencesService.getNewFlashcardsPerDay() -
              flashcardSetReport.newFlashcardsCompleted -
              startedFlashcards.length,
          newFlashcards.length,
        );
        if (_newFlashcardsAdded < 0) _newFlashcardsAdded = 0;
        for (int i = 0; i < _newFlashcardsAdded; i++) {
          activeFlashcards.add(
              newFlashcards.removeAt(_random.nextInt(newFlashcards.length)));
        }
        // Add started length to new flashcards added
        _newFlashcardsAdded += startedFlashcards.length;
        // Also change initial due flashcard count
        _initialDueFlashcardCount += _newFlashcardsAdded;

        // Add started flashcards
        activeFlashcards.addAll(startedFlashcards);
        startedFlashcards.clear();

        // Randomize
        activeFlashcards.shuffle(_random);
      } else {
        activeFlashcards.shuffle(_random);
      }

      // If active flashcards is still empty then the user is finished with today's spaced repetition
      // Ask if they want to continue using random order
      if (activeFlashcards.isEmpty) {
        // Wait for report dialog to finish if being shown
        if (reportDialogResponse != null) {
          await reportDialogResponse;
          _navigationService.back();
          return;
        }
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
      await _loadVocabFlashcardKanji(activeFlashcards[0] as Vocab);
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

    // If undoing a newly completed card, decrease new flashcards completed
    if (current.previousData?.dueDate == null &&
        current.flashcard.spacedRepetitionData?.dueDate != null) {
      flashcardSetReport.newFlashcardsCompleted--;
      _dictionaryService.setFlashcardSetReport(flashcardSetReport);
    }
    // If undoing a not new card and previous answer was correct, decrease count
    if (current.previousData?.dueDate != null &&
        current.previousData!.interval <
            current.flashcard.spacedRepetitionData!.interval) {
      flashcardSetReport.dueFlashcardsCompleted--;
      _dictionaryService.setFlashcardSetReport(flashcardSetReport);
    }
    // If undoing a not new card and previous answer was the first wrong answer, decrease count
    if (current.previousData?.dueDate != null &&
        current.previousData!.interval != 0 &&
        current.flashcard.spacedRepetitionData!.interval == 0) {
      flashcardSetReport.dueFlashcardsGotWrong--;
      _dictionaryService.setFlashcardSetReport(flashcardSetReport);
    }

    // Put flashcard at the front of active list with the previous data
    activeFlashcards.insert(0, current.flashcard);
    current.flashcard.spacedRepetitionData = current.previousData;

    notifyListeners();

    // Update in database with old data
    if (current.previousData == null) {
      return _dictionaryService.deleteSpacedRepetitionData(
          current.flashcard, flashcardSet.frontType);
    } else {
      return _dictionaryService
          .setSpacedRepetitionData(current.flashcard.spacedRepetitionData!);
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
      int interval = _calculateSpacedRepetition(
        answer,
        activeFlashcards[0].spacedRepetitionData ??
            SpacedRepetitionData.initial(
              dictionaryItem: activeFlashcards[0],
              frontType: flashcardSet.frontType,
            ),
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
    FlashcardAnswer answer,
    SpacedRepetitionData currentData,
  ) {
    // Check if completing initial correct requirement for new flashcards
    if (currentData.dueDate == null) {
      if (answer == FlashcardAnswer.wrong) {
        return currentData.copyWith(
          initialCorrectCount: max(0, currentData.initialCorrectCount - 1),
        );
      } else if (answer == FlashcardAnswer.correct &&
          currentData.initialCorrectCount + 1 <
              _sharedPreferencesService.getFlashcardCorrectAnswersRequired()) {
        return currentData.copyWith(
          initialCorrectCount: currentData.initialCorrectCount + 1,
        );
      }
    }

    late int interval;
    late int repetitions;
    late double easeFactor;
    if (answer.index >= FlashcardAnswer.correct.index) {
      switch (currentData.repetitions) {
        case 0:
          interval = answer.index == FlashcardAnswer.correct.index
              ? _sharedPreferencesService.getInitialCorrectInterval()
              : _sharedPreferencesService.getInitialVeryCorrectInterval();
          break;
        case 1:
          interval = currentData.interval +
              (answer.index == FlashcardAnswer.correct.index
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

    if (currentData.repetitions == 0 &&
        answer.index == FlashcardAnswer.wrong.index) {
      // Current repetitions is 0 and answer was wrong then the previous answer was also wrong
      // Use previous ease factor so it is not further decreased before a correct answer
      easeFactor = currentData.easeFactor;
    } else {
      easeFactor = currentData.easeFactor +
          (0.1 - (3 - answer.index) * (0.08 + (3 - answer.index) * 0.02));

      // Give a slight bump if have a low ease factor for correct answer
      if (answer.index == FlashcardAnswer.correct.index && easeFactor < 1.85) {
        easeFactor += 0.15;
      }

      if (easeFactor < 1.3) {
        easeFactor = 1.3;
      }
    }

    return currentData.copyWith(
      interval: interval,
      repetitions: repetitions,
      easeFactor: easeFactor,
      dueDate: sessionDateTime.add(Duration(days: interval)).toInt(),
      totalAnswers: currentData.totalAnswers + 1,
      totalWrongAnswers: currentData.totalWrongAnswers +
          (answer.index == FlashcardAnswer.wrong.index ? 1 : 0),
    );
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

  void openKanji(Kanji kanji) async {
    _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
  }

  Future<void> _loadVocabFlashcardKanji(Vocab vocab) async {
    // Don't load included kanji again
    if (vocab.includedKanji != null) return;

    vocab.includedKanji = [];
    List<String> kanjiStrings = [];
    if (vocab.writings != null) {
      final foundKanjiList = kanjiRegExp.allMatches(vocab.writings![0].writing);
      for (var foundKanji in foundKanjiList) {
        // Prevent duplicate kanji
        if (kanjiStrings.contains(foundKanji[0]!)) continue;
        kanjiStrings.add(foundKanji[0]!);
        // Load from database
        final kanji = await _dictionaryService.getKanji(foundKanji[0]!);
        if (kanji != null) vocab.includedKanji!.add(kanji);
      }
    }

    notifyListeners();
  }

  bool shouldShowTutorial() {
    if (flashcardSet.usingSpacedRepetition) {
      return _sharedPreferencesService.getAndSetTutorialFlashcards();
    } else {
      return false;
    }
  }

  Future<void> _reloadSession() async {
    await _dialogService.showCustomDialog(
      variant: DialogType.info,
      title: 'Reload Flashcards',
      description:
          'This session was started on a previous day so the flashcards need to be reloaded.',
      mainButtonTitle: 'Continue',
      barrierDismissible: true,
    );

    _navigationService.replaceWith(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(
        flashcardSet: flashcardSet,
        startMode: startMode,
      ),
    );
  }

  Future<void> _spreadOutDueFlashcards() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Reduce Due Flashcards?',
      description:
          'It has been several days since you last opened this flashcard set and a lot of due flashcards have pilled up. To help you return to studying some due flashcards can be delayed. Pressing confirm will leave 150 due flashcards for today and spread the rest out over the next 2 weeks.',
      mainButtonTitle: 'Confirm',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      // Show progress indicator dialog
      _dialogService.showCustomDialog(
        variant: DialogType.progressIndicator,
        title: 'Updating Flashcards',
        barrierDismissible: false,
      );

      dueFlashcards.shuffle(_random);
      int flashcardsPerDay = (dueFlashcards.length - 150) ~/ 12;
      for (int i = 1; i < 14; i++) {
        int dueDate = sessionDateTime.add(Duration(days: i)).toInt();
        for (int j = 0;
            j < flashcardsPerDay && dueFlashcards.length > 150;
            j++) {
          await _dictionaryService.setSpacedRepetitionData(
            dueFlashcards
                .removeLast()
                .spacedRepetitionData!
                .copyWith(dueDate: dueDate),
          );
        }
      }

      _dialogService.completeDialog(DialogResponse());
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
