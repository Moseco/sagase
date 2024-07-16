import 'dart:io';

import 'package:drift/native.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:drift/drift.dart' as drift;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sagase/utils/constants.dart' as constants;
import 'package:path/path.dart' as path;

Future<DictionaryService> setUpDictionaryData({
  bool inMemory = true,
  int dictionaryVersion = SagaseDictionaryConstants.dictionaryVersion,
}) async {
  // Create the database either in memory or at the expected location by the rest of the app
  final database = AppDatabase(
    inMemory
        ? null
        : NativeDatabase(
            File(
              path.join(
                (await path_provider.getApplicationSupportDirectory()).path,
                constants.dictionaryDatabaseFile,
              ),
            ),
          ),
  );
  final service = DictionaryService(database: database);
  await database.batch((batch) {
    // Dictionary info file
    batch.insert(
      database.dictionaryInfos,
      DictionaryInfosCompanion(
        version: drift.Value(dictionaryVersion),
      ),
    );
    // Vocab
    batch.insertAll(
      database.vocabs,
      List.generate(
        50,
        (index) => VocabsCompanion(id: drift.Value(index + 1)),
      ),
    );
    // Vocab writings
    batch.insertAll(
      database.vocabWritings,
      [
        const VocabWritingsCompanion(
          id: drift.Value(1),
          vocabId: drift.Value(1),
          writing: drift.Value('一'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(2),
          vocabId: drift.Value(2),
          writing: drift.Value('二'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(3),
          vocabId: drift.Value(3),
          writing: drift.Value('三'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(4),
          vocabId: drift.Value(4),
          writing: drift.Value('四'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(5),
          vocabId: drift.Value(5),
          writing: drift.Value('五'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(6),
          vocabId: drift.Value(6),
          writing: drift.Value('六'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(7),
          vocabId: drift.Value(7),
          writing: drift.Value('七'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(8),
          vocabId: drift.Value(8),
          writing: drift.Value('八'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(9),
          vocabId: drift.Value(9),
          writing: drift.Value('九'),
        ),
        const VocabWritingsCompanion(
          id: drift.Value(10),
          vocabId: drift.Value(10),
          writing: drift.Value('十'),
        ),
      ],
    );
    // Vocab readings
    batch.insertAll(
      database.vocabReadings,
      [
        const VocabReadingsCompanion(
          id: drift.Value(1),
          vocabId: drift.Value(1),
          reading: drift.Value('いち'),
          readingRomaji: drift.Value('ichi'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(2),
          vocabId: drift.Value(2),
          reading: drift.Value('に'),
          readingRomaji: drift.Value('ni'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(3),
          vocabId: drift.Value(3),
          reading: drift.Value('さん'),
          readingRomaji: drift.Value('san'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(4),
          vocabId: drift.Value(4),
          reading: drift.Value('よん'),
          readingRomaji: drift.Value('yon'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(5),
          vocabId: drift.Value(5),
          reading: drift.Value('ご'),
          readingRomaji: drift.Value('go'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(6),
          vocabId: drift.Value(6),
          reading: drift.Value('ろく'),
          readingRomaji: drift.Value('roku'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(7),
          vocabId: drift.Value(7),
          reading: drift.Value('なな'),
          readingRomaji: drift.Value('nana'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(8),
          vocabId: drift.Value(8),
          reading: drift.Value('はち'),
          readingRomaji: drift.Value('hachi'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(9),
          vocabId: drift.Value(9),
          reading: drift.Value('きゅう'),
          readingRomaji: drift.Value('kyuu'),
        ),
        const VocabReadingsCompanion(
          id: drift.Value(10),
          vocabId: drift.Value(10),
          reading: drift.Value('じゅう'),
          readingRomaji: drift.Value('jyuu'),
        ),
      ],
    );
    batch.insertAll(
      database.vocabReadings,
      List.generate(
        40,
        (i) => VocabReadingsCompanion(
          id: drift.Value(i + 11),
          vocabId: drift.Value(i + 11),
          reading: drift.Value((i + 11).toString()),
          readingRomaji: drift.Value(i.toString()),
        ),
      ),
    );
    // Vocab definitions
    batch.insertAll(
      database.vocabDefinitions,
      [
        const VocabDefinitionsCompanion(
          id: drift.Value(1),
          vocabId: drift.Value(1),
          definition: drift.Value('1'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(2),
          vocabId: drift.Value(2),
          definition: drift.Value('2'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(3),
          vocabId: drift.Value(3),
          definition: drift.Value('3'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(4),
          vocabId: drift.Value(4),
          definition: drift.Value('4'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(5),
          vocabId: drift.Value(5),
          definition: drift.Value('5'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(6),
          vocabId: drift.Value(6),
          definition: drift.Value('6'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(7),
          vocabId: drift.Value(7),
          definition: drift.Value('7'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(8),
          vocabId: drift.Value(8),
          definition: drift.Value('8'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(9),
          vocabId: drift.Value(9),
          definition: drift.Value('9'),
          waseieigo: drift.Value(false),
        ),
        const VocabDefinitionsCompanion(
          id: drift.Value(10),
          vocabId: drift.Value(10),
          definition: drift.Value('10'),
          waseieigo: drift.Value(false),
        ),
      ],
    );
    batch.insertAll(
      database.vocabDefinitions,
      List.generate(
        40,
        (i) => VocabDefinitionsCompanion(
          id: drift.Value(i + 11),
          vocabId: drift.Value(i + 11),
          definition: drift.Value((i + 11).toString()),
          waseieigo: const drift.Value(false),
        ),
      ),
    );
    // Kanji
    batch.insertAll(database.kanjis, [
      KanjisCompanion(
        id: drift.Value('一'.kanjiCodePoint()),
        kanji: const drift.Value('一'),
        radical: const drift.Value('一'),
        strokeCount: const drift.Value(1),
      ),
      KanjisCompanion(
        id: drift.Value('二'.kanjiCodePoint()),
        kanji: const drift.Value('二'),
        radical: const drift.Value('二'),
        strokeCount: const drift.Value(2),
      ),
      KanjisCompanion(
        id: drift.Value('三'.kanjiCodePoint()),
        kanji: const drift.Value('三'),
        radical: const drift.Value('三'),
        strokeCount: const drift.Value(3),
      ),
      KanjisCompanion(
        id: drift.Value('四'.kanjiCodePoint()),
        kanji: const drift.Value('四'),
        radical: const drift.Value('四'),
        strokeCount: const drift.Value(6),
      ),
      KanjisCompanion(
        id: drift.Value('五'.kanjiCodePoint()),
        kanji: const drift.Value('五'),
        radical: const drift.Value('五'),
        strokeCount: const drift.Value(5),
      ),
      KanjisCompanion(
        id: drift.Value('六'.kanjiCodePoint()),
        kanji: const drift.Value('六'),
        radical: const drift.Value('六'),
        strokeCount: const drift.Value(4),
      ),
      KanjisCompanion(
        id: drift.Value('七'.kanjiCodePoint()),
        kanji: const drift.Value('七'),
        radical: const drift.Value('七'),
        strokeCount: const drift.Value(2),
      ),
      KanjisCompanion(
        id: drift.Value('八'.kanjiCodePoint()),
        kanji: const drift.Value('八'),
        radical: const drift.Value('八'),
        strokeCount: const drift.Value(3),
      ),
      KanjisCompanion(
        id: drift.Value('九'.kanjiCodePoint()),
        kanji: const drift.Value('九'),
        radical: const drift.Value('九'),
        strokeCount: const drift.Value(2),
      ),
      KanjisCompanion(
        id: drift.Value('十'.kanjiCodePoint()),
        kanji: const drift.Value('十'),
        radical: const drift.Value('十'),
        strokeCount: const drift.Value(2),
      ),
    ]);
    // Predefined dictionary list
    batch.insertAll(database.predefinedDictionaryLists, [
      const PredefinedDictionaryListsCompanion(
        id: drift.Value(0),
        name: drift.Value('Vocab  list'),
        vocab: drift.Value([1, 2, 3, 4, 5]),
        kanji: drift.Value([]),
      ),
      PredefinedDictionaryListsCompanion(
        id: const drift.Value(1),
        name: const drift.Value('Kanji  list'),
        vocab: const drift.Value([]),
        kanji: drift.Value([
          '一'.kanjiCodePoint(),
          '二'.kanjiCodePoint(),
          '三'.kanjiCodePoint(),
          '四'.kanjiCodePoint(),
          '五'.kanjiCodePoint(),
        ]),
      ),
    ]);
  });

  return service;
}
