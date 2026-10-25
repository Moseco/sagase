import 'package:flutter/services.dart';
import 'package:sagase/utils/romaji_converter.dart';

class HiraganaInputFormatter extends TextInputFormatter {
  const HiraganaInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursor = newValue.selection.isValid
        ? newValue.selection.extentOffset.clamp(0, newValue.text.length)
        : newValue.text.length;
    final before = romajiToHiragana(newValue.text.substring(0, cursor));
    final after = romajiToHiragana(newValue.text.substring(cursor));
    final text = before + after;

    if (text == newValue.text) return newValue;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }
}
