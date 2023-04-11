class JapaneseTextToken {
  final String original;
  final String base;
  final List<RubyTextPair> rubyTextPairs;

  const JapaneseTextToken({
    required this.original,
    required this.base,
    required this.rubyTextPairs,
  });
}

class RubyTextPair {
  final String writing;
  final String? reading;

  const RubyTextPair({required this.writing, this.reading});
}
