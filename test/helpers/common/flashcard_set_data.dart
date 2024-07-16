import 'package:sagase_dictionary/sagase_dictionary.dart';

FlashcardSet createDefaultFlashcardSet({int id = 0, String name = 'Set'}) {
  return FlashcardSet(
    id: id,
    name: name,
    usingSpacedRepetition: true,
    frontType: FrontType.japanese,
    vocabShowReading: false,
    vocabShowReadingIfRareKanji: true,
    vocabShowAlternatives: false,
    vocabShowPitchAccent: false,
    kanjiShowReading: false,
    vocabShowPartsOfSpeech: false,
    timestamp: DateTime.now(),
    flashcardsCompletedToday: 0,
    newFlashcardsCompletedToday: 0,
    predefinedDictionaryLists: [],
    myDictionaryLists: [],
  );
}
