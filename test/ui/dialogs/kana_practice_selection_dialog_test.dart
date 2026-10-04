import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/ui/dialogs/kana_practice_selection_dialog.dart';
import 'package:stacked_services/stacked_services.dart';

import '../../helpers/mocks.dart';

void main() {
  group('KanaPracticeSelectionDialogTest', () {
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
      Set<KanaScript> scripts,
      Set<KanaType> types,
    ) async {
      final List<DialogResponse> responses = [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KanaPracticeSelectionDialog(
              request: DialogRequest(data: (scripts, types)),
              completer: responses.add,
            ),
          ),
        ),
      );
      return responses;
    }

    bool isSelected(WidgetTester tester, String title) {
      return tester
          .widget<CheckboxListTile>(
            find.widgetWithText(CheckboxListTile, title),
          )
          .value!;
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text));
      await tester.tap(find.text(text));
      await tester.pump();
    }

    testWidgets('Initial selection', (tester) async {
      await pumpDialog(
        tester,
        {KanaScript.katakana},
        {KanaType.basic, KanaType.combination},
      );

      expect(isSelected(tester, 'Hiragana'), false);
      expect(isSelected(tester, 'Katakana'), true);
      expect(isSelected(tester, 'Basic'), true);
      expect(isSelected(tester, 'Voiced'), false);
      expect(isSelected(tester, 'Semi-voiced'), false);
      expect(isSelected(tester, 'Combinations'), true);
    });

    testWidgets('Change selection and start', (tester) async {
      final initialScripts = {KanaScript.katakana};
      final initialTypes = {KanaType.basic, KanaType.combination};
      final responses = await pumpDialog(tester, initialScripts, initialTypes);

      await tapText(tester, 'Hiragana');
      await tapText(tester, 'Katakana');
      await tapText(tester, 'Basic');
      await tapText(tester, 'Voiced');

      expect(isSelected(tester, 'Hiragana'), true);
      expect(isSelected(tester, 'Katakana'), false);
      expect(isSelected(tester, 'Basic'), false);
      expect(isSelected(tester, 'Voiced'), true);
      expect(isSelected(tester, 'Combinations'), true);
      expect(responses, isEmpty);

      await tapText(tester, 'Start');

      expect(responses.length, 1);
      final (Set<KanaScript> scripts, Set<KanaType> types) =
          responses[0].data;
      expect(scripts, {KanaScript.hiragana});
      expect(types, {KanaType.voiced, KanaType.combination});
      verifyNever(snackbarService.showSnackbar(message: anyNamed('message')));

      // The sets passed in should not be modified in case the dialog is closed
      expect(initialScripts, {KanaScript.katakana});
      expect(initialTypes, {KanaType.basic, KanaType.combination});
    });

    testWidgets('Start requires a script and a type', (tester) async {
      final responses = await pumpDialog(
        tester,
        {KanaScript.hiragana},
        {KanaType.basic},
      );

      // No script selected
      await tapText(tester, 'Hiragana');
      await tapText(tester, 'Start');

      expect(responses, isEmpty);
      verify(snackbarService.showSnackbar(
        message: 'At least one script and one type must be selected',
      )).called(1);

      // No type selected
      await tapText(tester, 'Katakana');
      await tapText(tester, 'Basic');
      await tapText(tester, 'Start');

      expect(responses, isEmpty);
      verify(snackbarService.showSnackbar(message: anyNamed('message')))
          .called(1);

      // Snackbar should not be shown again while it is already open
      when(snackbarService.isSnackbarOpen).thenReturn(true);
      await tapText(tester, 'Start');

      expect(responses, isEmpty);
      verifyNever(snackbarService.showSnackbar(message: anyNamed('message')));

      // Valid selection
      await tapText(tester, 'Semi-voiced');
      await tapText(tester, 'Start');

      expect(responses.length, 1);
      final (Set<KanaScript> scripts, Set<KanaType> types) =
          responses[0].data;
      expect(scripts, {KanaScript.katakana});
      expect(types, {KanaType.semiVoiced});
    });
  });
}
