import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/radical/radical_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('RadicalViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Basic radical', (tester) async {
      getAndRegisterDictionaryService(
        getKanjiWithRadical: [
          Kanji(
            id: '丩'.kanjiCodePoint(),
            kanji: '丩',
            meaning: null,
            radical: '丩',
            components: null,
            grade: null,
            strokeCount: 21,
            frequency: null,
            jlpt: null,
            strokes: null,
            compounds: null,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RadicalView(
            Radical(
              id: 0,
              radical: '丨',
              kangxiId: 2,
              strokeCount: 1,
              meaning: 'line',
              reading: 'ぼう, たてぼう',
            ),
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
      getAndRegisterDictionaryService(
        getRadical: const Radical(
          id: 0,
          radical: '攵',
          kangxiId: 0,
          strokeCount: 4,
          meaning: '',
          reading: '',
        ),
        getKanjiWithRadical: [
          Kanji(
            id: '收'.kanjiCodePoint(),
            kanji: '收',
            meaning: null,
            radical: '收',
            components: null,
            grade: null,
            strokeCount: 21,
            frequency: null,
            jlpt: null,
            strokes: null,
            compounds: null,
          ),
        ],
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: RadicalView(
            Radical(
              id: 0,
              radical: '攴',
              kangxiId: 66,
              strokeCount: 4,
              meaning: 'strike',
              reading: 'ぼくづくり、ぼくにょう、のぶん、しぶん、とまた',
              position: RadicalPosition.right,
              importance: RadicalImportance.top75,
              variants: ['攵'],
            ),
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
