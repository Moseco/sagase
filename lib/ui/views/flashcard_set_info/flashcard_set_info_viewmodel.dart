import 'package:intl/intl.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetInfoViewModel extends FutureViewModel {
  final _navigationService = locator<NavigationService>();
  final _dialogService = locator<DialogService>();
  final _dictionaryService = locator<DictionaryService>();

  final FlashcardSet flashcardSet;

  late int _flashcardCount;
  int get flashcardCount => _flashcardCount;
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
  // Historical performance
  int _maxDueFlashcardsCompleted = 0;
  int get maxDueFlashcardsCompleted => _maxDueFlashcardsCompleted;
  late List<FlashcardSetReport?> flashcardSetReports;

  bool _showIntervalAsPercent = false;
  bool get showIntervalAsPercent => _showIntervalAsPercent;

  FlashcardSetInfoViewModel(this.flashcardSet);

  @override
  Future<void> futureToRun() async {
    final flashcards =
        await _dictionaryService.getFlashcardSetFlashcards(flashcardSet);
    _flashcardCount = flashcards.length;

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
    for (final flashcard in flashcards) {
      if (flashcard.spacedRepetitionData?.dueDate != null) {
        // Upcoming due count
        upcomingDueFlashcards![
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

    await _getFlashcardSetReports(today);
  }

  Future<void> _getFlashcardSetReports(DateTime endDateTime) async {
    // Get one week flashcard set reports and space out nulls in list
    final startDateTime = endDateTime.subtract(const Duration(days: 6));

    var flashcardSetReportMap = {
      for (var v in await _dictionaryService.getFlashcardSetReportRange(
        flashcardSet,
        startDateTime.toInt(),
        endDateTime.toInt(),
      ))
        v.date: v
    };

    flashcardSetReports = [];
    for (int i = 0; i < 7; i++) {
      final dateTime = startDateTime.add(Duration(days: i));
      flashcardSetReports.add(flashcardSetReportMap[dateTime.toInt()]);
      if (flashcardSetReports.last != null &&
          flashcardSetReports.last!.dueFlashcardsCompleted >
              _maxDueFlashcardsCompleted) {
        _maxDueFlashcardsCompleted =
            flashcardSetReports.last!.dueFlashcardsCompleted;
      }
    }
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

  void toggleIntervalDisplay() {
    _showIntervalAsPercent = !_showIntervalAsPercent;
    rebuildUi();
  }

  void showFlashcardSetReport(int index) {
    if (flashcardSetReports[index] != null) {
      _dialogService.showCustomDialog(
        variant: DialogType.flashcardSetReport,
        data: (flashcardSetReports[index], null),
        title: DateFormat.MEd()
            .format(DateTime.now().subtract(Duration(days: 6 - index))),
        mainButtonTitle: 'Close',
        barrierDismissible: true,
      );
    }
  }
}
