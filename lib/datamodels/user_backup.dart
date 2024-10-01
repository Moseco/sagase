import 'dart:convert';

import 'package:sagase_dictionary/sagase_dictionary.dart';

class UserBackup {
  final int dictionaryVersion;
  final DateTime timestamp;
  final List<String> myDictionaryLists;
  final List<String> flashcardSets;
  final List<String> flashcardSetReports;
  final Map<String, dynamic> vocabSpacedRepetitionData;
  final Map<String, dynamic> vocabSpacedRepetitionDataEnglish;
  final Map<String, dynamic> kanjiSpacedRepetitionData;
  final Map<String, dynamic> kanjiSpacedRepetitionDataEnglish;
  final List<String> searchHistory;
  final List<String> textAnalysisHistory;

  const UserBackup({
    required this.dictionaryVersion,
    required this.timestamp,
    required this.myDictionaryLists,
    required this.flashcardSets,
    required this.flashcardSetReports,
    required this.vocabSpacedRepetitionData,
    required this.vocabSpacedRepetitionDataEnglish,
    required this.kanjiSpacedRepetitionData,
    required this.kanjiSpacedRepetitionDataEnglish,
    required this.searchHistory,
    required this.textAnalysisHistory,
  });

  String toBackupJson() {
    return jsonEncode(
      {
        SagaseDictionaryConstants.exportType:
            SagaseDictionaryConstants.exportTypeBackup,
        SagaseDictionaryConstants.backupDictionaryVersion: dictionaryVersion,
        SagaseDictionaryConstants.backupTimestamp:
            timestamp.millisecondsSinceEpoch,
        SagaseDictionaryConstants.backupMyDictionaryLists: myDictionaryLists,
        SagaseDictionaryConstants.backupFlashcardSets: flashcardSets,
        SagaseDictionaryConstants.backupFlashcardSetReports:
            flashcardSetReports,
        SagaseDictionaryConstants.backupVocabSpacedRepetitionData:
            vocabSpacedRepetitionData,
        SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish:
            vocabSpacedRepetitionDataEnglish,
        SagaseDictionaryConstants.backupKanjiSpacedRepetitionData:
            kanjiSpacedRepetitionData,
        SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish:
            kanjiSpacedRepetitionDataEnglish,
        SagaseDictionaryConstants.backupSearchHistory: searchHistory,
        SagaseDictionaryConstants.backupTextAnalysisHistory:
            textAnalysisHistory,
      },
    );
  }

  static UserBackup? fromBackupJson(String json) {
    final map = jsonDecode(json);

    // Verify that json is a backup
    if (map[SagaseDictionaryConstants.exportType] !=
        SagaseDictionaryConstants.exportTypeBackup) {
      return null;
    }

    return UserBackup(
      dictionaryVersion: map[SagaseDictionaryConstants.backupDictionaryVersion],
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          map[SagaseDictionaryConstants.backupTimestamp]),
      myDictionaryLists:
          map[SagaseDictionaryConstants.backupMyDictionaryLists].cast<String>(),
      flashcardSets:
          map[SagaseDictionaryConstants.backupFlashcardSets].cast<String>(),
      flashcardSetReports:
          (map[SagaseDictionaryConstants.backupFlashcardSetReports] ?? [])
              .cast<String>(),
      vocabSpacedRepetitionData:
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData]
              .cast<String, dynamic>(),
      vocabSpacedRepetitionDataEnglish:
          map[SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish]
              .cast<String, dynamic>(),
      kanjiSpacedRepetitionData:
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData]
              .cast<String, dynamic>(),
      kanjiSpacedRepetitionDataEnglish:
          map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish]
              .cast<String, dynamic>(),
      searchHistory: (map[SagaseDictionaryConstants.backupSearchHistory] ?? [])
          .cast<String>(),
      textAnalysisHistory:
          (map[SagaseDictionaryConstants.backupTextAnalysisHistory] ?? [])
              .cast<String>(),
    );
  }
}
