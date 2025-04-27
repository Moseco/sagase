import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/vocab/vocab_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('VocabViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Basic vocab', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
        getKanjiList: [
          Kanji(
            id: '秋'.kanjiCodePoint(),
            kanji: '秋',
            meaning: 'autumn',
            radical: '秋',
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

      await tester.pumpWidget(MaterialApp(home: VocabView(getVocabFall())));

      // Check temporary kanji information before it is loaded
      // Finds three, one for vocab, one for temporary kanji, and example
      expect(find.textContaining('秋'), findsExactly(3));
      expect(find.textContaining('autumn'), findsExactly(2));

      await tester.pumpAndSettle();

      expect(find.text('あき'), findsOne);
      expect(find.textContaining('秋'), findsExactly(3));

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
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
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

      await tester.pumpWidget(MaterialApp(home: VocabView(getVocabYes())));

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
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: '岩', reading: 'いわ')],
          [const RubyTextPair(writing: '巌', reading: 'いわ')],
          [const RubyTextPair(writing: '磐', reading: 'いわ')],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VocabView(
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
                  writing: '岩',
                  primaryPair: true,
                ),
                const VocabWriting(
                  id: 1,
                  vocabId: 0,
                  writing: '巌',
                  primaryPair: false,
                ),
                const VocabWriting(
                  id: 2,
                  vocabId: 0,
                  writing: '磐',
                  primaryPair: false,
                ),
              ]
              ..readings = [
                const VocabReading(
                  id: 0,
                  vocabId: 0,
                  reading: 'いわ',
                  readingRomaji: 'iwa',
                  primaryPair: true,
                ),
              ]
              ..definitions = [
                const VocabDefinition(
                  id: 0,
                  vocabId: 0,
                  definition: 'rock; boulder',
                  waseieigo: false,
                  pos: [PartOfSpeech.noun],
                ),
              ],
          ),
        ),
      );

      expect(find.text('いわ'), findsExactly(3));
      // Each of these finds two, one for writing/reading the other from kanji
      expect(find.text('岩'), findsExactly(2));
      expect(find.text('巌'), findsExactly(2));
      expect(find.text('磐'), findsExactly(2));
    });

    testWidgets('Vocab with one kanji and multiple readings', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: 'いつでも')],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VocabView(
            Vocab(
              id: 0,
              pos: null,
              common: true,
              frequencyScore: 140148,
            )
              ..writings = [
                const VocabWriting(
                  id: 0,
                  vocabId: 0,
                  writing: '何時でも',
                  primaryPair: true,
                ),
              ]
              ..readings = [
                const VocabReading(
                  id: 0,
                  vocabId: 0,
                  reading: 'いつでも',
                  readingRomaji: 'itsudemo',
                  primaryPair: true,
                ),
                const VocabReading(
                  id: 1,
                  vocabId: 0,
                  reading: 'なんどきでも',
                  readingRomaji: 'nandekidemo',
                  primaryPair: false,
                ),
              ]
              ..definitions = [
                const VocabDefinition(
                  id: 0,
                  vocabId: 0,
                  definition: 'always; all the time; at all times',
                  waseieigo: false,
                  pos: [PartOfSpeech.noun],
                  miscInfo: [MiscellaneousInfo.usuallyKanaAlone],
                ),
              ],
          ),
        ),
      );

      expect(find.text('いつでも'), findsOne);
      expect(find.text('何時でも【いつでも, なんどきでも】'), findsOne);
    });

    testWidgets('Vocab with multiple kanji and readings', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: '有様', reading: 'ありさま')],
          [
            const RubyTextPair(writing: '有', reading: 'あ'),
            const RubyTextPair(writing: 'りさま'),
          ],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VocabView(
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
                  writing: '有様',
                  primaryPair: true,
                ),
                const VocabWriting(
                  id: 1,
                  vocabId: 0,
                  writing: '有り様',
                  primaryPair: false,
                ),
                const VocabWriting(
                  id: 2,
                  vocabId: 0,
                  writing: 'あり様',
                  primaryPair: false,
                ),
                const VocabWriting(
                  id: 3,
                  vocabId: 0,
                  writing: '有りさま',
                  primaryPair: false,
                ),
              ]
              ..readings = [
                const VocabReading(
                  id: 0,
                  vocabId: 0,
                  reading: 'ありさま',
                  readingRomaji: 'arisama',
                  primaryPair: true,
                ),
                const VocabReading(
                  id: 1,
                  vocabId: 0,
                  reading: 'ありよう',
                  readingRomaji: 'ariyou',
                  primaryPair: false,
                  associatedWritings: [
                    '有様',
                    '有り様',
                    'あり様',
                  ],
                ),
              ]
              ..definitions = [
                const VocabDefinition(
                  id: 0,
                  vocabId: 0,
                  definition:
                      'state; condition; circumstances; sight; spectacle',
                  waseieigo: false,
                  pos: [PartOfSpeech.noun],
                ),
              ],
          ),
        ),
      );

      expect(find.text('有様'), findsOne);
      expect(find.text('有様, 有り様, あり様【ありさま, ありよう】'), findsOne);
      // The text is split because of ruby text. 有 finds 2, one from alternatives and one from kanji
      expect(find.text('有'), findsExactly(2));
      expect(find.text('りさま'), findsOne);
    });

    testWidgets('Vocab with kanji/reading info', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
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

      await tester.pumpWidget(
        MaterialApp(
          home: VocabView(
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
                  writing: '機嫌',
                  primaryPair: true,
                ),
                const VocabWriting(
                  id: 1,
                  vocabId: 0,
                  writing: '譏嫌',
                  primaryPair: false,
                  info: [WritingInfo.outdatedKanji],
                ),
                const VocabWriting(
                  id: 2,
                  vocabId: 0,
                  writing: '気嫌',
                  primaryPair: false,
                  info: [WritingInfo.irregularKanji],
                ),
              ]
              ..readings = [
                const VocabReading(
                  id: 0,
                  vocabId: 0,
                  reading: 'きげん',
                  readingRomaji: 'kigen',
                  primaryPair: true,
                ),
              ]
              ..definitions = [
                const VocabDefinition(
                  id: 0,
                  vocabId: 0,
                  definition: 'humour; humor; temper; mood; spirits',
                  waseieigo: false,
                  pos: [PartOfSpeech.noun],
                ),
              ],
          ),
        ),
      );

      expect(find.text('機嫌'), findsOne);
      expect(find.text('譏嫌'), findsOne);
      expect(find.text('気嫌'), findsOne);
      // One for each writing/reading pair
      expect(find.text('きげん'), findsExactly(3));

      expect(find.text('譏嫌: outdated kanji'), findsOne);
      expect(find.text('気嫌: irregular kanji'), findsOne);
    });

    testWidgets('Vocab with antonym', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [
            const RubyTextPair(writing: '暑', reading: 'あつ'),
            const RubyTextPair(writing: 'い'),
          ],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VocabView(
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
                  writing: '暑い',
                  primaryPair: true,
                ),
              ]
              ..readings = [
                const VocabReading(
                  id: 0,
                  vocabId: 0,
                  reading: 'あつい',
                  readingRomaji: 'atsui',
                  primaryPair: true,
                ),
              ]
              ..definitions = [
                const VocabDefinition(
                  id: 0,
                  vocabId: 0,
                  definition: 'hot; warm; sultry; heated',
                  waseieigo: false,
                  pos: [PartOfSpeech.noun],
                  antonyms: [
                    VocabReference(
                      ids: [0],
                      text: '寒い',
                    ),
                  ],
                ),
              ],
          ),
        ),
      );

      expect(find.textContaining('antonym: 寒い'), findsOne);
    });

    testWidgets('Vocab with cross references', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
      getAndRegisterMecabService(
        createRubyTextPairs: [
          [const RubyTextPair(writing: 'ここ')],
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: VocabView(
            Vocab(
              id: 0,
              pos: null,
              common: true,
              frequencyScore: 0,
            )
              ..readings = [
                const VocabReading(
                  id: 0,
                  vocabId: 0,
                  reading: 'ここ',
                  readingRomaji: 'koko',
                  primaryPair: true,
                ),
              ]
              ..definitions = [
                const VocabDefinition(
                  id: 0,
                  vocabId: 0,
                  definition: 'here; this place',
                  waseieigo: false,
                  pos: [PartOfSpeech.noun],
                  crossReferences: [
                    VocabReference(
                      ids: [0],
                      text: 'そこ',
                    ),
                    VocabReference(
                      ids: [1],
                      text: 'あそこ',
                    ),
                    VocabReference(
                      ids: [2],
                      text: 'どこ',
                    ),
                  ],
                ),
              ],
          ),
        ),
      );

      expect(find.textContaining('see also: そこ, あそこ, どこ'), findsOne);
    });
  });
}
