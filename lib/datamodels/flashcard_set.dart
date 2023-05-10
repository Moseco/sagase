import 'package:isar/isar.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/predefined_dictionary_list.dart';
import 'package:sagase/utils/constants.dart' as constants;

part 'flashcard_set.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class FlashcardSet {
  Id id = Isar.autoIncrement;

  late String name;
  bool usingSpacedRepetition = true;
  bool vocabShowReading = false;
  bool vocabShowReadingIfRareKanji = true;
  bool vocabShowAlternatives = false;
  bool kanjiShowReading = false;
  late DateTime timestamp;

  int flashcardsCompletedToday = 0;
  int newFlashcardsCompletedToday = 0;

  final predefinedDictionaryListLinks = IsarLinks<PredefinedDictionaryList>();
  final myDictionaryListLinks = IsarLinks<MyDictionaryList>();

  String toBackupJson() {
    return '''{
      "${constants.backupFlashcardSetId}": $id,
      "${constants.backupFlashcardSetName}": "$name",
      "${constants.backupFlashcardSetUsingSpacedRepetition}": $usingSpacedRepetition,
      "${constants.backupFlashcardSetVocabShowReading}": $vocabShowReading,
      "${constants.backupFlashcardSetVocabShowReadingIfRareKanji}": $vocabShowReadingIfRareKanji,
      "${constants.backupFlashcardSetVocabShowAlternatives}": $vocabShowAlternatives,
      "${constants.backupFlashcardSetKanjiShowReading}": $kanjiShowReading,
      "${constants.backupFlashcardSetTimestamp}": ${timestamp.millisecondsSinceEpoch},
      "${constants.backupFlashcardSetFlashcardsCompletedToday}": $flashcardsCompletedToday,
      "${constants.backupFlashcardSetNewFlashcardsCompletedToday}": $newFlashcardsCompletedToday,
      "${constants.backupFlashcardSetPredefinedDictionaryLists}": ${predefinedDictionaryListLinks.map((e) => e.id).toList()},
      "${constants.backupFlashcardSetMyDictionaryLists}": ${myDictionaryListLinks.map((e) => e.id).toList()}
}''';
  }

  // IsarLinks must be added manually afterwards
  static FlashcardSet fromBackupJson(Map<String, dynamic> map) {
    return FlashcardSet()
      ..id = map[constants.backupFlashcardSetId]
      ..name = map[constants.backupFlashcardSetName]
      ..usingSpacedRepetition =
          map[constants.backupFlashcardSetUsingSpacedRepetition]
      ..vocabShowReading = map[constants.backupFlashcardSetVocabShowReading]
      ..vocabShowReadingIfRareKanji =
          map[constants.backupFlashcardSetVocabShowReadingIfRareKanji]
      ..vocabShowAlternatives =
          map[constants.backupFlashcardSetVocabShowAlternatives]
      ..kanjiShowReading = map[constants.backupFlashcardSetKanjiShowReading]
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(
          map[constants.backupFlashcardSetTimestamp])
      ..flashcardsCompletedToday =
          map[constants.backupFlashcardSetFlashcardsCompletedToday]
      ..newFlashcardsCompletedToday =
          map[constants.backupFlashcardSetNewFlashcardsCompletedToday];
  }
}
