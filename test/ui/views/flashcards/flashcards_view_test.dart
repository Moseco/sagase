import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/views/flashcards/flashcards_view.dart';
import 'package:sagase/ui/views/flashcards/flashcards_viewmodel.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('FlashcardsViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Progress bar normal mode with new cards', (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
            startMode: FlashcardStartMode.normal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 new cards completed'), findsOne);
      expect(find.text('1 new cards left'), findsOne);
    });

    testWidgets('Progress bar normal mode with new cards and completed',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
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

      expect(find.text('2 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('3 new cards completed'), findsOne);
      expect(find.text('1 new cards left'), findsOne);
    });

    testWidgets('Progress bar normal mode with due cards', (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);
    });

    testWidgets('Progress bar normal mode with due cards and completed',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
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
      expect(find.text('2 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('4 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);
    });

    testWidgets('Progress bar normal mode finish due cards', (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('0 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);
    });

    testWidgets('Progress bar normal mode finish due cards with completed',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
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
      expect(find.text('2 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('4 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('2 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);
    });

    testWidgets('Progress bar learning mode with new cards only',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
            startMode: FlashcardStartMode.learning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 new cards completed'), findsOne);
      expect(find.text('1 new cards left'), findsOne);
    });

    testWidgets('Progress bar learning mode with new cards only and completed',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
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
            startMode: FlashcardStartMode.learning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('3 new cards completed'), findsOne);
      expect(find.text('1 new cards left'), findsOne);
    });

    testWidgets('Progress bar learning mode with due cards only',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
            startMode: FlashcardStartMode.learning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);
    });

    testWidgets('Progress bar learning mode with due cards only and completed',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
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
            startMode: FlashcardStartMode.learning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3 completed'), findsOne);
      expect(find.text('2 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('4 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);
    });

    testWidgets('Progress bar learning mode with due and new cards',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
            startMode: FlashcardStartMode.learning,
            randomSeed: 123,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 (0) completed'), findsOne);
      expect(find.text('2 (2) due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('0 (1) completed'), findsOne);
      expect(find.text('2 (1) due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('0 (2) completed'), findsOne);
      expect(find.text('2 (0) due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 (2) completed'), findsOne);
      expect(find.text('1 (0) due cards left'), findsOne);
    });

    testWidgets(
        'Progress bar learning mode with due and new cards and completed',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
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
            startMode: FlashcardStartMode.learning,
            randomSeed: 123,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 (2) completed'), findsOne);
      expect(find.text('2 (2) due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 (3) completed'), findsOne);
      expect(find.text('2 (1) due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 (4) completed'), findsOne);
      expect(find.text('2 (0) due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('2 (4) completed'), findsOne);
      expect(find.text('1 (0) due cards left'), findsOne);
    });

    testWidgets('Progress bar learning mode due card with no new cards added',
        (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now()
              ..flashcardsCompletedToday = 13
              ..newFlashcardsCompletedToday = 10,
            startMode: FlashcardStartMode.learning,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('13 completed'), findsOne);
      expect(find.text('1 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('10 new cards completed'), findsOne);
      expect(find.text('1 new cards left'), findsOne);
    });

    testWidgets(
        'Progress bar learning mode with due and new cards and details disabled',
        (tester) async {
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うーん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
            startMode: FlashcardStartMode.learning,
            randomSeed: 123,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('4 due cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('3 due cards left'), findsOne);
    });

    testWidgets('Progress bar skip mode', (tester) async {
      getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
      getAndRegisterIsarService(
        getPredefinedDictionaryLists: [],
        getMyDictionaryLists: [],
        getKanjiList: [],
        getVocabList: [
          // New
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'はい'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes'],
          // Started
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'いいえ'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = SpacedRepetitionData(),
          // Due today
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'うん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'yes']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt()
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
          // Due tomorrow
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ううん'],
            ]
            ..definitions = [VocabDefinition()..definition = 'no']
            ..spacedRepetitionData = (SpacedRepetitionData()
              ..dueDate = DateTime.now().toInt() + 1
              ..interval = 1
              ..totalAnswers = 1
              ..totalWrongAnswers = 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FlashcardsView(
            FlashcardSet()
              ..name = 'set'
              ..myDictionaryLists = [0]
              ..timestamp = DateTime.now(),
            startMode: FlashcardStartMode.skip,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 new cards completed'), findsOne);
      expect(find.text('2 new cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.done_all));
      await tester.pumpAndSettle();

      expect(find.text('1 new cards completed'), findsOne);
      expect(find.text('1 new cards left'), findsOne);
    });
  });
}
