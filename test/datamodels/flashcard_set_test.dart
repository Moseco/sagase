import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/flashcard_set.dart';

void main() {
  group('FlashcardSetTest', () {
    test('Backup', () async {
      final now = DateTime.now();
      final flashcardSet = FlashcardSet()
        ..id = 1
        ..name = 'set1'
        ..usingSpacedRepetition = false
        ..frontType = FrontType.english
        ..vocabShowReading = true
        ..vocabShowReadingIfRareKanji = false
        ..vocabShowAlternatives = true
        ..vocabShowPitchAccent = false
        ..kanjiShowReading = true
        ..vocabShowPartsOfSpeech = true
        ..timestamp = now
        ..flashcardsCompletedToday = 1
        ..newFlashcardsCompletedToday = 2
        ..predefinedDictionaryLists = [0, 1]
        ..myDictionaryLists = [6, 7];

      final newFlashcardSet = FlashcardSet.fromBackupJson(
        jsonDecode(flashcardSet.toBackupJson()),
      );

      expect(newFlashcardSet.id, 1);
      expect(newFlashcardSet.name, 'set1');
      expect(newFlashcardSet.usingSpacedRepetition, false);
      expect(newFlashcardSet.frontType, FrontType.english);
      expect(newFlashcardSet.vocabShowReading, true);
      expect(newFlashcardSet.vocabShowReadingIfRareKanji, false);
      expect(newFlashcardSet.vocabShowAlternatives, true);
      expect(newFlashcardSet.vocabShowPitchAccent, false);
      expect(newFlashcardSet.kanjiShowReading, true);
      expect(newFlashcardSet.vocabShowPartsOfSpeech, true);
      expect(newFlashcardSet.timestamp.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch);
      expect(newFlashcardSet.flashcardsCompletedToday, 1);
      expect(newFlashcardSet.newFlashcardsCompletedToday, 2);
      expect(newFlashcardSet.predefinedDictionaryLists.length, 2);
      expect(newFlashcardSet.predefinedDictionaryLists.contains(0), true);
      expect(newFlashcardSet.predefinedDictionaryLists.contains(1), true);
      expect(newFlashcardSet.myDictionaryLists.length, 2);
      expect(newFlashcardSet.myDictionaryLists.contains(6), true);
      expect(newFlashcardSet.myDictionaryLists.contains(7), true);
    });
  });
}
