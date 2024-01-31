import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/views/flashcards/flashcards_view.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FlashcardsViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Progress bar with new cards', (tester) async {
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no'],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now()
              ..flashcardsCompletedToday = 3
              ..newFlashcardsCompletedToday = 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 new cards done today'), findsOne);
      expect(find.text('2 new cards left'), findsOne);
    });

    testWidgets('Progress bar with due cards ', (tester) async {
      final todayAsInt = DateTime.now().toInt();

      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = todayAsInt + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0)
            ..definitions = [VocabDefinition()..definition = 'no'],
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = todayAsInt
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0)
            ..definitions = [VocabDefinition()..definition = 'yes'],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now()
              ..flashcardsCompletedToday = 3
              ..newFlashcardsCompletedToday = 2,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);
    });
  });
}
