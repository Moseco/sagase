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
    showNote: false,
    timestamp: DateTime.now(),
    predefinedDictionaryLists: [],
    myDictionaryLists: [],
    streak: 0,
  );
}
