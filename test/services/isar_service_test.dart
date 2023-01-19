import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('IsarServiceTest', () {
    test('transferUserDataIsolate test', () async {
      // Create old db to upgrade from
      Isar oldIsar = await setUpIsar();

      await oldIsar.writeTxn(() async {
        final vocab1 = Vocab()..id = 1;
        final vocab2 = Vocab()..id = 2;
        final vocab3 = Vocab()
          ..id = 3
          ..spacedRepetitionData = SpacedRepetitionData.initialData();
        vocab3.spacedRepetitionData!.dueDate = 0;
        final kanji1 = Kanji()
          ..id = 1
          ..kanji = '1'
          ..radical = 0
          ..strokeCount = 0;
        final kanji2 = Kanji()
          ..id = 2
          ..kanji = '2'
          ..radical = 0
          ..strokeCount = 0;
        final kanji3 = Kanji()
          ..id = 3
          ..kanji = '3'
          ..radical = 0
          ..strokeCount = 0
          ..spacedRepetitionData = SpacedRepetitionData.initialData();
        kanji3.spacedRepetitionData!.dueDate = 0;

        await oldIsar.vocabs.put(vocab1);
        await oldIsar.vocabs.put(vocab2);
        await oldIsar.vocabs.put(vocab3);

        await oldIsar.kanjis.put(kanji1);
        await oldIsar.kanjis.put(kanji2);
        await oldIsar.kanjis.put(kanji3);

        final myList = MyDictionaryList()
          ..id = 0
          ..name = 'list'
          ..timestamp = DateTime.now();
        await oldIsar.myDictionaryLists.put(myList);
        myList.vocabLinks.add(vocab3);
        await myList.vocabLinks.save();
        myList.kanjiLinks.add(kanji1);
        await myList.kanjiLinks.save();

        final flashcardSet = FlashcardSet()
          ..id = 0
          ..name = 'set'
          ..timestamp = DateTime.now()
          ..kanjiShowReading = true;
        await oldIsar.flashcardSets.put(flashcardSet);
        flashcardSet.myDictionaryListLinks.add(myList);
        await flashcardSet.myDictionaryListLinks.save();
      });

      // Create new db to upgrade to
      Isar newIsar = await setUpIsar();

      await newIsar.writeTxn(() async {
        final vocab1 = Vocab()..id = 1;
        final vocab2 = Vocab()..id = 2;
        final vocab3 = Vocab()..id = 3;
        final kanji1 = Kanji()
          ..id = 1
          ..kanji = '1'
          ..radical = 0
          ..strokeCount = 0;
        final kanji2 = Kanji()
          ..id = 2
          ..kanji = '2'
          ..radical = 0
          ..strokeCount = 0;
        final kanji3 = Kanji()
          ..id = 3
          ..kanji = '3'
          ..radical = 0
          ..strokeCount = 0;

        await newIsar.vocabs.put(vocab1);
        await newIsar.vocabs.put(vocab2);
        await newIsar.vocabs.put(vocab3);

        await newIsar.kanjis.put(kanji1);
        await newIsar.kanjis.put(kanji2);
        await newIsar.kanjis.put(kanji3);
      });

      // Call actual function
      await IsarService.transferUserDataIsolate(
        null,
        testingOldIsar: oldIsar,
        testingNewIsar: newIsar,
      );

      // Verify result
      final vocab = await newIsar.vocabs.get(3);
      expect(vocab!.spacedRepetitionData != null, true);
      expect(vocab.spacedRepetitionData!.dueDate, 0);
      final kanji = await newIsar.kanjis.get(3);
      expect(kanji!.spacedRepetitionData != null, true);
      expect(kanji.spacedRepetitionData!.dueDate, 0);

      final myList = await newIsar.myDictionaryLists.get(0);
      expect(myList!.name, 'list');
      expect(myList.vocabLinks.length, 1);
      expect(myList.kanjiLinks.length, 1);

      final flashcardSet = await newIsar.flashcardSets.get(0);
      expect(flashcardSet!.name, 'set');
      expect(flashcardSet.kanjiShowReading, true);
      expect(flashcardSet.myDictionaryListLinks.length, 1);

      // Cleanup
      await oldIsar.close(deleteFromDisk: true);
      await newIsar.close(deleteFromDisk: true);
    });
  });
}
