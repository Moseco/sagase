import 'package:isar/isar.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';

part 'predefined_dictionary_list.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class PredefinedDictionaryList extends DictionaryList {
  @override
  final vocabLinks = IsarLinks<Vocab>();
  @override
  final kanjiLinks = IsarLinks<Kanji>();
}
