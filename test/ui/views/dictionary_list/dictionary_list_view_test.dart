import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/dictionary_list/dictionary_list_view.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../common.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('DictionaryListViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Empty predefined dictionary list', (tester) async {
      getAndRegisterIsarService(getVocabList: [], getKanjiList: []);

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(PredefinedDictionaryList()..name = 'Name'),
        ),
      );

      expect(find.text('Name'), findsOne);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOne);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('Empty dictionary list', (tester) async {
      getAndRegisterIsarService(getVocabList: [], getKanjiList: []);

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(MyDictionaryList()..name = 'My name'),
        ),
      );

      expect(find.text('My name'), findsOneWidget);
      expect(find.byType(IconButton), findsExactly(2));
      expect(find.byType(CircularProgressIndicator), findsOne);

      await tester.pumpAndSettle();

      expect(find.textContaining('This list is currently empty'), findsOne);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('Dictionary list with vocab', (tester) async {
      getAndRegisterIsarService(
        getVocabList: [vocabReadingOnly, vocabBasic],
        getKanjiList: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList()
              ..name = 'Name'
              ..vocab = [0, 1],
          ),
        ),
      );

      expect(find.byType(VocabListItem), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(VocabListItem), findsExactly(2));
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('Dictionary list with kanji', (tester) async {
      getAndRegisterIsarService(
        getVocabList: [],
        getKanjiList: [kanjiBasic],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList()
              ..name = 'Name'
              ..kanji = [2],
          ),
        ),
      );

      expect(find.byType(KanjiListItem), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(KanjiListItem), findsOne);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('Dictionary list with vocab and kanji', (tester) async {
      getAndRegisterIsarService(
        getVocabList: [vocabReadingOnly, vocabBasic],
        getKanjiList: [kanjiBasic],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList()
              ..name = 'Name'
              ..vocab = [0, 1]
              ..kanji = [2],
          ),
        ),
      );

      expect(find.byType(TabBar), findsOne);
      expect(find.byType(VocabListItem), findsNothing);
      expect(find.byType(KanjiListItem), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(VocabListItem), findsExactly(2));
      expect(find.byType(KanjiListItem), findsNothing);

      await tester.tap(find.textContaining('Kanji'));
      await tester.pumpAndSettle();

      expect(find.byType(VocabListItem), findsNothing);
      expect(find.byType(KanjiListItem), findsOne);
    });
  });
}
