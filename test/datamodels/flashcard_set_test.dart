import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('FlashcardSetTest', () {
    late Isar isar;

    setUp(() async {
      isar = await setUpIsar();
    });

    tearDown(() async {
      await isar.close(deleteFromDisk: true);
    });

    test('Backup', () async {
      final flashcardSet = FlashcardSet();

      final now = DateTime.now();
      await isar.writeTxn(() async {
        // Create and add flashcard set to isar
        flashcardSet
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

        await isar.flashcardSets.put(flashcardSet);

        // Add required dictionary lists to isar and add to flashcard set
        final pre1 = PredefinedDictionaryList()
          ..id = 1
          ..name = 'pre1';
        final pre2 = PredefinedDictionaryList()
          ..id = 2
          ..name = 'pre2';
        final my7 = MyDictionaryList()
          ..id = 7
          ..name = 'my7'
          ..timestamp = now;
        final my8 = MyDictionaryList()
          ..id = 8
          ..name = 'my8'
          ..timestamp = now;

        await isar.predefinedDictionaryLists.put(pre1);
        await isar.predefinedDictionaryLists.put(pre2);
        await isar.myDictionaryLists.put(my7);
        await isar.myDictionaryLists.put(my8);

        flashcardSet.predefinedDictionaryListLinks.add(pre1);
        flashcardSet.predefinedDictionaryListLinks.add(pre2);
        flashcardSet.myDictionaryListLinks.add(my7);
        flashcardSet.myDictionaryListLinks.add(my8);

        await flashcardSet.predefinedDictionaryListLinks.save();
        await flashcardSet.myDictionaryListLinks.save();
      });

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
      expect(newFlashcardSet.predefinedDictionaryLists.length, 3);
      expect(newFlashcardSet.predefinedDictionaryLists.contains(0), true);
      expect(newFlashcardSet.predefinedDictionaryLists.contains(1), true);
      expect(newFlashcardSet.predefinedDictionaryLists.contains(2), true);
      expect(newFlashcardSet.myDictionaryLists.length, 3);
      expect(newFlashcardSet.myDictionaryLists.contains(6), true);
      expect(newFlashcardSet.myDictionaryLists.contains(7), true);
      expect(newFlashcardSet.myDictionaryLists.contains(8), true);
    });
  });
}
