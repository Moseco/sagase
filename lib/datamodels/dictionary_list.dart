import 'package:isar/isar.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';

part 'dictionary_list.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class DictionaryList {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime timestamp;
  bool editable = true;

  final vocab = IsarLinks<Vocab>();
  final kanji = IsarLinks<Kanji>();
}
