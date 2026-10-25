import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:sagase/ui/views/conjugation_practice/conjugation_practice_view.dart';
import 'package:sagase/ui/widgets/furigana_text.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('ConjugationPracticeViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    String currentFormTitle(WidgetTester tester) {
      final titles = ConjugationPracticeForm.values.map((e) => e.title).toSet();
      return tester
          .widgetList<Text>(find.byType(Text))
          .map((e) => e.data)
          .firstWhere(titles.contains)!;
    }

    bool isAnswerVisible(WidgetTester tester) {
      return tester.widget<Visibility>(find.byType(Visibility)).visible;
    }

    TextField textField(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField));

    Color? furiganaColor(WidgetTester tester, String furigana) => tester
        .widget<FuriganaText>(find.byWidgetPredicate(
          (widget) => widget is FuriganaText && widget.text == furigana,
        ))
        .style
        ?.color;

    String answerFurigana(String formTitle) =>
        formTitle == 'Past' ? '死[し]んだ' : '死[し]なない';

    testWidgets('Romaji is converted while typing', (tester) async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {ConjugationPracticeForm.past},
      );

      await tester.pumpWidget(
        const MaterialApp(home: ConjugationPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'shin');
      await tester.pump();
      expect(find.text('しn'), findsOne);

      await tester.enterText(find.byType(TextField), 'しnd');
      await tester.pump();
      expect(find.text('しんd'), findsOne);
    });

    testWidgets('Answering questions', (tester) async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {
          ConjugationPracticeForm.past,
          ConjugationPracticeForm.negative,
        },
      );

      await tester.pumpWidget(
        const MaterialApp(home: ConjugationPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 left'), findsOne);
      expect(find.text('to die'), findsOne);
      expect(isAnswerVisible(tester), false);

      // Wrong answer shows the correct answer and keeps the input
      final firstForm = currentFormTitle(tester);
      await tester.enterText(find.byType(TextField), 'shinu');
      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();

      expect(isAnswerVisible(tester), true);
      expect(find.byIcon(Icons.arrow_forward), findsOne);
      expect(find.text('しぬ'), findsOne);
      expect(find.text('Godan ぬ'), findsOne);
      expect(find.text('0 completed'), findsOne);
      expect(furiganaColor(tester, answerFurigana(firstForm)), Colors.red);
      expect(textField(tester).style?.color, Colors.red);

      // Typing is blocked while showing the answer
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      expect(find.text('しぬ'), findsOne);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(isAnswerVisible(tester), false);
      expect(find.text('しぬ'), findsNothing);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 left'), findsOne);

      // Correct answer shows the answer in green and keeps the input
      final secondForm = currentFormTitle(tester);
      expect(secondForm, isNot(firstForm));
      await tester.enterText(
        find.byType(TextField),
        secondForm == 'Past' ? 'shinda' : 'shinanai',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(isAnswerVisible(tester), true);
      expect(find.byIcon(Icons.arrow_forward), findsOne);
      expect(furiganaColor(tester, answerFurigana(secondForm)), Colors.green);
      expect(textField(tester).style?.color, Colors.green);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 left'), findsOne);

      // Deleting does not retry a correct answer
      final input = textField(tester).controller!.text;
      await tester.enterText(
        find.byType(TextField),
        input.substring(0, input.length - 1),
      );
      await tester.pumpAndSettle();
      expect(textField(tester).controller!.text, input);
      expect(isAnswerVisible(tester), true);

      // The keyboard action moves on to the next question
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('1 completed'), findsOne);
      expect(find.text('1 left'), findsOne);
      expect(isAnswerVisible(tester), false);
      expect(textField(tester).controller!.text, '');
    });

    testWidgets('Deleting a wrong answer retries the question', (tester) async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {
          ConjugationPracticeForm.past,
          ConjugationPracticeForm.negative,
        },
      );

      await tester.pumpWidget(
        const MaterialApp(home: ConjugationPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      TextEditingController controller() =>
          tester.widget<TextField>(find.byType(TextField)).controller!;

      final form = currentFormTitle(tester);
      await tester.enterText(find.byType(TextField), 'shinan');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Trailing n is converted on submit with the cursor kept at the end
      expect(isAnswerVisible(tester), true);
      expect(controller().text, 'しなん');
      expect(
        controller().selection,
        const TextSelection.collapsed(offset: 3),
      );

      // Deleting a character clears the input and hides the answer
      await tester.enterText(find.byType(TextField), 'しな');
      await tester.pumpAndSettle();

      expect(controller().text, '');
      expect(isAnswerVisible(tester), false);
      expect(find.byIcon(Icons.check), findsOne);
      expect(currentFormTitle(tester), form);
      expect(find.text('0 completed'), findsOne);
      expect(find.text('2 left'), findsOne);

      // The same question can be answered again
      await tester.enterText(
        find.byType(TextField),
        form == 'Past' ? 'shinda' : 'shinanai',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(furiganaColor(tester, answerFurigana(form)), Colors.green);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('1 completed'), findsOne);
      expect(find.text('1 left'), findsOne);
    });

    testWidgets('Trailing n is converted on submit', (tester) async {
      getAndRegisterSharedPreferencesService(
        getConjugationPracticeWordTypes: {ConjugationPracticeWordType.godanNu},
        getConjugationPracticeForms: {
          ConjugationPracticeForm.politeNegative,
          ConjugationPracticeForm.past,
        },
      );

      await tester.pumpWidget(
        const MaterialApp(home: ConjugationPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();

      if (currentFormTitle(tester) != 'Polite negative') {
        await tester.enterText(find.byType(TextField), 'shinda');
        await tester.tap(find.byIcon(Icons.check));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pumpAndSettle();
      }
      expect(currentFormTitle(tester), 'Polite negative');

      await tester.enterText(find.byType(TextField), 'shinimasen');
      await tester.pump();
      expect(find.text('しにませn'), findsOne);

      await tester.tap(find.byIcon(Icons.check));
      await tester.pumpAndSettle();
      expect(textField(tester).controller!.text, 'しにません');
      expect(furiganaColor(tester, '死[し]にません'), Colors.green);

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text('2 completed'), findsOne);
      expect(find.text('0 left'), findsOne);
    });

    testWidgets('Edit selection', (tester) async {
      final dialogService = getAndRegisterDialogService();
      when(dialogService.showCustomDialog(
        variant: DialogType.conjugationPracticeSelection,
        data: anyNamed('data'),
        barrierDismissible: true,
      )).thenAnswer(
        (_) async => DialogResponse(
          data: (
            {ConjugationPracticeWordType.adjectiveIi},
            {ConjugationPracticeForm.past},
          ),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(home: ConjugationPracticeView(randomSeed: 123)),
      );
      await tester.pumpAndSettle();
      expect(find.text('20 left'), findsOne);

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(find.text('2 left'), findsOne);
      expect(find.text('Past'), findsOne);
      expect(find.text('abc'), findsNothing);
    });
  });
}
