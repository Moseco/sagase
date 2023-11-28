import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetInfoViewModel extends FutureViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _isarService = locator<IsarService>();

  final FlashcardSet flashcardSet;

  // Information about when flashcards are due
  // index 0-6 is days of the week starting from today
  // last index is cards due afterwards
  List<int>? upcomingDueFlashcards;
  // Information about the length of the due date for flashcards
  // 0 : new flashcards
  // 1 : flashcards due within 1 week
  // 2 : flashcards due in 2-4 weeks
  // 3 : flashcards due in 1-2 months
  // 4 : flashcards due in 3+ months
  List<double> flashcardIntervalCounts = [0, 0, 0, 0, 0];
  // Top challenging flashcards
  List<DictionaryItem> challengingFlashcards = [];

  FlashcardSetInfoViewModel(this.flashcardSet);

  @override
  Future<void> futureToRun() async {
    // Add all vocab and kanji ids to sets and then load to prevent duplicates
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
    final flashcards = (await _isarService.getVocabList(vocabSet.toList()))
            .cast<DictionaryItem>() +
        (await _isarService.getKanjiList(kanjiSet.toList()))
            .cast<DictionaryItem>();

    // Exit if nothing available
    if (flashcards.isEmpty) {
      await _dialogService.showDialog(
        title: 'No flashcards',
        description: 'Add lists to the flashcard set to view performance.',
        buttonTitle: 'Exit',
        barrierDismissible: true,
      );

      _navigationService.back();

      return;
    }

    // Go through and assemble data
    // Make sure there are only day differences
    final today = DateTime.parse(DateTime.now().toInt().toString());
    upcomingDueFlashcards = List<int>.filled(8, 0);
    for (var flashcard in flashcards) {
      if (_getSpacedRepetitionData(flashcard)?.dueDate != null) {
        // Upcoming due count
        upcomingDueFlashcards![(DateTime.parse(
                    _getSpacedRepetitionData(flashcard)!.dueDate!.toString())
                .difference(today)
                .inDays)
            .clamp(0, 7)]++;

        // Interval count
        if (_getSpacedRepetitionData(flashcard)!.interval <= 7) {
          flashcardIntervalCounts[1]++;
        } else if (_getSpacedRepetitionData(flashcard)!.interval <= 28) {
          flashcardIntervalCounts[2]++;
        } else if (_getSpacedRepetitionData(flashcard)!.interval <= 56) {
          flashcardIntervalCounts[3]++;
        } else {
          flashcardIntervalCounts[4]++;
        }

        // Challenging flashcards
        if (_getSpacedRepetitionData(flashcard)!.totalAnswers > 4 &&
            _getSpacedRepetitionData(flashcard)!.wrongAnswerRate >= 0.25) {
          bool addToEnd = true;
          for (int i = 0; i < challengingFlashcards.length; i++) {
            if (_getSpacedRepetitionData(flashcard)!.wrongAnswerRate >
                _getSpacedRepetitionData(challengingFlashcards[i])!
                    .wrongAnswerRate) {
              challengingFlashcards.insert(i, flashcard);
              addToEnd = false;
              break;
            }
          }
          if (addToEnd && challengingFlashcards.length < 10) {
            challengingFlashcards.add(flashcard);
          }
          if (challengingFlashcards.length > 10) {
            challengingFlashcards.removeLast();
          }
        }
      } else {
        flashcardIntervalCounts[0]++;
      }
    }

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

  // Convenience function for getting the correct spaced repetition data
  SpacedRepetitionData? _getSpacedRepetitionData(DictionaryItem item) {
    return switch (flashcardSet.frontType) {
      FrontType.japanese => item.spacedRepetitionData,
      FrontType.english => item.spacedRepetitionDataEnglish,
    };
  }
}
