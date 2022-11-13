import 'package:isar/isar.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';

abstract class DictionaryList {
  Id? id;

  late String name;

  IsarLinks<Vocab> get vocabLinks;
  IsarLinks<Kanji> get kanjiLinks;
}
