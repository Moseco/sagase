import 'package:isar/isar.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';

abstract class DictionaryItem {
  late Id id;

  SpacedRepetitionData? spacedRepetitionData;
}
