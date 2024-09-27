import 'dart:convert';

import 'package:isar/isar.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart'
    show SagaseDictionaryConstants;

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
  bool vocabShowPitchAccent = false;
  bool kanjiShowReading = false;
  bool vocabShowPartsOfSpeech = false;
  late DateTime timestamp;

  int flashcardsCompletedToday = 0;
  int newFlashcardsCompletedToday = 0;

  List<int> predefinedDictionaryLists = [];
  List<int> myDictionaryLists = [];

  String toBackupJson() {
    return jsonEncode(
      {
        SagaseDictionaryConstants.backupFlashcardSetId: id,
        SagaseDictionaryConstants.backupFlashcardSetName: name,
        SagaseDictionaryConstants.backupFlashcardSetUsingSpacedRepetition:
            usingSpacedRepetition,
        SagaseDictionaryConstants.backupFlashcardSetFrontType: frontType.index,
        SagaseDictionaryConstants.backupFlashcardSetVocabShowReading:
            vocabShowReading,
        SagaseDictionaryConstants.backupFlashcardSetVocabShowReadingIfRareKanji:
            vocabShowReadingIfRareKanji,
        SagaseDictionaryConstants.backupFlashcardSetVocabShowAlternatives:
            vocabShowAlternatives,
        SagaseDictionaryConstants.backupFlashcardSetVocabShowPitchAccent:
            vocabShowPitchAccent,
        SagaseDictionaryConstants.backupFlashcardSetKanjiShowReading:
            kanjiShowReading,
        SagaseDictionaryConstants.backupFlashcardSetVocabShowPartsOfSpeech:
            vocabShowPartsOfSpeech,
        SagaseDictionaryConstants.backupFlashcardSetTimestamp:
            timestamp.millisecondsSinceEpoch,
        SagaseDictionaryConstants.backupFlashcardSetPredefinedDictionaryLists:
            predefinedDictionaryLists,
        SagaseDictionaryConstants.backupFlashcardSetMyDictionaryLists:
            myDictionaryLists
      },
    );
  }

  static FlashcardSet fromBackupJson(String json) {
    final map = jsonDecode(json);
    return FlashcardSet()
      ..id = map[SagaseDictionaryConstants.backupFlashcardSetId]
      ..name = map[SagaseDictionaryConstants.backupFlashcardSetName]
      ..usingSpacedRepetition =
          map[SagaseDictionaryConstants.backupFlashcardSetUsingSpacedRepetition]
      ..frontType = FrontType
          .values[map[SagaseDictionaryConstants.backupFlashcardSetFrontType]]
      ..vocabShowReading =
          map[SagaseDictionaryConstants.backupFlashcardSetVocabShowReading]
      ..vocabShowReadingIfRareKanji = map[SagaseDictionaryConstants
          .backupFlashcardSetVocabShowReadingIfRareKanji]
      ..vocabShowAlternatives =
          map[SagaseDictionaryConstants.backupFlashcardSetVocabShowAlternatives]
      ..vocabShowPitchAccent =
          map[SagaseDictionaryConstants.backupFlashcardSetVocabShowPitchAccent]
      ..kanjiShowReading =
          map[SagaseDictionaryConstants.backupFlashcardSetKanjiShowReading]
      ..vocabShowPartsOfSpeech = map[
          SagaseDictionaryConstants.backupFlashcardSetVocabShowPartsOfSpeech]
      ..timestamp = DateTime.fromMillisecondsSinceEpoch(
          map[SagaseDictionaryConstants.backupFlashcardSetTimestamp])
      ..predefinedDictionaryLists = map[SagaseDictionaryConstants
              .backupFlashcardSetPredefinedDictionaryLists]
          .cast<int>()
      ..myDictionaryLists =
          map[SagaseDictionaryConstants.backupFlashcardSetMyDictionaryLists]
              .cast<int>();
  }
}

enum FrontType {
  japanese,
  english,
}
