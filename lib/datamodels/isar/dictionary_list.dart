import 'package:isar/isar.dart';

abstract class DictionaryList {
  Id id = Isar.autoIncrement;

  late String name;

  List<int> getVocab();
  List<int> getKanji();
}
