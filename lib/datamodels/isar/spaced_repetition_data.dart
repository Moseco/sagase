import 'dart:convert';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart'
    show SagaseDictionaryConstants;

part 'spaced_repetition_data.g.dart';

@embedded
class SpacedRepetitionData {
  int interval = 0;
  int repetitions = 0;
  double easeFactor = 2.5;
  int? dueDate;

  int totalAnswers = 0;
  int totalWrongAnswers = 0;
  @ignore
  double get wrongAnswerRate => totalWrongAnswers / totalAnswers;

  @ignore
  int initialCorrectCount = 0;

  // This exists to make sure undo works correctly
  SpacedRepetitionData copyWithInitialCorrectCount(int change) {
    return SpacedRepetitionData()
      ..interval = interval
      ..repetitions = repetitions
      ..easeFactor = easeFactor
      ..dueDate = dueDate
      ..totalAnswers = totalAnswers
      ..totalWrongAnswers = totalWrongAnswers
      ..initialCorrectCount = max(0, (initialCorrectCount + change));
  }

  String toBackupJson() {
    return jsonEncode(
      {
        SagaseDictionaryConstants.backupSpacedRepetitionDataInterval: interval,
        SagaseDictionaryConstants.backupSpacedRepetitionDataRepetitions:
            repetitions,
        SagaseDictionaryConstants.backupSpacedRepetitionDataEaseFactor:
            easeFactor,
        SagaseDictionaryConstants.backupSpacedRepetitionDataDueDate: dueDate,
        SagaseDictionaryConstants.backupSpacedRepetitionDataTotalAnswers:
            totalAnswers,
        SagaseDictionaryConstants.backupSpacedRepetitionDataTotalWrongAnswers:
            totalWrongAnswers
      },
    );
  }

  static SpacedRepetitionData fromBackupJson(Map<String, dynamic> map) {
    return SpacedRepetitionData()
      ..interval =
          map[SagaseDictionaryConstants.backupSpacedRepetitionDataInterval]
      ..repetitions =
          map[SagaseDictionaryConstants.backupSpacedRepetitionDataRepetitions]
      ..easeFactor =
          map[SagaseDictionaryConstants.backupSpacedRepetitionDataEaseFactor]
      ..dueDate =
          map[SagaseDictionaryConstants.backupSpacedRepetitionDataDueDate]
      ..totalAnswers =
          map[SagaseDictionaryConstants.backupSpacedRepetitionDataTotalAnswers]
      ..totalWrongAnswers = map[SagaseDictionaryConstants
          .backupSpacedRepetitionDataTotalWrongAnswers];
  }
}
