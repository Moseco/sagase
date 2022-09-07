import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:path/path.dart' as path;
import 'package:sagase/utils/dictionary_utils.dart';

import '../common.dart';

void main() {
  group('DictionaryUtilsTest', () {
    late Isar isar;

    setUp(() async {
      // Create directory .dart_tool/isar_test/tmp/
      final dartToolDir = path.join(Directory.current.path, '.dart_tool');
      String testTempPath = path.join(dartToolDir, 'isar_test', 'tmp');
      String downloadPath = path.join(dartToolDir, 'isar_test');
      await Directory(testTempPath).create(recursive: true);

      // Get name of isar binary based on platform
      late String binaryName;
      switch (Abi.current()) {
        case Abi.macosX64:
          binaryName = 'libisar.dylib';
          break;
        case Abi.linuxX64:
          binaryName = 'libisar.so';
          break;
        case Abi.windowsX64:
          binaryName = 'isar.dll';
          break;
        default:
          throw Exception('Unsupported platform for testing');
      }

      // Downloads Isar binary file
      await Isar.initializeIsarCore(
        libraries: {
          Abi.current(): '$downloadPath${Platform.pathSeparator}$binaryName'
        },
        download: true,
      );

      // Open Isar instance with random name
      isar = await Isar.open(
        [DictionaryInfoSchema, VocabSchema],
        directory: testTempPath,
        name: Random().nextInt(pow(2, 32) as int).toString(),
        inspector: false,
      );
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    test('Vocab creation with short source dictionary', () async {
      await DictionaryUtils.createVocabDictionaryIsolate(shortJMdict,
          testingIsar: isar);

      final vocab0 = await isar.vocabs.get(1000220);
      expect(vocab0!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab0.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab0.kanjiReadingPairs[0].kanjiWritings!.length, 1);
      expect(vocab0.kanjiReadingPairs[0].kanjiWritings![0].kanji, '明白');
      expect(vocab0.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab0.kanjiReadingPairs[0].readings[0].reading, 'めいはく');
      // Definition
      expect(vocab0.definitions.length, 1);
      expect(vocab0.definitions[0].definition,
          'obvious, clear, plain, evident, apparent, explicit, overt');
      expect(vocab0.definitions[0].pos!.length, 1);
      expect(vocab0.definitions[0].pos![0], PartOfSpeech.adjective);
      // Example
      expect(vocab0.examples!.length, 1);
      expect(vocab0.examples![0].index, 0);
      expect(vocab0.examples![0].japanese, '何をしなければならないかは明白です。');
      expect(vocab0.examples![0].english, 'It is clear what must be done.');

      final vocab1 = await isar.vocabs.get(1000390);
      expect(vocab1!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab1.kanjiReadingPairs.length, 6);
      // Pair 1
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings!.length, 1);
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![0].kanji, 'あっという間に');
      expect(vocab1.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab1.kanjiReadingPairs[0].readings[0].reading, 'あっというまに');
      // Pair 2
      expect(vocab1.kanjiReadingPairs[1].kanjiWritings!.length, 1);
      expect(vocab1.kanjiReadingPairs[1].kanjiWritings![0].kanji, 'あっと言う間に');
      expect(vocab1.kanjiReadingPairs[1].readings.length, 2);
      expect(vocab1.kanjiReadingPairs[1].readings[0].reading, 'あっというまに');
      expect(vocab1.kanjiReadingPairs[1].readings[1].reading, 'あっとゆうまに');
      // Pair 3
      expect(vocab1.kanjiReadingPairs[2].kanjiWritings!.length, 1);
      expect(vocab1.kanjiReadingPairs[2].kanjiWritings![0].kanji, 'あっとゆう間に');
      expect(vocab1.kanjiReadingPairs[2].readings.length, 1);
      expect(vocab1.kanjiReadingPairs[2].readings[0].reading, 'あっとゆうまに');
      // Pair 4
      expect(vocab1.kanjiReadingPairs[3].kanjiWritings!.length, 1);
      expect(vocab1.kanjiReadingPairs[3].kanjiWritings![0].kanji, 'アッという間に');
      expect(vocab1.kanjiReadingPairs[3].readings.length, 1);
      expect(vocab1.kanjiReadingPairs[3].readings[0].reading, 'アッというまに');
      // Pair 5
      expect(vocab1.kanjiReadingPairs[4].kanjiWritings!.length, 1);
      expect(vocab1.kanjiReadingPairs[4].kanjiWritings![0].kanji, 'アッと言う間に');
      expect(vocab1.kanjiReadingPairs[4].readings.length, 2);
      expect(vocab1.kanjiReadingPairs[4].readings[0].reading, 'アッというまに');
      expect(vocab1.kanjiReadingPairs[4].readings[1].reading, 'アッとゆうまに');
      // Pair 6
      expect(vocab1.kanjiReadingPairs[5].kanjiWritings!.length, 1);
      expect(vocab1.kanjiReadingPairs[5].kanjiWritings![0].kanji, 'アッとゆう間に');
      expect(vocab1.kanjiReadingPairs[5].readings.length, 1);
      expect(vocab1.kanjiReadingPairs[5].readings[0].reading, 'アッとゆうまに');
      // Definition
      expect(vocab1.definitions.length, 1);
      expect(vocab1.definitions[0].definition,
          'in an instant, in a flash, in the blink of an eye, in no time at all, just like that');
      expect(vocab1.definitions[0].pos!.length, 2);
      expect(vocab1.definitions[0].pos![0], PartOfSpeech.expressions);
      expect(vocab1.definitions[0].pos![1], PartOfSpeech.adverb);
      // Example
      expect(vocab1.examples!.length, 1);
      expect(vocab1.examples![0].index, 0);
      expect(vocab1.examples![0].japanese, '休暇はあっという間に終わった。');
      expect(vocab1.examples![0].english, 'The holiday ended all too soon.');

      final vocab2 = await isar.vocabs.get(1003430);
      expect(vocab2!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab2.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings!.length, 2);
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![0].kanji, '屹度');
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![0].info!.length, 2);
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![0].info![0],
          KanjiInfo.ateji);
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![0].info![1],
          KanjiInfo.rareKanjiForm);
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![1].kanji, '急度');
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![1].info!.length, 2);
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![1].info![0],
          KanjiInfo.ateji);
      expect(vocab2.kanjiReadingPairs[0].kanjiWritings![1].info![1],
          KanjiInfo.rareKanjiForm);
      expect(vocab2.kanjiReadingPairs[0].readings.length, 2);
      expect(vocab2.kanjiReadingPairs[0].readings[0].reading, 'きっと');
      expect(vocab2.kanjiReadingPairs[0].readings[1].reading, 'キッと');
      // Definitions
      expect(vocab2.definitions.length, 4);
      // Definition 1
      expect(vocab2.definitions[0].definition,
          'surely, undoubtedly, almost certainly, most likely (e.g. 90 percent)');
      expect(vocab2.definitions[0].pos!.length, 1);
      expect(vocab2.definitions[0].pos![0], PartOfSpeech.adverb);
      // Definition 2
      expect(vocab2.definitions[1].definition, 'sternly, severely');
      expect(vocab2.definitions[1].additionalInfo, 'esp. キッと');
      expect(vocab2.definitions[1].pos!.length, 1);
      expect(vocab2.definitions[1].pos![0], PartOfSpeech.adverb);
      // Definition 3
      expect(vocab2.definitions[2].definition,
          'having no slack, rigid, stiff, tight');
      expect(vocab2.definitions[2].pos!.length, 1);
      expect(vocab2.definitions[2].pos![0], PartOfSpeech.adverb);
      // Definition 4
      expect(vocab2.definitions[3].definition, 'suddenly, abruptly, instantly');
      expect(vocab2.definitions[3].pos!.length, 1);
      expect(vocab2.definitions[3].pos![0], PartOfSpeech.adverb);
      // Example
      expect(vocab2.examples!.length, 1);
      expect(vocab2.examples![0].index, 0);
      expect(vocab2.examples![0].japanese, 'でもよー、オラのおとうさんは良い気しねーよ、きっと。');
      expect(vocab2.examples![0].english,
          'But I don\'t think Dad would like me to.');

      final vocab3 = await isar.vocabs.get(1578850);
      expect(vocab3!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab3.kanjiReadingPairs.length, 1);
      expect(vocab3.kanjiReadingPairs[0].kanjiWritings!.length, 3);
      expect(vocab3.kanjiReadingPairs[0].kanjiWritings![0].kanji, '行く');
      expect(vocab3.kanjiReadingPairs[0].kanjiWritings![1].kanji, '逝く');
      expect(vocab3.kanjiReadingPairs[0].kanjiWritings![2].kanji, '往く');
      expect(vocab3.kanjiReadingPairs[0].kanjiWritings![2].info!.length, 1);
      expect(vocab3.kanjiReadingPairs[0].kanjiWritings![2].info![0],
          KanjiInfo.outdatedKanji);
      expect(vocab3.kanjiReadingPairs[0].readings.length, 2);
      expect(vocab3.kanjiReadingPairs[0].readings[0].reading, 'いく');
      expect(vocab3.kanjiReadingPairs[0].readings[1].reading, 'ゆく');
      // Definitions
      expect(vocab3.definitions.length, 10);
      // Definition 1
      expect(vocab3.definitions[0].definition,
          'to go, to move (in a direction or towards a specific location), to head (towards), to be transported (towards), to reach');
      expect(vocab3.definitions[0].pos!.length, 2);
      expect(vocab3.definitions[0].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[0].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 2
      expect(vocab3.definitions[1].definition, 'to proceed, to take place');
      expect(vocab3.definitions[1].additionalInfo,
          'い sometimes omitted in auxiliary use');
      expect(vocab3.definitions[1].pos!.length, 2);
      expect(vocab3.definitions[1].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[1].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 3
      expect(
          vocab3.definitions[2].definition, 'to pass through, to come and go');
      expect(vocab3.definitions[2].pos!.length, 2);
      expect(vocab3.definitions[2].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[2].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 4
      expect(vocab3.definitions[3].definition, 'to walk');
      expect(vocab3.definitions[3].pos!.length, 2);
      expect(vocab3.definitions[3].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[3].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 5
      expect(vocab3.definitions[4].definition, 'to die, to pass away');
      expect(vocab3.definitions[4].pos!.length, 2);
      expect(vocab3.definitions[4].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[4].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 6
      expect(vocab3.definitions[5].definition, 'to do (in a specific way)');
      expect(vocab3.definitions[5].pos!.length, 2);
      expect(vocab3.definitions[5].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[5].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 7
      expect(vocab3.definitions[6].definition, 'to stream, to flow');
      expect(vocab3.definitions[6].pos!.length, 2);
      expect(vocab3.definitions[6].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[6].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 8
      expect(vocab3.definitions[7].definition, 'to continue');
      expect(
          vocab3.definitions[7].additionalInfo, 'after the -te form of a verb');
      expect(vocab3.definitions[7].pos!.length, 2);
      expect(vocab3.definitions[7].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[7].pos![1], PartOfSpeech.auxiliary);
      // Definition 9
      expect(vocab3.definitions[8].definition,
          'to have an orgasm, to come, to cum');
      expect(vocab3.definitions[8].pos!.length, 2);
      expect(vocab3.definitions[8].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[8].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 10
      expect(vocab3.definitions[9].definition,
          'to trip, to get high, to have a drug-induced hallucination');
      expect(vocab3.definitions[9].pos!.length, 2);
      expect(vocab3.definitions[9].pos![0], PartOfSpeech.verbGodan);
      expect(vocab3.definitions[9].pos![1], PartOfSpeech.verbIntransitive);
      // Examples
      expect(vocab3.examples!.length, 3);
      // Example 1
      expect(vocab3.examples![0].index, 0);
      expect(vocab3.examples![0].japanese, 'お母さん、泳ぎに行ってもいい。');
      expect(vocab3.examples![0].english, 'Can I go swimming, Mother?');
      // Example 2
      expect(vocab3.examples![1].index, 1);
      expect(vocab3.examples![1].japanese, '私達はそれを禍とせず最善を尽くして頑張っていかなくてはならない。');
      expect(vocab3.examples![1].english,
          'We\'ll have to try and make the best of it.');
      // Example 3
      expect(vocab3.examples![2].index, 2);
      expect(
          vocab3.examples![2].japanese, 'これらの規則はずっと守られてきたし、これからもいつも守られていくだろう。');
      expect(vocab3.examples![2].english,
          'These rules have been and always will be observed.');

      final vocab4 = await isar.vocabs.get(2002400);
      expect(vocab4!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab4.kanjiReadingPairs.length, 1);
      expect(vocab4.kanjiReadingPairs[0].kanjiWritings, null);
      expect(vocab4.kanjiReadingPairs[0].readings.length, 3);
      expect(vocab4.kanjiReadingPairs[0].readings[0].reading, 'ううん');
      expect(vocab4.kanjiReadingPairs[0].readings[1].reading, 'うーん');
      expect(vocab4.kanjiReadingPairs[0].readings[2].reading, 'ウーン');
      // Definitions
      expect(vocab4.definitions.length, 3);
      // Definition 1
      expect(vocab4.definitions[0].definition, 'um, er, well');
      expect(vocab4.definitions[0].pos!.length, 1);
      expect(vocab4.definitions[0].pos![0], PartOfSpeech.interjection);
      // Definition 2
      expect(vocab4.definitions[1].definition, 'nuh-uh, no');
      expect(vocab4.definitions[1].pos!.length, 1);
      expect(vocab4.definitions[1].pos![0], PartOfSpeech.interjection);
      // Definition 3
      expect(vocab4.definitions[2].definition, 'oof');
      expect(vocab4.definitions[2].pos!.length, 1);
      expect(vocab4.definitions[2].pos![0], PartOfSpeech.interjection);
      // Examples
      expect(vocab4.examples!.length, 3);
      // Example 1
      expect(vocab4.examples![0].index, 0);
      expect(vocab4.examples![0].japanese, 'ウーン、どっちの道に行っても迷いそうな気がする。');
      expect(vocab4.examples![0].english,
          'Hmm. I have a feeling I\'m going to get lost whichever road I take.');
      // Example 2
      expect(vocab4.examples![1].index, 1);
      expect(vocab4.examples![1].japanese, 'うーんいいなあ。そこへ行こう。');
      expect(vocab4.examples![1].english,
          'Hm, that\'s a good idea. Let\'s go there.');
      // Example 3
      expect(vocab4.examples![2].index, 1);
      expect(vocab4.examples![2].japanese, 'ううん、由美ちゃんが魔法瓶に入れて、部室に持って来てくれたの。');
      expect(vocab4.examples![2].english,
          'No, Yumi put it in a thermos flask and brought it into the club room.');

      final vocab5 = await isar.vocabs.get(1002360);
      expect(vocab5!.commonWord, false);
      // Kanji-reading pairs
      expect(vocab5.kanjiReadingPairs.length, 3);
      // Pair 1
      expect(vocab5.kanjiReadingPairs[0].kanjiWritings!.length, 2);
      expect(vocab5.kanjiReadingPairs[0].kanjiWritings![0].kanji, 'お待ちどおさま');
      expect(vocab5.kanjiReadingPairs[0].kanjiWritings![1].kanji, 'お待ちどお様');
      expect(vocab5.kanjiReadingPairs[0].kanjiWritings![0].info, null);
      expect(vocab5.kanjiReadingPairs[0].kanjiWritings![1].info, null);
      expect(vocab5.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab5.kanjiReadingPairs[0].readings[0].reading, 'おまちどおさま');
      // Pair 2
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings!.length, 3);
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings![0].kanji, 'お待ち遠様');
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings![1].kanji, '御待ち遠様');
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings![2].kanji, 'お待ち遠さま');
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings![0].info, null);
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings![1].info, null);
      expect(vocab5.kanjiReadingPairs[1].kanjiWritings![2].info, null);
      expect(vocab5.kanjiReadingPairs[1].readings.length, 2);
      expect(vocab5.kanjiReadingPairs[1].readings[0].reading, 'おまちどおさま');
      expect(vocab5.kanjiReadingPairs[1].readings[1].reading, 'おまちどうさま');
      // Pair 3
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings!.length, 2);
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings![0].kanji, 'お待ちどうさま');
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings![1].kanji, 'お待ちどう様');
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings![0].info!.length, 1);
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings![0].info![0],
          KanjiInfo.irregularKana);
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings![1].info!.length, 1);
      expect(vocab5.kanjiReadingPairs[2].kanjiWritings![1].info![0],
          KanjiInfo.irregularKana);
      expect(vocab5.kanjiReadingPairs[2].readings.length, 1);
      expect(vocab5.kanjiReadingPairs[2].readings[0].reading, 'おまちどうさま');
      expect(vocab5.kanjiReadingPairs[2].readings[0].info!.length, 1);
      expect(vocab5.kanjiReadingPairs[2].readings[0].info![0],
          ReadingInfo.irregularKana);
      // Definition
      expect(vocab5.definitions.length, 1);
      expect(vocab5.definitions[0].definition,
          'I\'m sorry to have kept you waiting');
      expect(vocab5.definitions[0].pos!.length, 1);
      expect(vocab5.definitions[0].pos![0], PartOfSpeech.expressions);
    });
  });
}
