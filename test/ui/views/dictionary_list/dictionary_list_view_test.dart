import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/views/dictionary_list/dictionary_list_view.dart';
import 'package:sagase/ui/views/dictionary_list/dictionary_list_viewmodel.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/common/kanji_data.dart';
import '../../../helpers/common/vocab_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('DictionaryListViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Empty predefined dictionary list', (tester) async {
      getAndRegisterDictionaryService(getVocabList: [], getKanjiList: []);

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            PredefinedDictionaryList(
              id: 0,
              name: 'Name',
              vocab: [],
              kanji: [],
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOne);
      expect(find.byType(PopupMenuButton<PopupMenuItemType>), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOne);

      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('Empty my dictionary list', (tester) async {
      getAndRegisterDictionaryService(
        getVocabList: [],
        getKanjiList: [],
        watchMyDictionaryListItems: [
          DictionaryItemIdsResult(vocabIds: [], kanjiIds: []),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList(
              id: 0,
              name: 'Name',
              timestamp: DateTime.now(),
            ),
          ),
        ),
      );

      expect(find.text('Name'), findsOneWidget);
      expect(find.byType(PopupMenuButton<PopupMenuItemType>), findsOne);
      expect(find.byType(CircularProgressIndicator), findsOne);

      await tester.pumpAndSettle();

      expect(find.textContaining('This list is currently empty'), findsOne);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('My dictionary list with vocab', (tester) async {
      getAndRegisterDictionaryService(
        getVocabList: [getVocab1(), getVocab2()],
        getKanjiList: [],
        watchMyDictionaryListItems: [
          DictionaryItemIdsResult(vocabIds: [0, 1], kanjiIds: []),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList(
              id: 0,
              name: 'Name',
              timestamp: DateTime.now(),
              vocab: [0, 1],
            ),
          ),
        ),
      );

      expect(find.byType(VocabListItem), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(VocabListItem), findsExactly(2));
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('My dictionary list with kanji', (tester) async {
      getAndRegisterDictionaryService(
        getVocabList: [],
        getKanjiList: [getKanji1()],
        watchMyDictionaryListItems: [
          DictionaryItemIdsResult(vocabIds: [], kanjiIds: [2]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList(
              id: 0,
              name: 'Name',
              timestamp: DateTime.now(),
              kanji: [2],
            ),
          ),
        ),
      );

      expect(find.byType(KanjiListItem), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(KanjiListItem), findsOne);
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('My dictionary list with vocab and kanji', (tester) async {
      getAndRegisterDictionaryService(
        getVocabList: [getVocab1(), getVocab2()],
        getKanjiList: [getKanji1()],
        watchMyDictionaryListItems: [
          DictionaryItemIdsResult(vocabIds: [0, 1], kanjiIds: [2]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DictionaryListView(
            MyDictionaryList(
              id: 0,
              name: 'Name',
              timestamp: DateTime.now(),
              vocab: [0, 1],
              kanji: [2],
            ),
          ),
        ),
      );

      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(VocabListItem), findsNothing);
      expect(find.byType(KanjiListItem), findsNothing);

      await tester.pumpAndSettle();

      expect(find.byType(TabBar), findsOne);
      expect(find.byType(VocabListItem), findsExactly(2));
      expect(find.byType(KanjiListItem), findsNothing);

      await tester.tap(find.textContaining('Kanji'));
      await tester.pumpAndSettle();

      expect(find.byType(VocabListItem), findsNothing);
      expect(find.byType(KanjiListItem), findsOne);
    });
  });
}
