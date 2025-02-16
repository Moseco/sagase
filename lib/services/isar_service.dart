import 'dart:io';

import 'package:isar/isar.dart';
import 'package:sagase/datamodels/isar/dictionary_info.dart';
import 'package:sagase/datamodels/isar/flashcard_set.dart';
import 'package:sagase/datamodels/isar/kanji.dart';
import 'package:sagase/datamodels/isar/kanji_radical.dart';
import 'package:sagase/datamodels/isar/my_dictionary_list.dart';
import 'package:sagase/datamodels/isar/predefined_dictionary_list.dart';
import 'package:sagase/datamodels/isar/search_history_item.dart';
import 'package:sagase/datamodels/isar/vocab.dart';
import 'package:sagase/datamodels/user_backup.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart'
    show SagaseDictionaryConstants;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class IsarService {
  static const List<CollectionSchema<dynamic>> schemas = [
    DictionaryInfoSchema,
    VocabSchema,
    KanjiSchema,
    PredefinedDictionaryListSchema,
    MyDictionaryListSchema,
    FlashcardSetSchema,
    KanjiRadicalSchema,
    SearchHistoryItemSchema,
  ];

  late final Isar _isar;

  IsarService({Isar? isar}) {
    if (isar != null) _isar = isar;
  }

  Future<IsarStatus> initialize() async {
    try {
      _isar = await Isar.open(
        schemas,
        directory: (await path_provider.getApplicationSupportDirectory()).path,
      );

      return IsarStatus.valid;
    } catch (_) {
      return IsarStatus.invalid;
    }
  }

  Future<void> close() async {
    await _isar.close();
  }

  Future<String?> exportUserData() async {
    try {
      // My dictionary lists
      List<String> myDictionaryListBackups = [];
      final myLists = await _isar.myDictionaryLists.where().findAll();
      for (var myList in myLists) {
        myDictionaryListBackups.add(myList.toBackupJson());
      }

      // Flashcard sets
      List<String> flashcardSetBackups = [];
      final flashcardSets = await _isar.flashcardSets.where().findAll();
      for (var flashcardSet in flashcardSets) {
        flashcardSetBackups.add(flashcardSet.toBackupJson());
      }

      // Vocab spaced repetition data
      Map<String, String> vocabSpacedRepetitionDataBackups = {};
      final vocabSpacedRepetitionData =
          await _isar.vocabs.filter().spacedRepetitionDataIsNotNull().findAll();
      for (var vocab in vocabSpacedRepetitionData) {
        vocabSpacedRepetitionDataBackups[vocab.id.toString()] =
            vocab.spacedRepetitionData!.toBackupJson();
      }

      // Vocab spaced repetition data English
      Map<String, String> vocabSpacedRepetitionDataEnglishBackups = {};
      final vocabSpacedRepetitionDataEnglish = await _isar.vocabs
          .filter()
          .spacedRepetitionDataEnglishIsNotNull()
          .findAll();
      for (var vocab in vocabSpacedRepetitionDataEnglish) {
        vocabSpacedRepetitionDataEnglishBackups[vocab.id.toString()] =
            vocab.spacedRepetitionDataEnglish!.toBackupJson();
      }

      // Kanji spaced repetition data
      Map<String, String> kanjiSpacedRepetitionDataBackups = {};
      final kanjiSpacedRepetitionData =
          await _isar.kanjis.filter().spacedRepetitionDataIsNotNull().findAll();
      for (var kanji in kanjiSpacedRepetitionData) {
        kanjiSpacedRepetitionDataBackups[kanji.id.toString()] =
            kanji.spacedRepetitionData!.toBackupJson();
      }

      // Kanji spaced repetition data English
      Map<String, String> kanjiSpacedRepetitionDataEnglishBackups = {};
      final kanjiSpacedRepetitionDataEnglish = await _isar.kanjis
          .filter()
          .spacedRepetitionDataEnglishIsNotNull()
          .findAll();
      for (var kanji in kanjiSpacedRepetitionDataEnglish) {
        kanjiSpacedRepetitionDataEnglishBackups[kanji.id.toString()] =
            kanji.spacedRepetitionDataEnglish!.toBackupJson();
      }

      // Search history
      final List<String> searchHistoryBackups = [];
      final searchHistoryItems = await _isar.searchHistoryItems
          .where()
          .sortByTimestampDesc()
          .findAll();
      for (final item in searchHistoryItems) {
        searchHistoryBackups.add(item.searchQuery);
      }

      // Create instance
      DateTime now = DateTime.now();
      final backup = UserBackup(
        dictionaryVersion: SagaseDictionaryConstants.dictionaryVersion,
        timestamp: now,
        myDictionaryLists: myDictionaryListBackups,
        flashcardSets: flashcardSetBackups,
        flashcardSetReports: [],
        vocabSpacedRepetitionData: vocabSpacedRepetitionDataBackups,
        vocabSpacedRepetitionDataEnglish:
            vocabSpacedRepetitionDataEnglishBackups,
        kanjiSpacedRepetitionData: kanjiSpacedRepetitionDataBackups,
        kanjiSpacedRepetitionDataEnglish:
            kanjiSpacedRepetitionDataEnglishBackups,
        searchHistory: searchHistoryBackups,
        textAnalysisHistory: [],
        vocabNotes: [],
        kanjiNotes: [],
      );

      // Create file and write to it
      final file = File(path.join(
        (await path_provider.getApplicationCacheDirectory()).path,
        'backup_${now.year}-${now.month}-${now.day}_${now.millisecondsSinceEpoch}.sagase',
      ));

      await file.writeAsString(backup.toBackupJson());

      return file.path;
    } catch (_) {
      return null;
    }
  }
}

enum IsarStatus {
  valid,
  invalid,
}
