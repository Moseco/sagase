import 'dart:math';
import 'dart:ui';

class RecognizedTextBlock {
  final String text;
  final List<Point<int>> points;
  late List<Offset> offsets;
  bool selected;

  RecognizedTextBlock({
    required this.text,
    required this.points,
    this.selected = false,
  });
}
