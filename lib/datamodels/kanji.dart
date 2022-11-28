import 'package:isar/isar.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';

part 'kanji.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class Kanji extends DictionaryItem {
  @Index(unique: true)
  late String kanji;

  late byte radical;
  List<String>? components;
  byte grade = 255;
  late byte strokeCount;
  int? frequency;
  byte jlpt = 255;

  String? meanings;
  List<String>? onReadings;
  List<String>? kunReadings;
  List<String>? nanori;

  final compounds = IsarLinks<Vocab>();

  @Backlink(to: 'kanjiLinks')
  final myDictionaryListLinks = IsarLinks<MyDictionaryList>();
}
