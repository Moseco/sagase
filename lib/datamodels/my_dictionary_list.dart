import 'package:isar/isar.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/utils/constants.dart' as constants;

part 'my_dictionary_list.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class MyDictionaryList extends DictionaryList {
  late DateTime timestamp;

  @override
  final vocabLinks = IsarLinks<Vocab>();
  @override
  final kanjiLinks = IsarLinks<Kanji>();

  String toBackupJson() {
    return '''{
      "${constants.backupMyDictionaryListId}": $id,
      "${constants.backupMyDictionaryListName}": "$name",
      "${constants.backupMyDictionaryListTimestamp}": ${timestamp.millisecondsSinceEpoch},
      "${constants.backupMyDictionaryListVocab}": ${vocabLinks.map((e) => e.id).toList()},
      "${constants.backupMyDictionaryListKanji}": ${kanjiLinks.map((e) => '"${e.kanji}"').toList()}
}''';
  }

  // IsarLinks must be added manually afterwards
  static MyDictionaryList fromBackupJson(Map<String, dynamic> map) {
    return MyDictionaryList()
      ..id = map[constants.backupMyDictionaryListId]
      ..name = map[constants.backupMyDictionaryListName]
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(
          map[constants.backupMyDictionaryListTimestamp]);
  }
}
