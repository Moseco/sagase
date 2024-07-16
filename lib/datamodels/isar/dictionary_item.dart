import 'package:isar/isar.dart';
import 'package:sagase/datamodels/isar/spaced_repetition_data.dart';

abstract class DictionaryItem {
  late Id id;

  SpacedRepetitionData? spacedRepetitionData;
  SpacedRepetitionData? spacedRepetitionDataEnglish;

  @ignore
  List<DictionaryItem>? similarFlashcards;
}
