import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/kanji/kanji_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/common/kanji_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('KanjiViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Low information kanji', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
        getRadical: const Radical(
          id: 0,
          radical: '龜',
          kangxiId: 213,
          strokeCount: 18,
          meaning: 'turtle',
          reading: 'かめ',
          variants: ['亀'],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KanjiView(
            Kanji(
              id: '𪚲'.kanjiCodePoint(),
              kanji: '𪚲',
              meaning: null,
              radical: '龜',
              components: null,
              grade: null,
              strokeCount: 21,
              frequency: null,
              jlpt: null,
              strokes: null,
              compounds: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('𪚲'), findsOne);
      expect(find.text('—\nGrade'), findsOne);
      expect(find.text('—\nRank'), findsOne);
      expect(find.text('21\nStrokes'), findsOne);
      expect(find.text('—\nJLPT'), findsOne);

      expect(find.text('Kanji stroke order'), findsNothing);

      expect(find.text('(no meaning)'), findsOne);
      expect(find.textContaining('Kun reading'), findsNothing);
      expect(find.textContaining('On reading'), findsNothing);
      expect(find.textContaining('Nanori'), findsNothing);

      expect(find.text('Radical #213 - turtle'), findsOne);
      expect(find.text('Other components'), findsNothing);

      expect(find.text('Compounds'), findsNothing);
    });

    testWidgets('Basic kanji', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
        getRadical: const Radical(
          id: 0,
          radical: '手',
          kangxiId: 64,
          strokeCount: 4,
          meaning: 'hand',
          reading: 'て, てへん',
          importance: RadicalImportance.top25,
          variants: ['扌'],
        ),
        getKanjiList: [
          Kanji(
            id: '㓁'.kanjiCodePoint(),
            kanji: '㓁',
            meaning: null,
            radical: '',
            components: null,
            grade: null,
            strokeCount: 3,
            frequency: null,
            jlpt: null,
            strokes: null,
            compounds: null,
          ),
          Kanji(
            id: '木'.kanjiCodePoint(),
            kanji: '木',
            meaning: null,
            radical: '',
            components: null,
            grade: null,
            strokeCount: 3,
            frequency: null,
            jlpt: null,
            strokes: null,
            compounds: null,
          ),
        ],
        getVocabList: [
          Vocab(
            id: 0,
            pos: null,
            common: true,
            frequencyScore: 0,
          )
            ..writings = [
              const VocabWriting(
                id: 0,
                vocabId: 0,
                writing: '探偵',
              ),
            ]
            ..readings = [
              const VocabReading(
                id: 0,
                vocabId: 0,
                reading: 'たんてい',
                readingRomaji: 'tantei',
              ),
            ]
            ..definitions = [
              const VocabDefinition(
                id: 0,
                vocabId: 0,
                definition: 'detective; investigator; sleuth',
                waseieigo: false,
              ),
            ],
        ],
      );

      await tester.pumpWidget(MaterialApp(home: KanjiView(getKanjiBasic())));
      await tester.pumpAndSettle();

      expect(find.text('探'), findsOne);
      expect(find.text('6\nGrade'), findsOne);
      expect(find.text('930\nRank'), findsOne);
      expect(find.text('11\nStrokes'), findsOne);
      expect(find.text('N2\nJLPT'), findsOne);

      expect(find.text('Kanji stroke order'), findsOne);

      expect(find.text('grope; search; look for'), findsOne);
      expect(find.text('さぐる, さがす'), findsOne);
      expect(find.text('タン'), findsOne);
      expect(find.textContaining('Nanori'), findsNothing);

      expect(find.text('Radical #64 - hand'), findsOne);
      expect(find.text('Other components'), findsOne);
      expect(find.text('㓁'), findsOne);
      expect(find.text('木'), findsOne);

      await tester.scrollUntilVisible(find.text('Compounds'), 100);
      expect(find.text('Compounds'), findsOne);
      expect(find.textContaining('探偵'), findsOne);
    });

    testWidgets('7-9 grade kanji', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
        getRadical: const Radical(
          id: 0,
          radical: '二',
          kangxiId: 7,
          strokeCount: 2,
          meaning: 'two',
          reading: 'ニ',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KanjiView(
            Kanji(
              id: '亜'.kanjiCodePoint(),
              kanji: '亜',
              meaning: null,
              radical: '二',
              components: null,
              grade: KanjiGrade.middleSchool,
              strokeCount: 7,
              frequency: null,
              jlpt: null,
              strokes: null,
              compounds: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('亜'), findsOne);
      expect(find.text('7-9\nGrade'), findsOne);
    });
  });
}
