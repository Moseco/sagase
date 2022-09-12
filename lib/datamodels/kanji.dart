import 'package:isar/isar.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/vocab.dart';

part 'kanji.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class Kanji extends DictionaryItem {
  late Id id;

  @Index(unique: true)
  late String kanji;

  late byte radical;
  byte grade = 255;
  late byte strokeCount;
  final variants = IsarLinks<Kanji>();
  int? frequency;
  byte jlpt = 255;

  String? meanings;
  List<String>? onReadings;
  List<String>? kunReadings;
  List<String>? nanori;

  final compounds = IsarLinks<Vocab>();
}
