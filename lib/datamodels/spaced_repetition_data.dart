import 'package:isar/isar.dart';
import 'package:sagase/utils/constants.dart' as constants;

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
      ..initialCorrectCount = (initialCorrectCount + change).clamp(0, 3);
  }

  String toBackupJson({int? vocabId, String? kanji}) {
    assert(vocabId != null || kanji != null);

    return '''{
      ${vocabId != null ? '"${constants.backupSpacedRepetitionDataVocabId}": $vocabId' : '"${constants.backupSpacedRepetitionDataKanji}": "$kanji"'},
      "${constants.backupSpacedRepetitionDataInterval}": $interval,
      "${constants.backupSpacedRepetitionDataRepetitions}": $repetitions,
      "${constants.backupSpacedRepetitionDataEaseFactor}": $easeFactor,
      "${constants.backupSpacedRepetitionDataDueDate}": $dueDate,
      "${constants.backupSpacedRepetitionDataTotalAnswers}": $totalAnswers,
      "${constants.backupSpacedRepetitionDataTotalWrongAnswers}": $totalWrongAnswers
}''';
  }

  static SpacedRepetitionData fromBackupJson(Map<String, dynamic> map) {
    return SpacedRepetitionData()
      ..interval = map[constants.backupSpacedRepetitionDataInterval]
      ..repetitions = map[constants.backupSpacedRepetitionDataRepetitions]
      ..easeFactor = map[constants.backupSpacedRepetitionDataEaseFactor]
      ..dueDate = map[constants.backupSpacedRepetitionDataDueDate]
      ..totalAnswers = map[constants.backupSpacedRepetitionDataTotalAnswers]
      ..totalWrongAnswers =
          map[constants.backupSpacedRepetitionDataTotalWrongAnswers];
  }
}
