import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:mecab_dart/mecab_dart.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:archive/archive_io.dart' as archive;
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/utils/constants.dart' as constants;

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

  bool _ready = false;

  Future<bool> initialize() async {
    try {
      // Check if directory exists
      String mecabDir = path.join(
        (await path_provider.getApplicationSupportDirectory()).path,
        'mecab',
      );
      if (!(await Directory(mecabDir).exists())) {
        _ready = false;
        return _ready;
      }

      // Check if files exist
      for (var file in mecabFiles) {
        if (!(await File(path.join(mecabDir, file)).exists())) {
          _ready = false;
          return _ready;
        }
      }

      // Initialize mecab
      _mecab.initWithIpadicDir(mecabDir, true);

      _ready = true;
      return _ready;
    } catch (_) {
      _ready = false;
      return _ready;
    }
  }

  Future<bool> extractFiles() async {
    // Start isolate to handle exacting files
    try {
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

        // Extract zip to mecab directory
        final mecabDictionaryZip = File(path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          SagaseDictionaryConstants.mecabZip,
        ));
        await archive.extractFileToDisk(mecabDictionaryZip.path, mecabDir);

        // Remove the temp file
        await mecabDictionaryZip.delete();
      });
    } catch (_) {
      return false;
    }
    return true;
  }

  List<JapaneseTextToken> parseText(String text) {
    if (!_ready) {
      return [
        JapaneseTextToken(
          original: text,
          base: text,
          baseReading: text,
          rubyTextPairs: [RubyTextPair(writing: text)],
        ),
      ];
    }

    List<JapaneseTextToken> list = [];

    final tokens = _mecab.parse(text.romajiToFullWidth().toUpperCase());

    for (int i = 0; i < tokens.length; i++) {
      // If contains no features skip to next iteration (only EOS?)
      if (tokens[i].features.isEmpty) continue;

      // If non-standard feature length, punctuation, or arabic number, add with only writing
      if (tokens[i].features.length != 9 ||
          tokens[i].features[0] == featurePunctuation ||
          tokens[i].surface == '％' ||
          (tokens[i].surface.length == 1 &&
              tokens[i].surface.codeUnitAt(0) >= '０'.codeUnitAt(0) &&
              tokens[i].surface.codeUnitAt(0) <= '９'.codeUnitAt(0))) {
        list.add(JapaneseTextToken(
          original: tokens[i].surface,
          base: tokens[i].surface,
          baseReading: tokens[i].surface,
          rubyTextPairs: [RubyTextPair(writing: tokens[i].surface)],
        ));
        continue;
      }

      // Get part of speech that helps certain searches
      PartOfSpeech? pos;
      if (tokens[i].features[0] == '助詞') {
        pos = PartOfSpeech.particle;
      } else if (tokens[i].features[0] == '動詞') {
        pos = _identifyVerb(tokens[i].features);
      } else if (tokens[i].features[1] == '固有名詞' &&
          tokens[i].features[2] == '人名') {
        pos = PartOfSpeech.nounProper;
      }

      // Handle corner cases where the base or base reading form is different than the real form
      String base = tokens[i].features[6];
      if (tokens[i].surface == 'なら' && tokens[i].features[6] == 'だ') {
        base = 'なら';
      }
      String baseReading = tokens[i].features[7];
      if (baseReading.endsWith('ッ') &&
          tokens[i].features[5] == '連用タ接続' &&
          tokens.length > i + 1 &&
          tokens[i + 1].features.length == 9) {
        switch (tokens[i + 1].features[6]) {
          case 'て':
            baseReading =
                '${baseReading.substring(0, baseReading.length - 1)}ク';
            break;
          case 'で':
            baseReading =
                '${baseReading.substring(0, baseReading.length - 1)}グ';
            break;
        }
      }

      // Created token to add to list or trailing of previous token
      final current = JapaneseTextToken(
        original: tokens[i].surface,
        base: base,
        baseReading: baseReading,
        rubyTextPairs: createRubyTextPairs(
          tokens[i].surface,
          tokens[i].features[7],
        ),
        pos: pos,
      );

      // Check if the current token should be trailing of previous token
      if (list.isNotEmpty) {
        if (tokens[i - 1].features.length == 9 &&
            tokens[i - 1].features[5] == '連用タ接続') {
          list.last.trailing ??= [];
          list.last.trailing!.add(current);
          continue;
        } else if (list.last.pos != PartOfSpeech.particle) {
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
      }

      list.add(current);
    }

    return list;
  }

  PartOfSpeech? _identifyVerb(List<String> features) {
    switch (features[4]) {
      case 'サ変・スル':
        return PartOfSpeech.verbSuruIncluded;
      case '一段':
        return PartOfSpeech.verbIchidan;
      case '一段・クレル':
        return PartOfSpeech.verbIchidanS;
      // case '':
      //   return PartOfSpeech.verbGodanAru;
      case '五段・ラ行':
        if (features[6] == 'ある' || features[6] == '有る' || features[6] == 'アル') {
          return PartOfSpeech.verbGodanRI;
        } else {
          return PartOfSpeech.verbGodanR;
        }
      case '五段・バ行':
        return PartOfSpeech.verbGodanB;
      case '五段・ガ行':
        return PartOfSpeech.verbGodanG;
      case '五段・カ行促音便':
        return PartOfSpeech.verbGodanKS;
      case '五段・カ行イ音便':
        return PartOfSpeech.verbGodanK;
      case '五段・マ行':
        return PartOfSpeech.verbGodanM;
      case '五段・ナ行':
        return PartOfSpeech.verbGodanN;
      case '五段・サ行':
        return PartOfSpeech.verbGodanS;
      case '五段・タ行':
        return PartOfSpeech.verbGodanT;
      case '五段・ワ行促音便':
        return PartOfSpeech.verbGodanU;
      // case '':
      //   return PartOfSpeech.verbGodanUS;
      // case '':
      //   return PartOfSpeech.verbGodanUru;
      default:
        return null;
    }
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
              reading: _getReading(
                writing.substring(0, kanaStartingPosition),
                reading.substring(0, position),
              ),
            ));
            writing = writing.substring(kanaStartingPosition);
            reading = reading.substring(position);
          } else {
            // Could not find non-kana reading, add remaining and return
            rubyTextPairs.add(RubyTextPair(
              writing: writing,
              reading: _getReading(writing, reading),
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
          reading: _getReading(writing, reading),
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
              reading: _getReading(
                writing.substring(0, kanaStartingPosition),
                reading.substring(0, position),
              ),
            ));
          } else {
            // Could not find non-kana reading, add remaining and return
            rubyTextPairs.add(RubyTextPair(
              writing: writing,
              reading: _getReading(writing, reading),
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

  String _getReading(String writing, String reading) {
    // If writing is full width romaji, convert the reading to katakana
    if (constants.onlyFullWidthRomajiRegExp.hasMatch(writing)) {
      return _kanaKit.toKatakana(reading);
    } else {
      return reading;
    }
  }
}
