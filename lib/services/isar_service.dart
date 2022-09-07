import 'dart:io';

import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:stacked/stacked_annotations.dart';

class IsarService {
  final Isar _isar;

  IsarService(this._isar);

  final kanaKit = const KanaKit();

  static Future<IsarService> initialize() async {
    final isar = await Isar.open([DictionaryInfoSchema, VocabSchema]);

    return IsarService(isar);
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

  Future<void> importDatabase() async {
    // Close the current instance
    _isar.close();

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

    // Register new instance with locator
    StackedLocator.instance.unregister<IsarService>();
    StackedLocator.instance.registerSingleton(await IsarService.initialize());
  }
}
