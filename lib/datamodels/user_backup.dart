import 'package:sagase_dictionary/sagase_dictionary.dart';

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
      "${SagaseDictionaryConstants.backupDictionaryVersion}": $dictionaryVersion,
      "${SagaseDictionaryConstants.backupTimestamp}": ${timestamp.millisecondsSinceEpoch},
      "${SagaseDictionaryConstants.backupMyDictionaryLists}": $myDictionaryLists,
      "${SagaseDictionaryConstants.backupFlashcardSets}": $flashcardSets,
      "${SagaseDictionaryConstants.backupVocabSpacedRepetitionData}": $vocabSpacedRepetitionData,
      "${SagaseDictionaryConstants.backupKanjiSpacedRepetitionData}": $kanjiSpacedRepetitionData
}''';
  }
}
