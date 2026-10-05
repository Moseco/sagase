import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/ui/views/kana_practice/kana_practice_view.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('KanaPracticeViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    final allKana = {
      for (final kana in Kana.getKana(
        scripts: KanaScript.values.toSet(),
        types: KanaType.values.toSet(),
      ))
        kana.kana: kana,
    };

    Kana currentKana(WidgetTester tester) {
      return allKana[tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data)
          .firstWhere(allKana.containsKey)]!;
    }

    bool isShowingFront(WidgetTester tester) {
      return tester
              .state<FlipCardState>(find.byType(FlipCard))
              .controller
              .value ==
          0;
    }

    bool isUndoEnabled(WidgetTester tester) {
      return tester
              .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
              .onPressed !=
          null;
    }

    void stubSelectionDialog(
      MockDialogService dialogService,
      Set<KanaScript> scripts,
      Set<KanaType> types,
    ) {
      when(dialogService.showCustomDialog(
        variant: DialogType.kanaPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer((_) async => DialogResponse(data: (scripts, types)));
    }

    testWidgets('Progress bar', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);

      // Wrong answers go back into the deck
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);
    });

    testWidgets('Typing', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
        getKanaPracticeTypingEnabled: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOne);
      expect(find.byIcon(Icons.undo), findsNothing);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      // Wrong answer should stay on the flashcard and keep the answer
      await tester.enterText(find.byType(TextField), 'ka');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_forward), findsOne);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.text('ka'), findsOne);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOne);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text('ka'), findsNothing);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      // Correct answer for the current flashcard
      const romaji = {'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po'};
      final kana = tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data)
          .firstWhere(romaji.containsKey);
      await tester.enterText(find.byType(TextField), romaji[kana]!);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check), findsOne);
      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);
    });

    testWidgets('Toggle typing', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.undo), findsOne);

      await tester.tap(find.byIcon(Icons.keyboard));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOne);
      expect(find.byIcon(Icons.undo), findsNothing);

      await tester.tap(find.byIcon(Icons.style));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.undo), findsOne);
    });

    testWidgets('Flip and undo', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      final firstKana = currentKana(tester);
      expect(isShowingFront(tester), true);
      expect(isUndoEnabled(tester), false);

      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();

      expect(isShowingFront(tester), false);

      // Answering shows the front of the next flashcard
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(isShowingFront(tester), true);
      expect(isUndoEnabled(tester), true);
      expect(currentKana(tester), isNot(firstKana));

      // Undo from the back of a flashcard shows the front of the previous one
      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(isShowingFront(tester), true);
      expect(isUndoEnabled(tester), false);
      expect(currentKana(tester), firstKana);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);
    });

    testWidgets('Swipe flashcards', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      // Short swipe returns the flashcard without answering
      var kana = currentKana(tester);
      await tester.drag(find.byType(FlipCard), const Offset(40, 0));
      await tester.pumpAndSettle();

      expect(currentKana(tester), kana);
      expect(isUndoEnabled(tester), false);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      // Swipe right is correct
      await tester.drag(find.byType(FlipCard), const Offset(300, 0));
      await tester.pumpAndSettle();

      expect(currentKana(tester), isNot(kana));
      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);

      // Swipe left is wrong
      kana = currentKana(tester);
      await tester.drag(find.byType(FlipCard), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(currentKana(tester), isNot(kana));
      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);

      // Undo both swipes
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(currentKana(tester), kana);
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);
    });

    testWidgets('Input ignored while swiping', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      // Second answer during the swipe animation is ignored
      final kana = currentKana(tester);
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(currentKana(tester), isNot(kana));
      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);

      // Undo during the swipe animation is ignored
      await tester.tap(find.byIcon(Icons.check));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(find.text('2 completed'), findsOne);
      expect(find.text('3 cards left'), findsOne);

      // Undo works once the swipe animation is finished
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.undo));
      await tester.pumpAndSettle();

      expect(currentKana(tester), kana);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);
    });

    testWidgets('Finish and exit', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final navigationService = getAndRegisterNavigationService();

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
      }

      verify(navigationService.back()).called(1);
      expect(find.text('5 completed'), findsOne);
      expect(find.text('0 cards left'), findsOne);
    });

    testWidgets('Finish and restart', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      final navigationService = getAndRegisterNavigationService();
      getAndRegisterDialogService(dialogResponseConfirmed: true);

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
      }

      verifyNever(navigationService.back());
      expect(isUndoEnabled(tester), false);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);
    });

    testWidgets('Edit selection', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
      );
      stubSelectionDialog(
        getAndRegisterDialogService(),
        {KanaScript.katakana},
        {KanaType.voiced, KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FlipCard));
      await tester.pumpAndSettle();
      expect(isShowingFront(tester), false);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // New session starts on the front of a flashcard
      expect(isShowingFront(tester), true);
      expect(isUndoEnabled(tester), false);
      expect(currentKana(tester).script, KanaScript.katakana);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('25 cards left'), findsOne);
    });

    testWidgets('Edit selection while typing', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
        getKanaPracticeTypingEnabled: true,
      );
      stubSelectionDialog(
        getAndRegisterDialogService(),
        {KanaScript.katakana},
        {KanaType.voiced, KanaType.semiVoiced},
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'ka');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_forward), findsOne);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      // Previous answer should be cleared for the new session
      expect(find.byIcon(Icons.check), findsOne);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
      expect(find.text('ka'), findsNothing);
      expect(currentKana(tester).script, KanaScript.katakana);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('25 cards left'), findsOne);
    });

    testWidgets('Typing submit with keyboard', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
        getKanaPracticeTypingEnabled: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      bool isAnswerVisible(Kana kana) {
        return tester
            .widget<Visibility>(find.ancestor(
              of: find.text(kana.romaji),
              matching: find.byType(Visibility),
            ))
            .visible;
      }

      // Wrong answer shows the correct answer
      final kana = currentKana(tester);
      expect(isAnswerVisible(kana), false);
      await tester.enterText(find.byType(TextField), 'ka');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(isAnswerVisible(kana), true);
      expect(find.text('ka'), findsOne);
      expect(find.byIcon(Icons.arrow_forward), findsOne);

      // Submitting again moves on to the next flashcard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(currentKana(tester), isNot(kana));
      expect(find.text('ka'), findsNothing);
      expect(find.byIcon(Icons.check), findsOne);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      // Correct answer
      await tester.enterText(
        find.byType(TextField),
        currentKana(tester).romaji,
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('4 cards left'), findsOne);
    });

    testWidgets('Typing disabled while showing answer', (tester) async {
      getAndRegisterSharedPreferencesService(
        getKanaPracticeTypes: {KanaType.semiVoiced},
        getKanaPracticeTypingEnabled: true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: KanaPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      String fieldText() =>
          tester.widget<TextField>(find.byType(TextField)).controller!.text;

      final kana = currentKana(tester);
      await tester.enterText(find.byType(TextField), 'ka');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_forward), findsOne);

      // Changing to the correct answer or clearing should be ignored
      await tester.enterText(find.byType(TextField), kana.romaji);
      await tester.pump();
      expect(fieldText(), 'ka');
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(fieldText(), 'ka');

      // Keyboard should stay connected so submitting still moves on
      expect(tester.testTextInput.hasAnyClients, true);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(currentKana(tester), isNot(kana));
      expect(find.byIcon(Icons.check), findsOne);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('5 cards left'), findsOne);

      // Typing works again for the next flashcard
      await tester.enterText(find.byType(TextField), 'p');
      await tester.pump();
      expect(fieldText(), 'p');
    });
  });
}
