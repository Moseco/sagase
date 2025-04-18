import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/isar/my_dictionary_list.dart'
    as isar_my_dictionary_list;
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/utils/date_time_utils.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:sagase/utils/constants.dart' as constants;

import '../helpers/dictionary_service_helper.dart';
import '../helpers/fakes.dart';
import '../helpers/isar_helper.dart';

void main() {
  group('DictionaryServiceTest', () {
    setUp(() => setUpFakePathProvider());
    tearDown(() => cleanUpFakePathProvider());

    group('open', () {
      test('Valid', () async {
        // Create database file with data and close it
        final original = await setUpDictionaryData(inMemory: false);
        await original.close();

        // Open service
        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.valid);
        await service.close();
      });

      test('Initial install', () async {
        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.initialInstall);
      });

      test('Migration from Isar to sql required', () async {
        // Create a file with same name as isar database
        File(path.join(
          (await path_provider.getApplicationSupportDirectory()).path,
          constants.isarDatabaseFile,
        )).createSync();

        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.migrationRequired);
      });

      test('Previous user data transfer was interrupted', () async {
        // Create a file with same name as user data transfer file
        File(path.join(
          (await path_provider.getApplicationSupportDirectory()).path,
          constants.userDataTransferFile,
        )).createSync();

        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.transferInterrupted);
      });
    });

    group('getFlashcardSetFlashcards', () {
      late DictionaryService dictionaryService;

      setUp(() async {
        dictionaryService = await setUpDictionaryData();
      });

      tearDown(() async {
        await dictionaryService.close();
      });

      test('Lists overlap', () async {
        // Create my dictionary list that overlaps with predefined dictionary list
        final dictionaryList =
            await dictionaryService.createMyDictionaryList('list');
        for (int i = 3; i <= 10; i++) {
          await dictionaryService.addToMyDictionaryList(
            dictionaryList,
            await dictionaryService.getVocab(i),
          );
        }

        // Create flashcard set and add the dictionary lists
        final flashcardSet = await dictionaryService.createFlashcardSet('set');
        flashcardSet.myDictionaryLists.add(dictionaryList.id);
        flashcardSet.predefinedDictionaryLists.add(0);
        await dictionaryService.updateFlashcardSet(flashcardSet);

        // Get flashcards
        final flashcards =
            await dictionaryService.getFlashcardSetFlashcards(flashcardSet);

        expect(flashcards.length, 10);
      });

      test('Japanese front type spaced repetition data', () async {
        // Add spaced repetition data for 4 of the 5 vocab in the predefined dictionary list
        for (int i = 1; i < 5; i++) {
          await dictionaryService.setSpacedRepetitionData(
            SpacedRepetitionData.initial(
              dictionaryItem: await dictionaryService.getVocab(i),
              frontType: FrontType.japanese,
            ),
          );
        }

        // Create flashcard set and add the predefined dictionary list
        final flashcardSet = await dictionaryService.createFlashcardSet('set');
        flashcardSet.predefinedDictionaryLists.add(0);
        await dictionaryService.updateFlashcardSet(flashcardSet);

        // Get flashcards
        final flashcards =
            await dictionaryService.getFlashcardSetFlashcards(flashcardSet);

        expect(flashcards.length, 5);
        expect(flashcards[0].spacedRepetitionData, isNotNull);
        expect(flashcards[1].spacedRepetitionData, isNotNull);
        expect(flashcards[2].spacedRepetitionData, isNotNull);
        expect(flashcards[3].spacedRepetitionData, isNotNull);
        expect(flashcards[4].spacedRepetitionData, null);
      });

      test('English front type spaced repetition data', () async {
        // Add spaced repetition data for 4 of the 5 vocab in the predefined dictionary list
        for (int i = 1; i < 5; i++) {
          await dictionaryService.setSpacedRepetitionData(
            SpacedRepetitionData.initial(
              dictionaryItem: await dictionaryService.getVocab(i),
              frontType: FrontType.english,
            ),
          );
        }
        // Also add Japanese front spaced repetition data that should not be loaded
        for (int i = 1; i < 5; i++) {
          await dictionaryService.setSpacedRepetitionData(
            SpacedRepetitionData.initial(
              dictionaryItem: await dictionaryService.getVocab(i),
              frontType: FrontType.japanese,
            ),
          );
        }

        // Create flashcard set and add the predefined dictionary list
        final flashcardSet = await dictionaryService.createFlashcardSet('set');
        flashcardSet.frontType = FrontType.english;
        flashcardSet.predefinedDictionaryLists.add(0);
        await dictionaryService.updateFlashcardSet(flashcardSet);

        // Get flashcards
        final flashcards =
            await dictionaryService.getFlashcardSetFlashcards(flashcardSet);

        expect(flashcards.length, 5);
        expect(
          flashcards[0].spacedRepetitionData!.frontType,
          FrontType.english,
        );
        expect(
          flashcards[1].spacedRepetitionData!.frontType,
          FrontType.english,
        );
        expect(
          flashcards[2].spacedRepetitionData!.frontType,
          FrontType.english,
        );
        expect(
          flashcards[3].spacedRepetitionData!.frontType,
          FrontType.english,
        );
        expect(flashcards[4].spacedRepetitionData, null);
      });

      test('Mismatched front type spaced repetition data', () async {
        // Add spaced repetition data for 4 of the 5 vocab in the predefined dictionary list
        for (int i = 1; i < 5; i++) {
          await dictionaryService.setSpacedRepetitionData(
            SpacedRepetitionData.initial(
              dictionaryItem: await dictionaryService.getVocab(i),
              frontType: FrontType.english,
            ),
          );
        }

        // Create flashcard set and add the predefined dictionary list
        final flashcardSet = await dictionaryService.createFlashcardSet('set');
        flashcardSet.predefinedDictionaryLists.add(0);
        await dictionaryService.updateFlashcardSet(flashcardSet);

        // Get flashcards
        final flashcards =
            await dictionaryService.getFlashcardSetFlashcards(flashcardSet);

        expect(flashcards.length, 5);
        expect(flashcards[0].spacedRepetitionData, null);
        expect(flashcards[1].spacedRepetitionData, null);
        expect(flashcards[2].spacedRepetitionData, null);
        expect(flashcards[3].spacedRepetitionData, null);
        expect(flashcards[4].spacedRepetitionData, null);
      });
    });

    test('restoreFromBackup', () async {
      final service = await setUpDictionaryData();

      // Create initial data
      // Create my dictionary list
      final dictionaryList = await service.createMyDictionaryList('list1');
      await service.addToMyDictionaryList(
        dictionaryList,
        await service.getVocab(2),
      );
      await service.addToMyDictionaryList(
        dictionaryList,
        (await service.getKanji('二'))!,
      );

      // Create flashcard set
      final flashcardSet = await service.createFlashcardSet('set1');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      await service.updateFlashcardSet(flashcardSet);

      // Create spaced repetition data
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: await service.getVocab(2),
          frontType: FrontType.japanese,
        ),
      );

      // Create search history
      await service.setSearchHistoryItem(
        const SearchHistoryItem(id: 0, searchText: 'search'),
      );

      // Create text analysis history
      await service.setTextAnalysisHistoryItem(
        const TextAnalysisHistoryItem(id: 0, analysisText: 'analysis!'),
      );

      // Export data
      String path = (await service.exportUserData())!;
      final file = File(path);

      // Create/modify existing data that will be overwritten
      // My dictionary list
      await service.addToMyDictionaryList(
        dictionaryList,
        await service.getVocab(3),
      );
      await service.addToMyDictionaryList(
        dictionaryList,
        (await service.getKanji('三'))!,
      );
      await service.renameMyDictionaryList(dictionaryList, 'new name');

      // Flashcard set
      flashcardSet.name = 'set name change';
      await service.updateFlashcardSet(flashcardSet);

      // Create spaced repetition data
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: await service.getVocab(3),
          frontType: FrontType.japanese,
        ).copyWith(interval: 1),
      );
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: (await service.getKanji('二'))!,
          frontType: FrontType.japanese,
        ).copyWith(interval: 4),
      );
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: (await service.getKanji('三'))!,
          frontType: FrontType.english,
        ).copyWith(interval: 4),
      );

      // Create search history
      await service.setSearchHistoryItem(
        const SearchHistoryItem(id: 1, searchText: 'newer'),
      );

      // Create text analysis history
      await service.setTextAnalysisHistoryItem(
        const TextAnalysisHistoryItem(id: 1, analysisText: 'newer!'),
      );

      // Restore from backup
      await service.restoreFromBackup(file.path);

      // Verify contents
      final myDictionaryLists = await service.getAllMyDictionaryLists();
      expect(myDictionaryLists.length, 1);
      expect(myDictionaryLists[0].name, 'list1');
      final myDictionaryListItems =
          await service.getMyDictionaryListItems(myDictionaryLists[0]);
      expect(myDictionaryListItems.vocabIds, [2]);
      expect(myDictionaryListItems.kanjiIds, ['二'.kanjiCodePoint()]);

      final flashcardSets = await service.getFlashcardSets();
      expect(flashcardSets.length, 1);
      expect(flashcardSets[0].name, 'set1');
      final flashcards =
          await service.getFlashcardSetFlashcards(flashcardSets[0]);
      expect(flashcards.length, 2);
      expect(flashcards[0].id, 2);
      expect(flashcards[0].spacedRepetitionData, isNotNull);
      expect(flashcards[1].id, '二'.kanjiCodePoint());
      expect(flashcards[1].spacedRepetitionData, null);

      final searchHistory = await service.getSearchHistory();
      expect(searchHistory.length, 1);
      expect(searchHistory[0].searchText, 'search');

      final textAnalysisHistory = await service.getTextAnalysisHistory();
      expect(textAnalysisHistory.length, 1);
      expect(textAnalysisHistory[0].analysisText, 'analysis!');

      // Cleanup
      await service.close();
    });

    test('exportUserData/importUserData - empty', () async {
      final service = await setUpDictionaryData();

      String path = (await service.exportUserData())!;
      final file = File(path);

      // Check file content
      String backupContent = await file.readAsString();
      Map<String, dynamic> map = jsonDecode(backupContent);

      expect(
        map[SagaseDictionaryConstants.exportType],
        SagaseDictionaryConstants.exportTypeBackup,
      );
      expect(
        map[SagaseDictionaryConstants.backupDictionaryVersion],
        SagaseDictionaryConstants.dictionaryVersion,
      );
      expect(
        DateTime.fromMillisecondsSinceEpoch(
                map[SagaseDictionaryConstants.backupTimestamp])
            .isDifferentDay(DateTime.now()),
        false,
      );
      expect(
        map[SagaseDictionaryConstants.backupMyDictionaryLists],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupFlashcardSets],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupFlashcardSetReports],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionData],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupVocabSpacedRepetitionDataEnglish],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionData],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupKanjiSpacedRepetitionDataEnglish],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupSearchHistory],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupTextAnalysisHistory],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupVocabNotes],
        isEmpty,
      );
      expect(
        map[SagaseDictionaryConstants.backupKanjiNotes],
        isEmpty,
      );

      // Import the backup
      await service.importUserData(path);

      expect(
        await service.getAllMyDictionaryLists(),
        isEmpty,
      );
      expect(
        await service.getFlashcardSets(),
        isEmpty,
      );
      expect(
        await service.getSearchHistory(),
        isEmpty,
      );
      expect(
        await service.getTextAnalysisHistory(),
        isEmpty,
      );

      // Cleanup
      await service.close();
    });

    test('exportUserData/importUserData - with data', () async {
      final service = await setUpDictionaryData();

      // Create my dictionary list
      final dictionaryList = await service.createMyDictionaryList('list1');
      await service.addToMyDictionaryList(
        dictionaryList,
        await service.getVocab(2),
      );
      await service.addToMyDictionaryList(
        dictionaryList,
        await service.getVocab(3),
      );
      await service.addToMyDictionaryList(
        dictionaryList,
        (await service.getKanji('二'))!,
      );
      await service.addToMyDictionaryList(
        dictionaryList,
        (await service.getKanji('三'))!,
      );

      // Create flashcard set
      final flashcardSet = await service.createFlashcardSet('set1');
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
      flashcardSet.vocabShowReading = true;
      await service.updateFlashcardSet(flashcardSet);

      // Create flashcard set reports
      await service.createFlashcardSetReport(flashcardSet, 20240920);

      // Create spaced repetition data
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: await service.getVocab(2),
          frontType: FrontType.japanese,
        ),
      );
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: await service.getVocab(3),
          frontType: FrontType.japanese,
        ).copyWith(interval: 1),
      );
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: await service.getVocab(3),
          frontType: FrontType.english,
        ).copyWith(interval: 2),
      );
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: (await service.getKanji('三'))!,
          frontType: FrontType.japanese,
        ).copyWith(interval: 3),
      );
      await service.setSpacedRepetitionData(
        SpacedRepetitionData.initial(
          dictionaryItem: (await service.getKanji('三'))!,
          frontType: FrontType.english,
        ).copyWith(interval: 4),
      );

      // Create search history
      await service.setSearchHistoryItem(
        const SearchHistoryItem(id: 0, searchText: 'older'),
      );
      await service.setSearchHistoryItem(
        const SearchHistoryItem(id: 1, searchText: 'newer'),
      );

      // Create text analysis history
      await service.setTextAnalysisHistoryItem(
        const TextAnalysisHistoryItem(id: 0, analysisText: 'older!'),
      );
      await service.setTextAnalysisHistoryItem(
        const TextAnalysisHistoryItem(id: 1, analysisText: 'newer!'),
      );

      // Create vocab and kanji notes
      await service.setVocabNote(1, 'This is a note');
      await service.setKanjiNote('四'.kanjiCodePoint(), 'Important thing');

      // Export data and validate contents
      String path = (await service.exportUserData())!;
      final file = File(path);

      final userBackup = UserBackup.fromBackupJson(await file.readAsString());

      // Basic data
      expect(userBackup, isNotNull);
      expect(
        userBackup!.dictionaryVersion,
        SagaseDictionaryConstants.dictionaryVersion,
      );
      expect(userBackup.timestamp.isDifferentDay(DateTime.now()), false);

      // My dictionary list
      expect(userBackup.myDictionaryLists.length, 1);
      final myList =
          MyDictionaryList.fromBackupJson(userBackup.myDictionaryLists[0]);
      expect(myList.name, 'list1');
      expect(myList.timestamp.isDifferentDay(DateTime.now()), false);
      expect(myList.vocab, [3, 2]);
      expect(myList.kanji, ['三'.kanjiCodePoint(), '二'.kanjiCodePoint()]);

      // Flashcard set
      expect(userBackup.flashcardSets.length, 1);
      final set = FlashcardSet.fromBackupJson(userBackup.flashcardSets[0]);
      expect(set.myDictionaryLists.length, 1);
      expect(set.name, 'set1');
      expect(set.usingSpacedRepetition, true);
      expect(set.frontType, FrontType.japanese);
      expect(set.vocabShowReading, true);

      // Flashcard set reports
      expect(userBackup.flashcardSetReports.length, 1);
      final report = FlashcardSetReport.fromBackupJson(
        userBackup.flashcardSetReports[0],
      );
      expect(report.flashcardSetId, set.id);
      expect(report.date, 20240920);

      // Vocab spaced repetition data Japanese front
      expect(userBackup.vocabSpacedRepetitionData.length, 2);
      expect(userBackup.vocabSpacedRepetitionData['2'], isNotNull);
      final data1 = SpacedRepetitionData.fromBackupJson(
        jsonDecode(userBackup.vocabSpacedRepetitionData['2']),
        vocabId: 2,
        frontType: FrontType.japanese,
      );
      expect(data1.interval, 0);

      expect(userBackup.vocabSpacedRepetitionData['3'], isNotNull);
      final data2 = SpacedRepetitionData.fromBackupJson(
        jsonDecode(userBackup.vocabSpacedRepetitionData['3']),
        vocabId: 3,
        frontType: FrontType.japanese,
      );
      expect(data2.interval, 1);

      // Vocab spaced repetition data English front
      expect(userBackup.vocabSpacedRepetitionDataEnglish.length, 1);
      expect(userBackup.vocabSpacedRepetitionDataEnglish['3'], isNotNull);
      final data3 = SpacedRepetitionData.fromBackupJson(
        jsonDecode(userBackup.vocabSpacedRepetitionDataEnglish['3']),
        vocabId: 3,
        frontType: FrontType.english,
      );
      expect(data3.interval, 2);

      // Kanji spaced repetition data Japanese front
      expect(userBackup.kanjiSpacedRepetitionData.length, 1);
      expect(
        userBackup.kanjiSpacedRepetitionData['三'.kanjiCodePoint().toString()],
        isNotNull,
      );
      final data4 = SpacedRepetitionData.fromBackupJson(
        jsonDecode(userBackup
            .kanjiSpacedRepetitionData['三'.kanjiCodePoint().toString()]),
        kanjiId: 3,
        frontType: FrontType.japanese,
      );
      expect(data4.interval, 3);

      // Kanji spaced repetition data English front
      expect(userBackup.kanjiSpacedRepetitionDataEnglish.length, 1);
      expect(
        userBackup
            .kanjiSpacedRepetitionDataEnglish['三'.kanjiCodePoint().toString()],
        isNotNull,
      );
      final spaced5 = SpacedRepetitionData.fromBackupJson(
        jsonDecode(userBackup
            .kanjiSpacedRepetitionDataEnglish['三'.kanjiCodePoint().toString()]),
        kanjiId: 3,
        frontType: FrontType.english,
      );
      expect(spaced5.interval, 4);

      // Search history
      expect(userBackup.searchHistory, ['newer', 'older']);

      // Text analysis history
      expect(userBackup.textAnalysisHistory, ['newer!', 'older!']);

      // Close original service
      await service.close();

      // Create new instance of dictionary service and import data
      final newService = await setUpDictionaryData();
      final result = await newService.importUserData(path);

      expect(result, true);

      // My dictionary lists
      final dictionaryLists = await newService.getAllMyDictionaryLists();
      expect(dictionaryLists.length, 1);
      expect(dictionaryLists[0].name, 'list1');
      final dictionaryListItems =
          await newService.getMyDictionaryListItems(dictionaryLists[0]);
      expect(dictionaryListItems.vocabIds, [3, 2]);
      expect(dictionaryListItems.kanjiIds,
          ['三'.kanjiCodePoint(), '二'.kanjiCodePoint()]);

      // Flashcard sets
      final flashcardSets = await newService.getFlashcardSets();
      expect(flashcardSets.length, 1);
      expect(flashcardSets[0].name, 'set1');
      expect(flashcardSets[0].usingSpacedRepetition, true);
      expect(flashcardSets[0].vocabShowReading, true);
      expect(flashcardSets[0].predefinedDictionaryLists.length, 0);
      expect(flashcardSets[0].myDictionaryLists.length, 1);

      // Flashcard set reports
      final flashcardSetReport =
          await newService.getFlashcardSetReport(flashcardSet, 20240920);
      expect(flashcardSetReport!.flashcardSetId, flashcardSets[0].id);
      expect(flashcardSetReport.date, 20240920);

      // Spaced repetition data
      var vocabList = await newService
          .getVocabList([1, 2, 3], frontType: FrontType.japanese);
      expect(vocabList[0].spacedRepetitionData, null);
      expect(vocabList[1].spacedRepetitionData!.interval, 0);
      expect(vocabList[2].spacedRepetitionData!.interval, 1);
      vocabList =
          await newService.getVocabList([2, 3], frontType: FrontType.english);
      expect(vocabList[0].spacedRepetitionData, null);
      expect(vocabList[1].spacedRepetitionData!.interval, 2);

      var kanjiList = await newService.getKanjiList(
        ['二'.kanjiCodePoint(), '三'.kanjiCodePoint()],
        frontType: FrontType.japanese,
      );
      expect(kanjiList[0].spacedRepetitionData, null);
      expect(kanjiList[1].spacedRepetitionData!.interval, 3);
      kanjiList = await newService.getKanjiList(
        ['二'.kanjiCodePoint(), '三'.kanjiCodePoint()],
        frontType: FrontType.english,
      );
      expect(kanjiList[0].spacedRepetitionData, null);
      expect(kanjiList[1].spacedRepetitionData!.interval, 4);

      // Search history
      final searchHistory = await newService.getSearchHistory();
      expect(searchHistory.length, 2);
      expect(searchHistory[0].searchText, 'newer');
      expect(searchHistory[1].searchText, 'older');

      // Text analysis history
      final textAnalysisHistory = await newService.getTextAnalysisHistory();
      expect(textAnalysisHistory.length, 2);
      expect(textAnalysisHistory[0].analysisText, 'newer!');
      expect(textAnalysisHistory[1].analysisText, 'older!');

      // Vocab and kanji notes
      final vocabWithNote = await newService.getVocab(1);
      expect(vocabWithNote.note, 'This is a note');
      final kanjiWithNote = await newService.getKanji('四');
      expect(kanjiWithNote!.note, 'Important thing');

      // Cleanup
      await newService.close();
    });

    group('open and importDatabase', () {
      setUp(() async {
        // Create a database file
        final service = await setUpDictionaryData(inMemory: false);
        await service.close();
        // Compress database file in the expected download location
        final dbFile = File(
          path.join(
            (await path_provider.getApplicationSupportDirectory()).path,
            SagaseDictionaryConstants.dictionaryDatabaseFile,
          ),
        );
        final bytes = dbFile.readAsBytesSync();
        final archiveFile = ArchiveFile(
          SagaseDictionaryConstants.dictionaryDatabaseFile,
          bytes.length,
          bytes,
        );
        final archive = Archive();
        archive.addFile(archiveFile);
        final encodedArchive =
            ZipEncoder().encode(archive, level: DeflateLevel.bestCompression);
        File(path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          SagaseDictionaryConstants.dictionaryZip,
        )).writeAsBytesSync(encodedArchive);
        // Delete original file
        dbFile.deleteSync();
      });

      test('Initial install', () async {
        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.initialInstall);
        final result = await service.importDatabase(status);
        await service.close();

        expect(result, ImportResult.success);
      });

      test('Migration required', () async {
        // Create isar database
        final isar = await setUpIsar();
        // Create a my dictionary list
        await isar.writeTxn(() async {
          await isar.myDictionaryLists.put(
            isar_my_dictionary_list.MyDictionaryList()
              ..id = 0
              ..name = 'list1'
              ..timestamp = DateTime.now(),
          );
        });
        await isar.close();

        // Open and check status
        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.migrationRequired);

        // Do import
        final result = await service.importDatabase(status);

        // Check contents
        final dictionaryList = await service.getMyDictionaryList(0);
        expect(dictionaryList.name, 'list1');

        await service.close();

        // Check result
        expect(result, ImportResult.success);
        // Check isar database was deleted
        expect(
          File(path.join(
            (await path_provider.getApplicationSupportDirectory()).path,
            constants.isarDatabaseFile,
          )).existsSync(),
          false,
        );
      });

      test('New version available', () async {
        // Create new database and with lower dictionary version
        final oldService = await setUpDictionaryData(
          inMemory: false,
          dictionaryVersion: 1,
        );
        // Create a my dictionary list
        final dictionaryList = await oldService.createMyDictionaryList('list1');
        await oldService.close();

        // Open and check status
        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.outOfDate);

        // Do import
        final result = await service.importDatabase(status);

        // Check contents
        final newDictionaryList =
            await service.getMyDictionaryList(dictionaryList.id);
        expect(newDictionaryList.name, 'list1');

        await service.close();

        expect(result, ImportResult.success);
      });

      test('Previous transfer failed', () async {
        // Create new database
        final oldService = await setUpDictionaryData(inMemory: false);
        // Create a my dictionary list
        final dictionaryList = await oldService.createMyDictionaryList('list1');
        // Export user data
        final userDataPath = await oldService.exportUserData();
        // Delete my dictionary list to ensure correct transfer is happening
        await oldService.deleteMyDictionaryList(dictionaryList);
        await oldService.close();
        // Move file to expected location
        File(userDataPath!).renameSync(path.join(
          (await path_provider.getApplicationSupportDirectory()).path,
          constants.userDataTransferFile,
        ));

        // Open and check status
        final service = DictionaryService();
        final status = await service.open();
        expect(status, DictionaryStatus.transferInterrupted);

        // Do import
        final result = await service.importDatabase(status);

        // Check contents
        final newDictionaryList =
            await service.getMyDictionaryList(dictionaryList.id);
        expect(newDictionaryList.name, 'list1');

        await service.close();

        expect(result, ImportResult.success);
      });
    });
  });
}
