import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:sagase/datamodels/isar/dictionary_list.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart'
    show SagaseDictionaryConstants;

part 'my_dictionary_list.g.dart';

@Collection()
class MyDictionaryList extends DictionaryList {
  late DateTime timestamp;

  @Index()
  List<int> vocab = [];
  @Index()
  List<int> kanji = [];

  @override
  List<int> getVocab() => vocab;
  @override
  List<int> getKanji() => kanji;

  String toBackupJson() {
    return jsonEncode(
      {
        SagaseDictionaryConstants.backupMyDictionaryListId: id,
        SagaseDictionaryConstants.backupMyDictionaryListName: name,
        SagaseDictionaryConstants.backupMyDictionaryListTimestamp:
            timestamp.millisecondsSinceEpoch,
        SagaseDictionaryConstants.backupMyDictionaryListVocab: vocab,
        SagaseDictionaryConstants.backupMyDictionaryListKanji: kanji
      },
    );
  }

  static MyDictionaryList fromBackupJson(String json) {
    final map = jsonDecode(json);

    return MyDictionaryList()
      ..id = map[SagaseDictionaryConstants.backupMyDictionaryListId]
      ..name = map[SagaseDictionaryConstants.backupMyDictionaryListName]
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(
          map[SagaseDictionaryConstants.backupMyDictionaryListTimestamp])
      ..vocab =
          map[SagaseDictionaryConstants.backupMyDictionaryListVocab].cast<int>()
      ..kanji = map[SagaseDictionaryConstants.backupMyDictionaryListKanji]
          .cast<int>();
  }

  String toShareJson() {
    return jsonEncode(
      {
        SagaseDictionaryConstants.exportType:
            SagaseDictionaryConstants.exportTypeMyList,
        SagaseDictionaryConstants.exportMyListName: name,
        SagaseDictionaryConstants.exportMyListVocab: vocab,
        SagaseDictionaryConstants.exportMyListKanji: kanji,
      },
    );
  }

  static MyDictionaryList? fromShareJson(String json) {
    final map = jsonDecode(json);

    // Verify contents
    if (map[SagaseDictionaryConstants.exportType] !=
            SagaseDictionaryConstants.exportTypeMyList ||
        map[SagaseDictionaryConstants.exportMyListName] == null ||
        map[SagaseDictionaryConstants.exportMyListVocab] == null ||
        map[SagaseDictionaryConstants.exportMyListKanji] == null) {
      return null;
    }

    return MyDictionaryList()
      ..name = map[SagaseDictionaryConstants.exportMyListName]
      ..vocab = map[SagaseDictionaryConstants.exportMyListVocab].cast<int>()
      ..kanji = map[SagaseDictionaryConstants.exportMyListKanji].cast<int>();
  }
}
