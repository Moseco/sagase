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
}
