import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/views/grammar/grammar_view.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../../../helpers/mocks.dart';

void main() {
  group('GrammarViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Grammar with furigana', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GrammarView(
            Grammar(
              id: 1,
              form: 'が 嫌[きら]い',
              meaning: 'dislike',
              jlptLevel: 5,
              exampleJapanese: '野菜[やさい]が 嫌[きら]いです',
              exampleEnglish: 'I dislike vegetables',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Form and example both show the reading above the kanji
      expect(find.text('が'), findsNWidgets(2));
      expect(find.text('嫌'), findsNWidgets(2));
      expect(find.text('きら'), findsNWidgets(2));
      expect(find.text('い'), findsOne);
      expect(find.text('JLPT N5'), findsOne);

      expect(find.text('Meaning'), findsOne);
      expect(find.text('dislike'), findsOne);

      expect(find.text('Example'), findsOne);
      expect(find.text('野菜'), findsOne);
      expect(find.text('やさい'), findsOne);
      expect(find.text('I dislike vegetables'), findsOne);
    });

    testWidgets('Open example in text analysis', (tester) async {
      getAndRegisterDictionaryService(
        getMyDictionaryListsContainingDictionaryItem: [],
      );
      final navigationService = getAndRegisterNavigationService();

      await tester.pumpWidget(
        MaterialApp(
          home: GrammarView(
            Grammar(
              id: 1,
              form: 'が 嫌[きら]い',
              meaning: 'dislike',
              jlptLevel: 5,
              exampleJapanese: '野菜[やさい]が 嫌[きら]いです',
              exampleEnglish: 'I dislike vegetables',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('I dislike vegetables'));
      await tester.pumpAndSettle();

      // Verify the example was sent without the furigana
      final arguments = verify(
        navigationService.navigateTo(
          Routes.textAnalysisView,
          arguments: captureAnyNamed('arguments'),
        ),
      ).captured.single as TextAnalysisViewArguments;
      expect(arguments.initialText, '野菜が嫌いです');
    });
  });
}
