import 'dart:io';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/utils/constants.dart' as constants;

class IsarService {
  final Isar _isar;

  IsarService(this._isar);

  final kanaKit = const KanaKit();

  static Future<IsarService> initialize() async {
    final isar = await Isar.open(
      [DictionaryInfoSchema, VocabSchema, KanjiSchema],
    );

    return IsarService(isar);
  }

  Future<void> close() async {
    await _isar.close();
  }

  Future<DictionaryStatus> validateDictionary() async {
    // Check if dictionary count matches expectation
    if ((await _isar.kanjis.count()) != 13108 ||
        (await _isar.vocabs.count()) != 198094) {
      return DictionaryStatus.invalid;
    }

    // Check version matches current
    if ((await _isar.dictionaryInfos.get(0))?.version !=
        constants.dictionaryVersion) {
      return DictionaryStatus.outOfDate;
    }

    return DictionaryStatus.valid;
  }

  Future<List<DictionaryItem>> searchDictionary(String value) async {
    // First check if searching single kanji
    Kanji? kanji;
    if (value.length == 1 && value.contains(constants.kanjiRegExp)) {
      kanji = await _isar.kanjis.getByKanji(value);
    }

    // Search vocab
    final vocabList = await searchVocab(value);

    // Add kanji to the start of results if found
    if (kanji != null) {
      return <DictionaryItem>[kanji] + vocabList;
    } else {
      return vocabList;
    }
  }

  Future<List<Vocab>> searchVocab(String value) async {
    // Check if searching Japanese or romaji text
    if (kanaKit.isRomaji(value)) {
      List<String> split = Isar.splitWords(value);

      if (split.length == 1) {
        // Check both readings and definition
        return _isar.vocabs
            .where()
            .romajiTextIndexElementStartsWith(split.first)
            .or()
            .definitionIndexElementStartsWith(split.first)
            .limit(100)
            .findAll();
      } else {
        // Check definition only
        // Must do a which check with index and follow up with filters
        // Use -EqualTo for all but last element, and use -StartsWith for last element
        late QueryBuilder<Vocab, Vocab, QAfterFilterCondition> query;

        if (split.length == 2) {
          // First filter is also final filter
          query = _isar.vocabs
              .where()
              .definitionIndexElementEqualTo(split.first)
              .filter()
              .definitionIndexElementStartsWith(split[1]);
        } else {
          // Add all filters
          query = _isar.vocabs
              .where()
              .definitionIndexElementEqualTo(split.first)
              .filter()
              .definitionIndexElementEqualTo(split[1]);
          for (int i = 2; i < split.length - 1; i++) {
            query = query.and().definitionIndexElementEqualTo(split[i]);
          }
          query = query.and().definitionIndexElementStartsWith(split.last);
        }

        return query.limit(100).findAll();
      }
    } else {
      return _isar.vocabs
          .where()
          .japaneseTextIndexElementStartsWith(value)
          .limit(100)
          .findAll();
    }
  }

  Future<Kanji?> getKanji(String kanji) async {
    return _isar.kanjis.getByKanji(kanji);
  }

  static Future<void> importDatabase() async {
    // Copy db_export.zip asset to temporary directory file
    final ByteData byteData =
        await rootBundle.load('assets/dictionary_source/db_export.zip');
    final newDbZipBytes = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    final tempDir = await path_provider.getTemporaryDirectory();
    final File newDbZipFile = File('${tempDir.path}/db_export.zip');
    await newDbZipFile.writeAsBytes(newDbZipBytes);

    // Extract zip to application support directory
    final appSupportDir = await path_provider.getApplicationSupportDirectory();
    await archive.extractFileToDisk(newDbZipFile.path, appSupportDir.path);

    // Remove old database file, rename new one, delete temp file
    final File oldDbFile = File('${appSupportDir.path}/default.isar');
    if (await oldDbFile.exists()) {
      await oldDbFile.delete();
      await File('${appSupportDir.path}/default.isar.lock').delete();
    }
    await File('${appSupportDir.path}/db_export.isar')
        .rename('${appSupportDir.path}/default.isar');
    await newDbZipFile.delete();
  }
}

enum DictionaryStatus {
  valid,
  invalid,
  outOfDate,
}
