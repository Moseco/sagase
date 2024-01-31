import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/vocab/vocab_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../common.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('VocabViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Basic vocab', (tester) async {
      getAndRegisterIsarService(
        isVocabInMyDictionaryLists: false,
        getKanji: Kanji()
          ..kanji = '秋'
          ..meanings = ['autumn'],
      );
      getAndRegisterMecabService(
        parseTextList: [
          [
            JapaneseTextToken(
              original: '秋には木の葉が落ちる。',
              base: '秋には木の葉が落ちる。',
              baseReading: '秋には木の葉が落ちる。',
              rubyTextPairs: [const RubyTextPair(writing: '秋には木の葉が落ちる。')],
            ),
          ],
        ],
        createRubyTextPairs: [
          [const RubyTextPair(writing: '秋', reading: 'あき')],
          [const RubyTextPair(writing: '秋', reading: 'あき')],
        ],
      );

      await tester.pumpWidget(MaterialApp(home: VocabView(vocabBasic)));

      // Check temporary kanji information before it is loaded
      // Finds two, one for vocab and one for kanji
      expect(find.text('秋'), findsExactly(2));
      expect(find.text('autumn'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('あき'), findsOne);
      // Finds two, one for vocab and one for kanji
      expect(find.text('秋'), findsExactly(2));

      expect(find.text('Common'), findsOne);

      expect(find.text('noun, adverb'), findsOne);
      expect(find.text('autumn; fall'), findsOne);

      expect(find.text('Kanji'), findsOne);
      expect(find.text('autumn'), findsOne);

      expect(find.text('Examples'), findsOne);
      expect(find.text('秋には木の葉が落ちる。'), findsOne);
      expect(find.text('Leaves fall in the autumn.'), findsOne);
      expect(find.text('Applies to definition 1'), findsOne);
    });

    testWidgets('Vocab with only reading', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        parseTextList: [
          [
            JapaneseTextToken(
              original: '「もしもし、ブラウンさんですか」「はい、そうです」',
              base: '「もしもし、ブラウンさんですか」「はい、そうです」',
              baseReading: '「もしもし、ブラウンさんですか」「はい、そうです」',
              rubyTextPairs: [
                const RubyTextPair(writing: '「もしもし、ブラウンさんですか」「はい、そうです」')
              ],
            ),
          ],
          [
            JapaneseTextToken(
              original: 'はいどうぞ、君が飛行機の中で読む雑誌です。',
              base: 'はいどうぞ、君が飛行機の中で読む雑誌です。',
              baseReading: 'はいどうぞ、君が飛行機の中で読む雑誌です。',
              rubyTextPairs: [
                const RubyTextPair(writing: 'はいどうぞ、君が飛行機の中で読む雑誌です。')
              ],
            ),
          ],
        ],
        createRubyTextPairs: [
          [const RubyTextPair(writing: 'はい')],
          [const RubyTextPair(writing: 'はい')],
        ],
      );

      await tester.pumpWidget(MaterialApp(home: VocabView(vocabReadingOnly)));

      expect(find.text('はい'), findsOne);

      expect(
        find.text('yes; that is correct (polite (teineigo) language)'),
        findsOne,
      );
      expect(find.textContaining('colloquialism'), findsOne);

      expect(find.text('Examples'), findsOne);
      expect(find.text('「もしもし、ブラウンさんですか」「はい、そうです」'), findsOne);
      expect(
        find.text('"Hello, is this Mrs. Brown?" "Yes, this is Mrs. Brown."'),
        findsOne,
      );
      expect(find.text('Applies to definition 1'), findsOne);
      expect(find.text('はいどうぞ、君が飛行機の中で読む雑誌です。'), findsOne);
      expect(
        find.text('Here\'s a magazine for you to read in the plane.'),
        findsOne,
      );
      expect(find.text('Applies to definition 2'), findsOne);
    });

    testWidgets('Vocab with multiple kanji and one reading', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: '岩', reading: 'いわ')],
          [const RubyTextPair(writing: '巌', reading: 'いわ')],
          [const RubyTextPair(writing: '磐', reading: 'いわ')],
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: VocabView(
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [
                  VocabKanji()..kanji = '岩',
                  VocabKanji()..kanji = '巌',
                  VocabKanji()..kanji = '磐',
                ]
                ..readings = [VocabReading()..reading = 'いわ'],
            ]
            ..pos = [PartOfSpeech.noun]
            ..definitions = [VocabDefinition()..definition = 'rock; boulder'],
        ),
      ));

      expect(find.text('いわ'), findsExactly(3));
      // Each of these finds two, one for writing/reading the other from kanji
      expect(find.text('岩'), findsExactly(2));
      expect(find.text('巌'), findsExactly(2));
      expect(find.text('磐'), findsExactly(2));
    });

    testWidgets('Vocab with one kanji and multiple readings', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: 'いつでも')],
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: VocabView(
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [VocabKanji()..kanji = '何時でも']
                ..readings = [
                  VocabReading()..reading = 'いつでも',
                  VocabReading()..reading = 'なんどきでも',
                ],
            ]
            ..pos = [PartOfSpeech.noun]
            ..definitions = [
              VocabDefinition()
                ..definition = 'always; all the time; at all times'
                ..miscInfo = [MiscellaneousInfo.usuallyKanaAlone],
            ],
        ),
      ));

      expect(find.text('いつでも'), findsOne);
      expect(find.text('何時でも【いつでも, なんどきでも】'), findsOne);
    });

    testWidgets('Vocab with multiple kanji and readings', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: '有様', reading: 'ありさま')],
          [
            const RubyTextPair(writing: '有', reading: 'あ'),
            const RubyTextPair(writing: 'りさま'),
          ],
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: VocabView(
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [
                  VocabKanji()..kanji = '有様',
                  VocabKanji()..kanji = '有り様',
                  VocabKanji()..kanji = 'あり様',
                ]
                ..readings = [
                  VocabReading()..reading = 'ありさま',
                  VocabReading()..reading = 'ありよう',
                ],
              KanjiReadingPair()
                ..kanjiWritings = [VocabKanji()..kanji = '有りさま']
                ..readings = [VocabReading()..reading = 'ありさま'],
            ]
            ..pos = [PartOfSpeech.noun]
            ..definitions = [
              VocabDefinition()
                ..definition =
                    'state; condition; circumstances; sight; spectacle',
            ],
        ),
      ));

      expect(find.text('有様'), findsOne);
      expect(find.text('有様, 有り様, あり様【ありさま, ありよう】'), findsOne);
      // The text is split because of ruby text. 有 finds 2, one from alternatives and one from kanji
      expect(find.text('有'), findsExactly(2));
      expect(find.text('りさま'), findsOne);
    });

    testWidgets('Vocab with kanji/reading info', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [
            const RubyTextPair(writing: '機嫌', reading: 'きげん'),
          ],
          [
            const RubyTextPair(writing: '譏嫌', reading: 'きげん'),
          ],
          [
            const RubyTextPair(writing: '気嫌', reading: 'きげん'),
          ],
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: VocabView(
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [
                  VocabKanji()..kanji = '機嫌',
                  VocabKanji()
                    ..kanji = '譏嫌'
                    ..info = [KanjiInfo.outdatedKanji],
                  VocabKanji()
                    ..kanji = '気嫌'
                    ..info = [KanjiInfo.irregularKanji],
                ]
                ..readings = [VocabReading()..reading = 'きげん'],
            ]
            ..pos = [PartOfSpeech.noun]
            ..definitions = [
              VocabDefinition()
                ..definition = 'humour; humor; temper; mood; spirits',
            ],
        ),
      ));

      expect(find.text('機嫌'), findsOne);
      expect(find.text('譏嫌'), findsOne);
      expect(find.text('気嫌'), findsOne);
      // One for each writing/reading pair
      expect(find.text('きげん'), findsExactly(3));

      expect(find.text('譏嫌: outdated kanji'), findsOne);
      expect(find.text('気嫌: irregular kanji'), findsOne);
    });

    testWidgets('Vocab with antonym', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [
            const RubyTextPair(writing: '暑', reading: 'あつ'),
            const RubyTextPair(writing: 'い'),
          ],
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: VocabView(
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()
                ..kanjiWritings = [VocabKanji()..kanji = '暑い']
                ..readings = [VocabReading()..reading = 'あつい'],
            ]
            ..pos = [PartOfSpeech.noun]
            ..definitions = [
              VocabDefinition()
                ..definition = 'hot; warm; sultry; heated'
                ..antonyms = [
                  VocabReference()
                    ..ids = [0]
                    ..text = '寒い',
                ],
            ],
        ),
      ));

      expect(find.textContaining('antonym: 寒い'), findsOne);
    });

    testWidgets('Vocab with cross references', (tester) async {
      getAndRegisterIsarService(isVocabInMyDictionaryLists: false);
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: 'ここ')],
        ],
      );

      await tester.pumpWidget(MaterialApp(
        home: VocabView(
          Vocab()
            ..kanjiReadingPairs = [
              KanjiReadingPair()..readings = [VocabReading()..reading = 'ここ'],
            ]
            ..pos = [PartOfSpeech.noun]
            ..definitions = [
              VocabDefinition()
                ..definition = 'here; this place'
                ..crossReferences = [
                  VocabReference()
                    ..ids = [0]
                    ..text = 'そこ',
                  VocabReference()
                    ..ids = [1]
                    ..text = 'あそこ',
                  VocabReference()
                    ..ids = [2]
                    ..text = 'どこ',
                ],
            ],
        ),
      ));

      expect(find.textContaining('see also: そこ, あそこ, どこ'), findsOne);
    });
  });
}
