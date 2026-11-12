import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:sagase/ui/dialogs/conjugation_practice_selection_dialog.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/mocks.dart';

void main() {
  group('ConjugationPracticeSelectionDialogTest', () {
    late MockSnackbarService snackbarService;

    setUp(() {
      registerServices();
      snackbarService = getAndRegisterSnackbarService();
      when(snackbarService.isSnackbarOpen).thenReturn(false);
      when(snackbarService.showSnackbar(message: anyNamed('message')))
          .thenReturn(null);
    });
    tearDown(() => unregisterServices());

    Future<List<DialogResponse>> pumpDialog(
      WidgetTester tester,
      Set<ConjugationPracticeWordType> types,
      Set<ConjugationPracticeForm> forms,
    ) async {
      final List<DialogResponse> responses = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConjugationPracticeSelectionDialog(
              request: DialogRequest(data: (types, forms)),
              completer: responses.add,
            ),
          ),
        ),
      );
      return responses;
    }

    bool isSelected(WidgetTester tester, String title) {
      final finder = find.widgetWithText(CheckboxListTile, title);
      return tester.widget<CheckboxListTile>(finder).value!;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    testWidgets('Sections start collapsed', (tester) async {
      await pumpDialog(
        tester,
        {ConjugationPracticeWordType.godanMu},
        {ConjugationPracticeForm.past, ConjugationPracticeForm.teForm},
      );

      expect(find.text('1 of 12 selected'), findsOne);
      expect(find.text('0 of 3 selected'), findsOne);
      expect(find.text('2 of 19 selected'), findsOne);
      expect(find.text('Godan う').hitTestable(), findsNothing);
      expect(find.text('Polite').hitTestable(), findsNothing);

      // Expanding a section only shows its own items
      await tapText(tester, 'Verbs');
      expect(find.text('Godan う').hitTestable(), findsOne);
      expect(find.text('Polite').hitTestable(), findsNothing);

      await tapText(tester, 'Verbs');
      expect(find.text('Godan う').hitTestable(), findsNothing);
    });

    testWidgets('Select and start', (tester) async {
      final responses = await pumpDialog(
        tester,
        {ConjugationPracticeWordType.godanMu},
        {ConjugationPracticeForm.past},
      );

      expect(isSelected(tester, 'Godan む'), true);
      expect(isSelected(tester, 'Ichidan'), false);

      await tapText(tester, 'Verbs');
      await tapText(tester, 'Ichidan');
      expect(isSelected(tester, 'Ichidan'), true);
      await tapText(tester, 'Godan む');
      expect(isSelected(tester, 'Godan む'), false);
      expect(find.text('1 of 12 selected'), findsOne);

      await tapText(tester, 'Forms');
      await tapText(tester, 'Te-form');
      expect(isSelected(tester, 'Te-form'), true);
      expect(find.text('2 of 19 selected'), findsOne);

      await tester.tap(find.text('Start'));
      await tester.pump();

      expect(responses.length, 1);
      final (
        Set<ConjugationPracticeWordType> types,
        Set<ConjugationPracticeForm> forms,
      ) = responses[0].data;
      expect(types, {ConjugationPracticeWordType.ichidan});
      expect(
        forms,
        {ConjugationPracticeForm.past, ConjugationPracticeForm.teForm},
      );
    });

    testWidgets('Select all', (tester) async {
      final responses = await pumpDialog(
        tester,
        {ConjugationPracticeWordType.godanMu},
        {ConjugationPracticeForm.past},
      );

      // Verbs section can be selected while collapsed
      await tester.tap(find.text('Select all').first);
      await tester.pump();
      for (final type in ConjugationPracticeWordType.values) {
        if (type.isAdjective) continue;
        expect(isSelected(tester, type.title), true);
      }
      expect(find.text('12 of 12 selected'), findsOne);
      expect(find.text('Select none'), findsOne);

      await tester.tap(find.text('Start'));
      await tester.pump();
      final (Set<ConjugationPracticeWordType> types, _) = responses[0].data;
      expect(types.length, ConjugationPracticeWordType.values.length - 3);
    });

    testWidgets('Invalid selection', (tester) async {
      final responses = await pumpDialog(
        tester,
        {ConjugationPracticeWordType.adjectiveI},
        {ConjugationPracticeForm.potential},
      );

      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(responses, isEmpty);
      verify(snackbarService.showSnackbar(
        message: 'The selected forms do not apply to the selected word types',
      )).called(1);

      await tapText(tester, 'Adjectives');
      await tapText(tester, 'い-adjectives');
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(responses, isEmpty);
      verify(snackbarService.showSnackbar(
        message: 'At least one word type and one form must be selected',
      )).called(1);
    });
  });
}
