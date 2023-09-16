import 'package:isar/isar.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

part 'flashcard_set.g.dart';

@Collection()
class FlashcardSet {
  Id id = Isar.autoIncrement;

  late String name;
  bool usingSpacedRepetition = true;
  @enumerated
  FrontType frontType = FrontType.japanese;
  bool vocabShowReading = false;
  bool vocabShowReadingIfRareKanji = true;
  bool vocabShowAlternatives = false;
  bool kanjiShowReading = false;
  bool vocabShowPartsOfSpeech = false;
  late DateTime timestamp;

  int flashcardsCompletedToday = 0;
  int newFlashcardsCompletedToday = 0;

  final predefinedDictionaryListLinks = IsarLinks<PredefinedDictionaryList>();
  final myDictionaryListLinks = IsarLinks<MyDictionaryList>();

  String toBackupJson() {
    return '''{
      "${SagaseDictionaryConstants.backupFlashcardSetId}": $id,
      "${SagaseDictionaryConstants.backupFlashcardSetName}": "$name",
      "${SagaseDictionaryConstants.backupFlashcardSetUsingSpacedRepetition}": $usingSpacedRepetition,
      "${SagaseDictionaryConstants.backupFlashcardSetFrontType}": ${frontType.index},
      "${SagaseDictionaryConstants.backupFlashcardSetVocabShowReading}": $vocabShowReading,
      "${SagaseDictionaryConstants.backupFlashcardSetVocabShowReadingIfRareKanji}": $vocabShowReadingIfRareKanji,
      "${SagaseDictionaryConstants.backupFlashcardSetVocabShowAlternatives}": $vocabShowAlternatives,
      "${SagaseDictionaryConstants.backupFlashcardSetKanjiShowReading}": $kanjiShowReading,
      "${SagaseDictionaryConstants.backupFlashcardSetVocabShowPartsOfSpeech}": $vocabShowPartsOfSpeech,
      "${SagaseDictionaryConstants.backupFlashcardSetTimestamp}": ${timestamp.millisecondsSinceEpoch},
      "${SagaseDictionaryConstants.backupFlashcardSetFlashcardsCompletedToday}": $flashcardsCompletedToday,
      "${SagaseDictionaryConstants.backupFlashcardSetNewFlashcardsCompletedToday}": $newFlashcardsCompletedToday,
      "${SagaseDictionaryConstants.backupFlashcardSetPredefinedDictionaryLists}": ${predefinedDictionaryListLinks.map((e) => e.id).toList()},
      "${SagaseDictionaryConstants.backupFlashcardSetMyDictionaryLists}": ${myDictionaryListLinks.map((e) => e.id).toList()}
}''';
  }

  // IsarLinks must be added manually afterwards
  static FlashcardSet fromBackupJson(Map<String, dynamic> map) {
    return FlashcardSet()
      ..id = map[SagaseDictionaryConstants.backupFlashcardSetId]
      ..name = map[SagaseDictionaryConstants.backupFlashcardSetName]
      ..usingSpacedRepetition =
          map[SagaseDictionaryConstants.backupFlashcardSetUsingSpacedRepetition]
      ..frontType = FrontType.values[
          map[SagaseDictionaryConstants.backupFlashcardSetFrontType] ?? 0]
      ..vocabShowReading =
          map[SagaseDictionaryConstants.backupFlashcardSetVocabShowReading]
      ..vocabShowReadingIfRareKanji = map[SagaseDictionaryConstants
          .backupFlashcardSetVocabShowReadingIfRareKanji]
      ..vocabShowAlternatives =
          map[SagaseDictionaryConstants.backupFlashcardSetVocabShowAlternatives]
      ..kanjiShowReading =
          map[SagaseDictionaryConstants.backupFlashcardSetKanjiShowReading]
      ..vocabShowPartsOfSpeech = map[SagaseDictionaryConstants
              .backupFlashcardSetVocabShowPartsOfSpeech] ??
          false
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(
          map[SagaseDictionaryConstants.backupFlashcardSetTimestamp])
      ..flashcardsCompletedToday = map[
          SagaseDictionaryConstants.backupFlashcardSetFlashcardsCompletedToday]
      ..newFlashcardsCompletedToday = map[SagaseDictionaryConstants
          .backupFlashcardSetNewFlashcardsCompletedToday];
  }
}

enum FrontType {
  japanese,
  english,
}
