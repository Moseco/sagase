import 'package:isar_community/isar.dart';

abstract class DictionaryList {
  Id id = Isar.autoIncrement;

  late String name;

  List<int> getVocab();
  List<int> getKanji();
}
