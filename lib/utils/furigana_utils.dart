import 'package:sagase_dictionary/sagase_dictionary.dart';

/// Converts Japanese text written in the Anki furigana format into pairs.
///
/// Text within brackets is the reading of the text that precedes it. A space
/// separates the text the reading applies to from what comes before it. If
/// there is no preceding space, the reading applies to everything from the
/// start of the text. For example `例[たと]えば` and `と 言[い]ってもいい`.
List<RubyTextPair> parseFurigana(String text) {
  List<RubyTextPair> pairs = [];
  final plain = StringBuffer();
  final segment = StringBuffer();

  void addPlain(String string) {
    if (string.isEmpty) return;
    pairs.add(RubyTextPair(writing: string));
  }

  int i = 0;
  while (i < text.length) {
    final character = text[i];
    if (character == ' ') {
      plain.write(segment);
      segment.clear();
      i++;
    } else if (character == '[') {
      final closingIndex = text.indexOf(']', i + 1);
      if (closingIndex == -1) {
        segment.write(text.substring(i));
        break;
      }
      final reading = text.substring(i + 1, closingIndex);
      if (reading.isEmpty || segment.isEmpty) {
        segment.write(text.substring(i, closingIndex + 1));
      } else {
        addPlain(plain.toString());
        plain.clear();
        pairs.add(RubyTextPair(writing: segment.toString(), reading: reading));
        segment.clear();
      }
      i = closingIndex + 1;
    } else {
      segment.write(character);
      i++;
    }
  }

  plain.write(segment);
  addPlain(plain.toString());

  return pairs;
}

/// Returns Anki furigana formatted text without any of the readings.
String removeFurigana(String text) =>
    parseFurigana(text).map((pair) => pair.writing).join();
