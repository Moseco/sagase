import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/utils/hiragana_input_formatter.dart';

void main() {
  group('HiraganaInputFormatterTest', () {
    const formatter = HiraganaInputFormatter();

    TextEditingValue format(String text, int cursor) {
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: cursor),
        ),
      );
    }

    test('Converts while typing', () {
      final value = format('nomu', 4);
      expect(value.text, 'のむ');
      expect(value.selection, const TextSelection.collapsed(offset: 2));
    });

    test('Keeps incomplete romaji', () {
      final value = format('のmimas', 6);
      expect(value.text, 'のみまs');
      expect(value.selection, const TextSelection.collapsed(offset: 4));
    });

    test('Unchanged text is returned as is', () {
      const value = TextEditingValue(
        text: 'のk',
        selection: TextSelection.collapsed(offset: 2),
      );
      expect(formatter.formatEditUpdate(TextEditingValue.empty, value), value);
    });

    test('Cursor in the middle of the text', () {
      // Typed "ma" between の and む
      final value = format('のmaむ', 3);
      expect(value.text, 'のまむ');
      expect(value.selection, const TextSelection.collapsed(offset: 2));
    });
  });
}
