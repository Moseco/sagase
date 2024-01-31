import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/kanji/kanji_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../common.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('KanjiViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Low information kanji', (tester) async {
      getAndRegisterIsarService(
        isKanjiInMyDictionaryLists: false,
        getKanjiRadical: KanjiRadical()
          ..radical = '龜'
          ..kangxiId = 213
          ..meaning = 'turtle'
          ..reading = 'かめ'
          ..variants = ['亀'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KanjiView(
            Kanji()
              ..kanji = '𪚲'
              ..radical = '龜'
              ..strokeCount = 21,
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
      getAndRegisterIsarService(
        isKanjiInMyDictionaryLists: false,
        getKanjiRadical: KanjiRadical()
          ..radical = '手'
          ..kangxiId = 64
          ..strokeCount = 4
          ..meaning = 'hand'
          ..reading = 'て, てへん'
          ..importance = KanjiRadicalImportance.top25
          ..strokeCount = 4
          ..variants = ['扌'],
        getKanjiList: [Kanji()..kanji = '㓁', Kanji()..kanji = '木'],
        getVocabList: [
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [VocabKanji()..kanji = '探偵']
                ..readings = [VocabReading()..reading = 'たんてい']
            ]
            ..definitions = [
              VocabDefinition()..definition = 'detective; investigator; sleuth'
            ]
        ],
      );

      await tester.pumpWidget(MaterialApp(home: KanjiView(kanjiBasic)));
      await tester.pumpAndSettle();

      expect(find.text('探'), findsOne);
      expect(find.text('6\nGrade'), findsOne);
      expect(find.text('930\nRank'), findsOne);
      expect(find.text('11\nStrokes'), findsOne);
      expect(find.text('N2\nJLPT'), findsOne);

      expect(find.text('Kanji stroke order'), findsOne);

      expect(find.text('grope, search, look for'), findsOne);
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
      getAndRegisterIsarService(
        isKanjiInMyDictionaryLists: false,
        getKanjiRadical: KanjiRadical()
          ..radical = '二'
          ..kangxiId = 7
          ..meaning = 'two'
          ..reading = 'ニ',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: KanjiView(
            Kanji()
              ..kanji = '亜'
              ..radical = '二'
              ..strokeCount = 7
              ..grade = 8,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('亜'), findsOne);
      expect(find.text('7-9\nGrade'), findsOne);
    });
  });
}
