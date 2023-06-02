import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetInfoViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();

  final FlashcardSet flashcardSet;

  bool get loading => upcomingDueFlashcards.isEmpty;

  // Information about when flashcards are due
  // index 0-6 is days of the week starting from today
  // last index is cards due afterwards
  List<int> upcomingDueFlashcards = [];
  // Information about the length of the due date for flashcards
  // 0 : new flashcards
  // 1 : flashcards due within 1 week
  // 2 : flashcards due in 2-4 weeks
  // 3 : flashcards due in 1-2 months
  // 4 : flashcards due in 3+ months
  List<double> flashcardIntervalCounts = [0, 0, 0, 0, 0];
  // Top challenging flashcards
  List<DictionaryItem> challengingFlashcards = [];

  FlashcardSetInfoViewModel(this.flashcardSet) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Load all vocab and kanji and add to maps to avoid duplicates
    await flashcardSet.predefinedDictionaryListLinks.load();
    await flashcardSet.myDictionaryListLinks.load();

    Map<int, Vocab> vocabMap = {};
    Map<String, Kanji> kanjiMap = {};

    // Get predefined lists vocab and kanji
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

    // Get my lists vocab and kanji
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
    final flashcards = vocabMap.values.toList().cast<DictionaryItem>() +
        kanjiMap.values.toList().cast<DictionaryItem>();

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
      if (flashcard.spacedRepetitionData != null) {
        // Upcoming due count
        upcomingDueFlashcards[
            (DateTime.parse(flashcard.spacedRepetitionData!.dueDate!.toString())
                    .difference(today)
                    .inDays)
                .clamp(0, 7)]++;

        // Interval count
        if (flashcard.spacedRepetitionData!.interval <= 7) {
          flashcardIntervalCounts[1]++;
        } else if (flashcard.spacedRepetitionData!.interval <= 28) {
          flashcardIntervalCounts[2]++;
        } else if (flashcard.spacedRepetitionData!.interval <= 56) {
          flashcardIntervalCounts[3]++;
        } else {
          flashcardIntervalCounts[4]++;
        }

        // Challenging flashcards
        if (flashcard.spacedRepetitionData!.totalAnswers > 4 &&
            flashcard.spacedRepetitionData!.wrongAnswerRate >= 0.25) {
          bool addToEnd = true;
          for (int i = 0; i < challengingFlashcards.length; i++) {
            if (flashcard.spacedRepetitionData!.wrongAnswerRate >
                challengingFlashcards[i]
                    .spacedRepetitionData!
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
}
