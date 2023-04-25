import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:mecab_dart/mecab_dart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/datamodels/japanese_text_token.dart';

class MecabService {
  static const List<String> mecabFiles = [
    'char.bin',
    'dicrc',
    'left-id.def',
    'matrix.bin',
    'pos-id.def',
    'rewrite.def',
    'right-id.def',
    'sys.dic',
    'unk.dic',
  ];

  static const String featurePunctuation = '記号';

  final _mecab = Mecab();
  final _kanaKit = const KanaKit();

  Future<void> initialize() async {
    // Set up directory
    String mecabDir = path.join(
      (await path_provider.getApplicationSupportDirectory()).path,
      'mecab',
    );
    await Directory(mecabDir).create(recursive: true);

    // Check if files exist
    bool extractFiles = false;
    for (var file in mecabFiles) {
      if (!(await File('$mecabDir/$file').exists())) {
        extractFiles = true;
        break;
      }
    }

    // Extract files from assets of required
    if (extractFiles) {
      // Copy zip to temporary directory file
      final ByteData byteData =
          await rootBundle.load('assets/mecab/ipadic.zip');
      final ipadicZipBytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final tempDir = await path_provider.getTemporaryDirectory();
      final File ipadicZipFile = File('${tempDir.path}/ipadic.zip');
      await ipadicZipFile.writeAsBytes(ipadicZipBytes);

      // Extract zip to mecab directory
      await archive.extractFileToDisk(ipadicZipFile.path, mecabDir);

      // Remove the temp file
      await ipadicZipFile.delete();
    }

    // Initialize mecab
    _mecab.initWithIpadicDir(mecabDir, true);
  }

  List<JapaneseTextToken> parseText(String text) {
    List<JapaneseTextToken> list = [];

    final tokens = _mecab.parse(text);

    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i].features.length != 9) continue;

      List<RubyTextPair> rubyTextPairs = [];

      // If punctuation or arabic number, add with only writing
      if (tokens[i].features[0] == featurePunctuation ||
          (tokens[i].surface.codeUnitAt(0) >= '０'.codeUnitAt(0) &&
              tokens[i].surface.codeUnitAt(0) <= '９'.codeUnitAt(0))) {
        rubyTextPairs.add(RubyTextPair(writing: tokens[i].surface));
      } else {
        rubyTextPairs.addAll(createRubyTextPairs(
          tokens[i].surface,
          tokens[i].features[7],
        ));
      }

      list.add(JapaneseTextToken(
        original: tokens[i].surface,
        base: tokens[i].features[4],
        rubyTextPairs: rubyTextPairs,
      ));
    }

    return list;
  }

  List<RubyTextPair> createRubyTextPairs(
    String writing,
    String reading, {
    bool convertReading = true,
  }) {
    // First check if only kana
    if (_kanaKit.isKana(writing)) return [RubyTextPair(writing: writing)];

    List<RubyTextPair> rubyTextPairs = [];
    RubyTextPair? trailingRubyTextPair;

    if (convertReading) reading = _kanaKit.toHiragana(reading);

    String originalWriting = writing;
    String originalReading = reading;

    // Check for trailing kana
    for (int i = writing.length - 1; i >= 0; i--) {
      // If found non-kana character preceding a kana character, add writing and break
      if (!_kanaKit.isKana(writing[i])) {
        if (i != writing.length - 1) {
          trailingRubyTextPair = RubyTextPair(
            writing: writing.substring(i + 1),
          );
          writing = writing.substring(
              0, writing.length - trailingRubyTextPair.writing.length);
          reading = reading.substring(
              0, reading.length - trailingRubyTextPair.writing.length);
        }
        break;
      }
    }

    int? kanaStartingPosition;
    for (int j = 0; j < writing.length; j++) {
      if (_kanaKit.isKana(writing[j])) {
        // Found kana, set starting position if not already set
        kanaStartingPosition ??= j;
      } else if (kanaStartingPosition != null) {
        // Found non-kana character after previously found kana
        // Get kana substring
        String kanaSubstring = writing.substring(kanaStartingPosition, j);
        // If have non-kana before current kana, create that substring first
        if (kanaStartingPosition > 0) {
          // Find position of kana substring in the reading
          int position = reading.indexOf(convertReading
              ? _kanaKit.toHiragana(kanaSubstring)
              : kanaSubstring);
          if (position != -1) {
            // Get non-kana writing and reading then cut from writing and reading strings
            rubyTextPairs.add(RubyTextPair(
              writing: writing.substring(0, kanaStartingPosition),
              reading: reading.substring(0, position),
            ));
            writing = writing.substring(kanaStartingPosition);
            reading = reading.substring(position);
          } else {
            // Could not find non-kana reading, add remaining and return
            rubyTextPairs.add(RubyTextPair(
              writing: writing,
              reading: reading,
            ));
            return rubyTextPairs;
          }
        }

        // Add kana and cut writing and reading strings
        rubyTextPairs.add(RubyTextPair(writing: kanaSubstring));
        writing = writing.substring(kanaSubstring.length);
        reading = reading.substring(kanaSubstring.length);

        // Will have cut string up to character j, so set to 0
        j = 0;
        kanaStartingPosition = null;
      }
    }

    // If have remaining writing/reading create final pairs
    if (writing.isNotEmpty) {
      // If no kana found, simply add remaining writing and reading
      if (kanaStartingPosition == null) {
        rubyTextPairs.add(RubyTextPair(
          writing: writing,
          reading: reading,
        ));
      } else {
        // There is mixed kana and non-kana
        // Get kana substring
        String kanaSubstring = writing.substring(kanaStartingPosition);
        // If have non-kana before current kana, create that substring first
        if (kanaStartingPosition != 0) {
          // Find position of kana substring in the reading
          int position = reading.indexOf(convertReading
              ? _kanaKit.toHiragana(kanaSubstring)
              : kanaSubstring);
          if (position != -1) {
            // Get non-kana writing and reading
            rubyTextPairs.add(RubyTextPair(
              writing: writing.substring(0, kanaStartingPosition),
              reading: reading.substring(0, position),
            ));
          } else {
            // Could not find non-kana reading, add remaining and return
            rubyTextPairs.add(RubyTextPair(
              writing: writing,
              reading: reading,
            ));
            return rubyTextPairs;
          }
        }

        // Add kana
        rubyTextPairs.add(RubyTextPair(writing: kanaSubstring));
      }
    }

    if (trailingRubyTextPair != null) rubyTextPairs.add(trailingRubyTextPair);

    // Make sure all reading from input exists in the ruby text pairs
    // If it does not, add reading/writing as single ruby text pair
    final buffer = StringBuffer();
    for (var pair in rubyTextPairs) {
      if (pair.reading != null) {
        buffer.write(pair.reading);
      } else {
        buffer.write(pair.writing);
      }
    }
    String finalReading = buffer.toString();
    if (convertReading) finalReading = _kanaKit.toHiragana(finalReading);
    if (originalReading != finalReading) {
      return [RubyTextPair(writing: originalWriting, reading: originalReading)];
    }

    return rubyTextPairs;
  }
}
