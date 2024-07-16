import 'package:isar/isar.dart';
import 'package:sagase/datamodels/isar/dictionary_item.dart';
import 'package:sagase/datamodels/isar/spaced_repetition_data.dart';

part 'kanji.g.dart';

@Collection()
class Kanji extends DictionaryItem {
  late String kanji;

  @Index()
  late String radical;
  List<String>? components;

  // Grade value meaning
  //  1-6: learn in that grade
  //  8: learn in grades 7-9
  byte grade = 255;
  late byte strokeCount;
  int? frequency;
  byte jlpt = 255;

  @Index(type: IndexType.value, caseSensitive: false)
  List<String>? meanings;

  List<String>? onReadings;
  List<String>? kunReadings;
  List<String>? nanori;

  @Index(type: IndexType.value)
  List<String>? readingIndex;

  List<String>? strokes;

  List<int>? compounds;
}
