import 'package:sagase/utils/constants.dart' as constants;

class UserBackup {
  final int dictionaryVersion;
  final DateTime timestamp;
  final List<String> myDictionaryLists;
  final List<String> flashcardSets;
  final List<String> vocabSpacedRepetitionData;
  final List<String> kanjiSpacedRepetitionData;

  const UserBackup({
    required this.dictionaryVersion,
    required this.timestamp,
    required this.myDictionaryLists,
    required this.flashcardSets,
    required this.vocabSpacedRepetitionData,
    required this.kanjiSpacedRepetitionData,
  });

  String toJson() {
    return '''{
      "${constants.backupDictionaryVersion}": $dictionaryVersion,
      "${constants.backupTimestamp}": ${timestamp.millisecondsSinceEpoch},
      "${constants.backupMyDictionaryLists}": $myDictionaryLists,
      "${constants.backupFlashcardSets}": $flashcardSets,
      "${constants.backupVocabSpacedRepetitionData}": $vocabSpacedRepetitionData,
      "${constants.backupKanjiSpacedRepetitionData}": $kanjiSpacedRepetitionData
}''';
  }
}
