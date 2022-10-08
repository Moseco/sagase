class KanjiRadical {
  final String radical;
  final int strokes;
  final String meaning;
  final String? variants;

  const KanjiRadical(
    this.radical,
    this.strokes,
    this.meaning, {
    this.variants,
  });
}
