import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/flashcards/flashcards_view.dart';
import 'package:sagase/ui/views/flashcards/flashcards_viewmodel.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/common/flashcard_set_data.dart';
import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('FlashcardsViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    group('Progress bar', () {
      group('Normal mode', () {
        testWidgets('New cards', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due tomorrow
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('New cards and completed', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 1,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 2,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due tomorrow
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due cards', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due cards and completed', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 1,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 2,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Finish due cards', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Finish due cards with completed', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 1,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 2,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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
      });

      group('Learning mode', () {
        testWidgets('New cards', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due tomorrow
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('New cards and completed', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 1,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 2,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due tomorrow
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due cards', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due cards only and completed', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 1,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 2,
            ),
            getFlashcardSetFlashcards: [
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due and new cards', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due and new cards and completed', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 1,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 2,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due card with no new cards added', (tester) async {
          getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 3,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 10,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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

        testWidgets('Due and new cards and details disabled', (tester) async {
          getAndRegisterDictionaryService(
            getRecentFlashcardSetReport: FlashcardSetReport(
              id: 0,
              flashcardSetId: 0,
              date: 20240920,
              dueFlashcardsCompleted: 0,
              dueFlashcardsGotWrong: 0,
              newFlashcardsCompleted: 0,
            ),
            getFlashcardSetFlashcards: [
              // New
              getVocabYes(),
              // Started
              getVocabMaybe()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabMaybe(),
                  frontType: FrontType.japanese,
                ),
              // Due today
              getVocabNo1()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo1(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due today
              getVocabNo2()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo2(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().toInt(),
                ),
              // Due tomorrow
              getVocabNo3()
                ..spacedRepetitionData = SpacedRepetitionData.initial(
                  dictionaryItem: getVocabNo3(),
                  frontType: FrontType.japanese,
                ).copyWith(
                  interval: 1,
                  totalAnswers: 1,
                  totalWrongAnswers: 0,
                  dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
                ),
            ],
          );

          await tester.pumpWidget(
            MaterialApp(
              home: FlashcardsView(
                createDefaultFlashcardSet(),
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
      });

      testWidgets('Progress bar skip mode', (tester) async {
        getAndRegisterSharedPreferencesService(getShowDetailedProgress: true);
        getAndRegisterDictionaryService(
          getRecentFlashcardSetReport: FlashcardSetReport(
            id: 0,
            flashcardSetId: 0,
            date: 20240920,
            dueFlashcardsCompleted: 0,
            dueFlashcardsGotWrong: 0,
            newFlashcardsCompleted: 0,
          ),
          getFlashcardSetFlashcards: [
            // New
            getVocabYes(),
            // Started
            getVocabMaybe()
              ..spacedRepetitionData = SpacedRepetitionData.initial(
                dictionaryItem: getVocabMaybe(),
                frontType: FrontType.japanese,
              ),
            // Due today
            getVocabNo1()
              ..spacedRepetitionData = SpacedRepetitionData.initial(
                dictionaryItem: getVocabNo1(),
                frontType: FrontType.japanese,
              ).copyWith(
                interval: 1,
                totalAnswers: 1,
                totalWrongAnswers: 0,
                dueDate: DateTime.now().toInt(),
              ),
            // Due tomorrow
            getVocabNo3()
              ..spacedRepetitionData = SpacedRepetitionData.initial(
                dictionaryItem: getVocabNo3(),
                frontType: FrontType.japanese,
              ).copyWith(
                interval: 1,
                totalAnswers: 1,
                totalWrongAnswers: 0,
                dueDate: DateTime.now().add(const Duration(days: 1)).toInt(),
              ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: FlashcardsView(
              createDefaultFlashcardSet(),
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

    group('Flashcard front', () {
      // TODO
    });

    group('Flashcard back', () {
      // TODO
    });
  });
}
