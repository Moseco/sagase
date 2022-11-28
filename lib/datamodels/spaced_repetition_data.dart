import 'package:isar/isar.dart';

part 'spaced_repetition_data.g.dart';

@embedded
class SpacedRepetitionData {
  late int interval;
  late int repetitions;
  late double easeFactor;
  late int dueDate;

  SpacedRepetitionData();

  factory SpacedRepetitionData.initialData() {
    return SpacedRepetitionData()
      ..interval = 0
      ..repetitions = 0
      ..easeFactor = 2.5;
  }
}
