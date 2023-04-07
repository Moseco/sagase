import 'package:isar/isar.dart';

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
}
