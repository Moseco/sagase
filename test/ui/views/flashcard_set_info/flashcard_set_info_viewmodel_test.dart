import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/views/flashcard_set_info/flashcard_set_info_viewmodel.dart';
import 'package:sagase/utils/date_time_utils.dart';

import '../../../helpers/common/flashcard_set_data.dart';
import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('FlashcardsViewModelTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    test('Upcoming due flashcards', () async {
      // Flashcard for each upcoming due flashcards group
      // and flashcards that should not be added to a group
      getAndRegisterDictionaryService(
        getFlashcardSetFlashcards: [
              getVocab1(),
              getVocab2(),
              getVocab3(),
              getVocab4(),
              getVocab5(),
              getVocab6(),
              getVocab7(),
              getVocab8(),
            ]
                .map(
                  (e) => e
                    ..spacedRepetitionData = SpacedRepetitionData.initial(
                      dictionaryItem: e,
                      frontType: FrontType.japanese,
                    ).copyWith(
                        dueDate: DateTime.now()
                            .add(Duration(days: e.id - 1))
                            .toInt()),
                )
                .toList() +
            [
              getVocab9()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocab9(),
                  frontType: FrontType.japanese,
                ),
              getVocab10(),
            ],
        getFlashcardSetReportRange: [],
      );

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(createDefaultFlashcardSet());
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.upcomingDueFlashcards!.length, 8);
      expect(viewModel.upcomingDueFlashcards![0], 1);
      expect(viewModel.upcomingDueFlashcards![1], 1);
      expect(viewModel.upcomingDueFlashcards![2], 1);
      expect(viewModel.upcomingDueFlashcards![3], 1);
      expect(viewModel.upcomingDueFlashcards![4], 1);
      expect(viewModel.upcomingDueFlashcards![5], 1);
      expect(viewModel.upcomingDueFlashcards![6], 1);
      expect(viewModel.upcomingDueFlashcards![7], 1);
    });

    test('Flashcard interval counts', () async {
      // Flashcards for each interval group
      // and flashcards that should not be in a group
      getAndRegisterDictionaryService(
        getFlashcardSetFlashcards: [
          getVocab1()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
              dictionaryItem: getVocab1(),
              frontType: FrontType.japanese,
            ).copyWith(interval: 1, dueDate: DateTime.now().toInt()),
          getVocab2()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
              dictionaryItem: getVocab2(),
              frontType: FrontType.japanese,
            ).copyWith(interval: 8, dueDate: DateTime.now().toInt()),
          getVocab3()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
              dictionaryItem: getVocab3(),
              frontType: FrontType.japanese,
            ).copyWith(interval: 30, dueDate: DateTime.now().toInt()),
          getVocab4()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
              dictionaryItem: getVocab4(),
              frontType: FrontType.japanese,
            ).copyWith(interval: 60, dueDate: DateTime.now().toInt()),
          getVocab5()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
              dictionaryItem: getVocab5(),
              frontType: FrontType.japanese,
            ),
          getVocab6(),
        ],
        getFlashcardSetReportRange: [],
      );

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(createDefaultFlashcardSet());
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.flashcardIntervalCounts[0], 2);
      expect(viewModel.flashcardIntervalCounts[1], 1);
      expect(viewModel.flashcardIntervalCounts[2], 1);
      expect(viewModel.flashcardIntervalCounts[3], 1);
      expect(viewModel.flashcardIntervalCounts[4], 1);
    });

    test('Historical performance', () async {
      getAndRegisterDictionaryService(
        getFlashcardSetFlashcards: [getVocab1()],
        getFlashcardSetReportRange: [
          FlashcardSetReport(
            id: 0,
            flashcardSetId: 1,
            date: DateTime.now().subtract(const Duration(days: 5)).toInt(),
            dueFlashcardsCompleted: 1,
            dueFlashcardsGotWrong: 2,
            newFlashcardsCompleted: 3,
          ),
          FlashcardSetReport(
            id: 1,
            flashcardSetId: 1,
            date: DateTime.now().subtract(const Duration(days: 3)).toInt(),
            dueFlashcardsCompleted: 3,
            dueFlashcardsGotWrong: 2,
            newFlashcardsCompleted: 1,
          ),
          FlashcardSetReport(
            id: 2,
            flashcardSetId: 1,
            date: DateTime.now().toInt(),
            dueFlashcardsCompleted: 20,
            dueFlashcardsGotWrong: 0,
            newFlashcardsCompleted: 0,
          ),
        ],
      );

      final navigationService = getAndRegisterNavigationService();

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(createDefaultFlashcardSet());
      await viewModel.futureToRun();

      // Verify that back was not called
      verifyNever(navigationService.back());

      // Check contents
      expect(viewModel.maxDueFlashcardsCompleted, 20);
      expect(viewModel.flashcardSetReports.length, 7);
      expect(viewModel.flashcardSetReports[0], null);
      expect(
        viewModel.flashcardSetReports[1]!.date,
        DateTime.now().subtract(const Duration(days: 5)).toInt(),
      );
      expect(viewModel.flashcardSetReports[2], null);
      expect(
        viewModel.flashcardSetReports[3]!.date,
        DateTime.now().subtract(const Duration(days: 3)).toInt(),
      );
      expect(viewModel.flashcardSetReports[4], null);
      expect(viewModel.flashcardSetReports[5], null);
      expect(viewModel.flashcardSetReports[6]!.date, DateTime.now().toInt());
    });

    test('Top challenging flashcards', () async {
      // Flashcards that fall within and outside of challenging flashcards limit
      getAndRegisterDictionaryService(
        getFlashcardSetFlashcards: List.generate(
              20,
              (i) {
                final vocab = Vocab(
                  id: i,
                  pos: null,
                  common: true,
                  frequencyScore: 0,
                );
                vocab.spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: vocab,
                  frontType: FrontType.japanese,
                ).copyWith(
                  totalAnswers: i + 1,
                  totalWrongAnswers: i,
                  dueDate: DateTime.now().toInt(),
                );
                return vocab;
              },
            ) +
            [
              Vocab(
                id: 20,
                pos: null,
                common: true,
                frequencyScore: 0,
              )..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem:
                      Vocab(id: 20, pos: null, common: true, frequencyScore: 0),
                  frontType: FrontType.japanese,
                ).copyWith(
                  totalAnswers: 20,
                  totalWrongAnswers: 3,
                  dueDate: DateTime.now().toInt(),
                ),
              Vocab(
                id: 21,
                pos: null,
                common: true,
                frequencyScore: 0,
              )..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem:
                      Vocab(id: 21, pos: null, common: true, frequencyScore: 0),
                  frontType: FrontType.japanese,
                ).copyWith(
                  totalAnswers: 10,
                  totalWrongAnswers: 3,
                  dueDate: DateTime.now().toInt(),
                ),
            ],
        getFlashcardSetReportRange: [],
      );

      // Initialize viewmodel
      var viewModel = FlashcardSetInfoViewModel(createDefaultFlashcardSet());
      await viewModel.futureToRun();

      // Check contents
      expect(viewModel.challengingFlashcards.length, 10);
      expect(viewModel.challengingFlashcards.first.id, 19);
      expect(viewModel.challengingFlashcards.last.id, 10);
    });
  });
}
