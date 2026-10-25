import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/views/learning/learning_view.dart';

import '../../../helpers/common/flashcard_set_data.dart';
import '../../../helpers/mocks.dart';

void main() {
  group('LearningViewTest', () {
    setUp(() => registerServices());
    tearDown(() => unregisterServices());

    testWidgets('Practice without flashcard sets', (tester) async {
      getAndRegisterDictionaryService(getFlashcardSets: []);
      final navigationService = getAndRegisterNavigationService();

      await tester.pumpWidget(const MaterialApp(home: LearningView()));
      await tester.pumpAndSettle();

      expect(find.textContaining('You have no flashcards yet'), findsOne);
      expect(find.text('Practice'), findsOne);

      await tester.tap(find.text('Kana practice'));
      await tester.pumpAndSettle();
      verify(navigationService.navigateTo(Routes.kanaPracticeView)).called(1);

      await tester.tap(find.text('Conjugation practice'));
      await tester.pumpAndSettle();
      verify(navigationService.navigateTo(Routes.conjugationPracticeView))
          .called(1);
    });

    testWidgets('Practice under flashcard sets', (tester) async {
      getAndRegisterDictionaryService(getFlashcardSets: [
        createDefaultFlashcardSet(id: 0, name: 'Set 1'),
        createDefaultFlashcardSet(id: 1, name: 'Set 2'),
      ]);

      await tester.pumpWidget(const MaterialApp(home: LearningView()));
      await tester.pumpAndSettle();

      expect(find.text('Set 1'), findsOne);
      expect(find.text('Set 2'), findsOne);
      expect(
        tester.getTopLeft(find.text('Practice')).dy,
        greaterThan(tester.getBottomLeft(find.text('Set 2')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Kana practice')).dy,
        greaterThan(tester.getBottomLeft(find.text('Practice')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Conjugation practice')).dy,
        greaterThan(tester.getBottomLeft(find.text('Kana practice')).dy),
      );
    });
  });
}
