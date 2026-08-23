import 'package:flutter/material.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sagase/utils/furigana_utils.dart';

class FuriganaText extends StatelessWidget {
  final String text;
  final bool showReading;
  final TextStyle? style;
  final TextStyle? rubyStyle;
  final TextAlign? textAlign;

  const FuriganaText(
    this.text, {
    this.showReading = true,
    this.style,
    this.rubyStyle,
    this.textAlign,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    late List<RubyTextData> data;
    if (showReading) {
      data = parseFurigana(text)
          .map((pair) => RubyTextData(pair.writing, ruby: pair.reading))
          .toList();
    } else {
      data = [RubyTextData(removeFurigana(text))];
    }

    return RubyText(
      data,
      style: const TextStyle(letterSpacing: 0, height: 1.1).merge(style),
      rubyStyle: rubyStyle,
      textAlign: textAlign,
    );
  }
}
