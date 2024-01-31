import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/views/flashcard_set_info/flashcard_set_info_view.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FlashcardSetInfoViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Upcoming due flashcards', (tester) async {
      final todayAsInt = DateTime.now().toInt();

      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        // Generates a list of vocab with different amount of vocab per due date
        getVocabList: [Vocab()] +
            List.generate(
              8,
              (i) => List.generate(
                i,
                (x) => Vocab()
                  ..spacedRepetitionData = (SpacedRepetitionData()
                    ..dueDate = todayAsInt + i
                    ..interval = 1
                    ..totalAnswers = 1
                    ..totalWrongAnswers = 0),
              ),
            ).expand((element) => element).toList(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardSetInfoView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0],
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

      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        // Generates a list of vocab with different amount of vocab per due date
        getVocabList: [
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [VocabKanji()..kanji = '秋']
                ..readings = [VocabReading()..reading = 'あき'],
            ]
            ..definitions = [VocabDefinition()..definition = 'autumn; fall']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = todayAsInt
              ..interval = 1
              ..totalAnswers = 10
              ..totalWrongAnswers = 1),
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = todayAsInt
              ..interval = 1
              ..totalAnswers = 10
              ..totalWrongAnswers = 8),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardSetInfoView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('はい'), 100);

      expect(find.text('Top challenging flashcards'), findsOne);
      expect(find.text('秋【あき】'), findsNothing);
      expect(find.text('はい'), findsOne);
    });
  });
}
