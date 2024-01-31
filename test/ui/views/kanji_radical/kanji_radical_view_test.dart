import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/kanji_radical/kanji_radical_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('KanjiRadicalViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Basic radical', (tester) async {
      getAndRegisterIsarService(getKanjiWithRadical: [Kanji()..kanji = '丩']);

      await tester.pumpWidget(
        MaterialApp(
          home: KanjiRadicalView(
            KanjiRadical()
              ..radical = '丨'
              ..kangxiId = 2
              ..strokeCount = 1
              ..meaning = 'line'
              ..reading = 'ぼう, たてぼう'
              ..position = KanjiRadicalPosition.none
              ..importance = KanjiRadicalImportance.none,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('丨'), findsOne);
      expect(find.text('2\nRadical #'), findsOne);
      expect(find.text('—\nImportance'), findsOne);
      expect(find.text('1\nStrokes'), findsOne);
      expect(find.text('—\nPosition'), findsOne);

      expect(find.text('line'), findsOne);
      expect(find.text('ぼう, たてぼう'), findsOne);

      expect(find.text('Variants'), findsNothing);

      expect(find.text('Kanji using the radical'), findsOne);
      expect(find.textContaining('丩'), findsOne);
    });

    testWidgets('Radical with variants', (tester) async {
      getAndRegisterIsarService(
        getKanjiRadical: KanjiRadical()
          ..radical = '攵'
          ..strokeCount = 4
          ..position = KanjiRadicalPosition.right,
        getKanjiWithRadical: [Kanji()..kanji = '收'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KanjiRadicalView(
            KanjiRadical()
              ..radical = '攴'
              ..kangxiId = 66
              ..strokeCount = 4
              ..meaning = 'strike'
              ..reading = 'ぼくづくり、ぼくにょう、のぶん、しぶん、とまた'
              ..position = KanjiRadicalPosition.right
              ..importance = KanjiRadicalImportance.top75
              ..variants = ['攵'],
          ),
        ),
      );

      // Check main radical information before variant is loaded
      expect(find.text('攴'), findsOne);
      expect(find.text('66\nRadical #'), findsOne);
      expect(find.text('Top 75%\nImportance'), findsOne);
      expect(find.text('4\nStrokes'), findsOne);
      // Finds 2 for main radical and variant
      expect(find.textContaining('Position'), findsExactly(2));

      // Variant temporary information
      expect(find.text('0\nStrokes'), findsOne);
      expect(find.text('—\nPosition'), findsOne);

      await tester.pumpAndSettle();

      expect(find.text('strike'), findsOne);
      expect(find.text('ぼくづくり、ぼくにょう、のぶん、しぶん、とまた'), findsOne);

      expect(find.text('Variants'), findsOne);
      expect(find.text('攵'), findsOne);
      // Below each finds 2 for main radical and variant
      expect(find.text('4\nStrokes'), findsExactly(2));
      expect(find.textContaining('Position'), findsExactly(2));

      expect(find.text('Kanji using the radical'), findsOne);
      expect(find.textContaining('收'), findsOne);
    });
  });
}
