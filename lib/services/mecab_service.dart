import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:mecab_dart/mecab_dart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase/utils/string_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

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

  Future<bool> initialize() async {
    // Check if directory exists
    String mecabDir = path.join(
      (await path_provider.getApplicationSupportDirectory()).path,
      'mecab',
    );
    if (!(await Directory(mecabDir).exists())) return false;

    // Check if files exist
    for (var file in mecabFiles) {
      if (!(await File('$mecabDir/$file').exists())) {
        return false;
      }
    }

    // Initialize mecab
    _mecab.initWithIpadicDir(mecabDir, true);

    return true;
  }

  Future<void> extractFiles() async {
    // Get zip data
    final ByteData byteData = await rootBundle.load('assets/mecab/ipadic.zip');

    // Start isolate to handle exacting files
    final rootIsolateToken = RootIsolateToken.instance!;
    await Isolate.run(() async {
      BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
      // Set up directory
      String mecabDir = path.join(
        (await path_provider.getApplicationSupportDirectory()).path,
        'mecab',
      );
      final dir = Directory(mecabDir);
      // If directory already exists, delete it first to avoid conflicting files
      if (await dir.exists()) await dir.delete(recursive: true);
      await dir.create(recursive: true);

      // Copy zip to temporary directory file
      final ipadicZipBytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final tempDir = await path_provider.getTemporaryDirectory();
      final File ipadicZipFile = File('${tempDir.path}/ipadic.zip');
      await ipadicZipFile.writeAsBytes(ipadicZipBytes);

      // Extract zip to mecab directory
      await archive.extractFileToDisk(ipadicZipFile.path, mecabDir);

      // Remove the temp file
      await ipadicZipFile.delete();
    });
  }

  List<JapaneseTextToken> parseText(String text) {
    List<JapaneseTextToken> list = [];

    final tokens = _mecab.parse(text.romajiToFullWidth().toUpperCase());

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

      // Get part of speech that helps certain searches
      PartOfSpeech? pos;
      if (tokens[i].features[0] == '助詞') {
        pos = PartOfSpeech.particle;
      } else if (tokens[i].features[4] == 'サ変・スル') {
        pos = PartOfSpeech.verbSuruIncluded;
      }

      // Handle corner cases where the base form (index 6) is different than the real base form
      String base = tokens[i].features[6];
      if (tokens[i].surface == 'なら' && tokens[i].features[6] == 'だ') {
        base = 'なら';
      }

      // Created token to add to list or trailing of previous token
      final current = JapaneseTextToken(
        original: tokens[i].surface,
        base: base,
        baseReading: tokens[i].features[7],
        rubyTextPairs: rubyTextPairs,
        pos: pos,
      );

      // Check if the current token should be trailing of previous token
      if (i > 0) {
        if (tokens[i].features[1] == '接続助詞' && tokens[i].features[6] == 'て') {
          list.last.trailing ??= [];
          list.last.trailing!.add(current);
          continue;
        } else if (tokens[i].features[0] == '助動詞') {
          if (tokens[i].features[6] == 'う' ||
              tokens[i].features[6] == 'た' ||
              tokens[i].features[6] == 'ます' ||
              tokens[i].features[6] == 'ん' ||
              tokens[i].features[6] == 'ない' ||
              tokens[i].features[7] == 'ナ') {
            list.last.trailing ??= [];
            list.last.trailing!.add(current);
            continue;
          }
        } else if (tokens[i].features[1] == '非自立' &&
            tokens[i].features[6] == 'ん') {
          list.last.trailing ??= [];
          list.last.trailing!.add(current);
          continue;
        }
      }

      list.add(current);
    }

    return list;
  }

  List<RubyTextPair> createRubyTextPairs(String writing, String reading) {
    // First check if only kana
    if (_kanaKit.isKana(writing)) return [RubyTextPair(writing: writing)];

    List<RubyTextPair> rubyTextPairs = [];
    RubyTextPair? trailingRubyTextPair;

    reading = _kanaKit.toHiragana(reading);

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
    for (int i = 0; i < writing.length; i++) {
      if (_kanaKit.isKana(writing[i])) {
        // Found kana, set starting position if not already set
        kanaStartingPosition ??= i;
      } else if (kanaStartingPosition != null) {
        // Found non-kana character after previously found kana
        // Get kana substring
        String kanaSubstring = writing.substring(kanaStartingPosition, i);
        // If have non-kana before current kana, create that substring first
        if (kanaStartingPosition > 0) {
          // Find position of kana substring in the reading
          int position = reading.indexOf(_kanaKit.toHiragana(kanaSubstring));
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

        // Will have cut string up to character i, so set to 0
        i = 0;
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
          int position = reading.indexOf(_kanaKit.toHiragana(kanaSubstring));
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
    String finalReading = _kanaKit.toHiragana(buffer.toString());
    if (originalReading != finalReading) {
      return [RubyTextPair(writing: originalWriting, reading: originalReading)];
    }

    return rubyTextPairs;
  }
}
