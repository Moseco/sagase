import 'package:isar/isar.dart';
import 'package:sagase/datamodels/isar/dictionary_list.dart';

part 'predefined_dictionary_list.g.dart';

@Collection()
class PredefinedDictionaryList extends DictionaryList {
  List<int> vocab = [];
  List<int> kanji = [];

  @override
  List<int> getVocab() => vocab;
  @override
  List<int> getKanji() => kanji;
}
