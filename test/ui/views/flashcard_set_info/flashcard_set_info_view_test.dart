import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sagase/ui/views/flashcard_set_info/flashcard_set_info_view.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/common/flashcard_set_data.dart';
import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('FlashcardSetInfoViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Upcoming due flashcards', (tester) async {
      getAndRegisterDictionaryService(
        getFlashcardSetFlashcards:
            // No spaced repetition data
            [
                  Vocab(id: 1, pos: null, common: true, frequencyScore: 0),
                ] +
                // Spaced repetition with increasing due date
                List.generate(
                  8,
                  (i) => List.generate(
                    i,
                    (j) {
                      final vocab = Vocab(
                        id: 1,
                        pos: null,
                        common: true,
                        frequencyScore: 0,
                      );
                      vocab.spacedRepetitionData = SpacedRepetitionData.initial(
                        dictionaryItem: vocab,
                        frontType: FrontType.japanese,
                      ).copyWith(
                        dueDate: DateTime.now().add(Duration(days: i)).toInt(),
                      );
                      return vocab;
                    },
                  ),
                ).expand((element) => element).toList(),
        getFlashcardSetReportRange: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardSetInfoView(
            createDefaultFlashcardSet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upcoming due flashcards'), findsOne);
      expect(find.text(DateFormat.EEEE().format(DateTime.now())), findsNothing);
      expect(
        find.text(DateFormat.EEEE()
            .format(DateTime.now().add(const Duration(days: 1)))),
        findsNothing,
      );
      expect(
        find.text(DateFormat.EEEE()
            .format(DateTime.now().add(const Duration(days: 2)))),
        findsOne,
      );
      expect(find.text('0'), findsOne);
      expect(find.text('1'), findsOne);
      expect(find.text('2'), findsOne);
      expect(find.text('3'), findsOne);
      expect(find.text('4'), findsOne);
      expect(find.text('5'), findsOne);
      expect(find.text('6'), findsOne);
      expect(find.text('7'), findsOne);

      expect(find.text('Flashcard interval length'), findsOne);
      expect(find.text('29'), findsOne);

      expect(find.text('Top challenging flashcards'), findsNothing);
    });

    testWidgets('Top challenging flashcards', (tester) async {
      final todayAsInt = DateTime.now().toInt();
      getAndRegisterDictionaryService(
        getFlashcardSetFlashcards: [
          getVocab1()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
                    dictionaryItem: getVocab1(), frontType: FrontType.japanese)
                .copyWith(
              dueDate: todayAsInt,
              totalAnswers: 10,
              totalWrongAnswers: 1,
            ),
          getVocab2()
            ..spacedRepetitionData = SpacedRepetitionData.initial(
                    dictionaryItem: getVocab2(), frontType: FrontType.japanese)
                .copyWith(
              dueDate: todayAsInt,
              totalAnswers: 10,
              totalWrongAnswers: 8,
            ),
        ],
        getFlashcardSetReportRange: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardSetInfoView(
            createDefaultFlashcardSet(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('二【に】'), 100);

      expect(find.text('Top challenging flashcards'), findsOne);
      expect(find.text('一【いち】'), findsNothing);
      expect(find.text('二【に】'), findsOne);
    });
  });
}
