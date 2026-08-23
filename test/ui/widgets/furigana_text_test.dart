import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/ui/widgets/furigana_text.dart';

void main() {
  testWidgets('Shows reading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: FuriganaText('と 言[い]ってもいい')),
      ),
    );

    expect(find.text('と'), findsOne);
    expect(find.text('言'), findsOne);
    expect(find.text('い'), findsOne);
    expect(find.text('ってもいい'), findsOne);
  });

  testWidgets('Hides reading', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FuriganaText('と 言[い]ってもいい', showReading: false),
        ),
      ),
    );

    expect(find.text('と言ってもいい'), findsOne);
    expect(find.text('い'), findsNothing);
  });
}
