import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/kanji_radical.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/utils/dictionary_utils.dart';

import '../common.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('DictionaryUtilsTest', () {
    late Isar isar;

    setUp(() async {
      isar = await setUpIsar();
    });

    tearDown(() => isar.close(deleteFromDisk: true));

    test('Vocab database creation with short source dictionary', () async {
      await DictionaryUtils.createVocabDictionaryIsolate(shortJMdict, isar);

      final vocab0 = await isar.vocabs.get(1000220);
      expect(vocab0!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab0.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab0.kanjiReadingPairs[0].kanjiWritings!.length, 1);
      expect(vocab0.kanjiReadingPairs[0].kanjiWritings![0].kanji, '明白');
      expect(vocab0.kanjiReadingPairs[0].kanjiWritings![0].info, null);
      expect(vocab0.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab0.kanjiReadingPairs[0].readings[0].reading, 'めいはく');
      expect(vocab0.kanjiReadingPairs[0].readings[0].info, null);
      // Definition
      expect(vocab0.definitions.length, 1);
      expect(vocab0.definitions[0].definition,
          'obvious; clear; plain; evident; apparent; explicit; overt');
      expect(vocab0.definitions[0].additionalInfo, null);
      expect(vocab0.definitions[0].pos!.length, 1);
      expect(vocab0.definitions[0].pos![0], PartOfSpeech.adjectiveNa);
      expect(vocab0.definitions[0].appliesTo, null);
      expect(vocab0.definitions[0].miscInfo, null);
      expect(vocab0.definitions[0].dialects, null);
      // Example
      expect(vocab0.examples!.length, 1);
      expect(vocab0.examples![0].index, 0);
      expect(vocab0.examples![0].japanese, '何をしなければならないかは明白です。');
      expect(vocab0.examples![0].english, 'It is clear what must be done.');
      // Japanese text index
      expect(vocab0.japaneseTextIndex.length, 2);
      expect(vocab0.japaneseTextIndex[0], 'めいはく');
      expect(vocab0.japaneseTextIndex[1], '明白');
      // Romaji text index
      expect(vocab0.romajiTextIndex.length, 1);
      expect(vocab0.romajiTextIndex[0], 'meihaku');

      final vocab1 = await isar.vocabs.get(1000390);
      expect(vocab1!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab1.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings!.length, 6);
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![0].kanji, 'あっという間に');
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![1].kanji, 'あっと言う間に');
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![2].kanji, 'アッという間に');
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![3].kanji, 'アッと言う間に');
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![4].kanji, 'あっとゆう間に');
      expect(vocab1.kanjiReadingPairs[0].kanjiWritings![5].kanji, 'アッとゆう間に');
      expect(vocab1.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab1.kanjiReadingPairs[0].readings[0].reading, 'あっというまに');
      // Definition
      expect(vocab1.definitions.length, 1);
      expect(vocab1.definitions[0].definition,
          'in an instant; in a flash; in the blink of an eye; in no time at all; just like that');
      expect(vocab1.definitions[0].pos!.length, 2);
      expect(vocab1.definitions[0].pos![0], PartOfSpeech.expressions);
      expect(vocab1.definitions[0].pos![1], PartOfSpeech.adverb);
      // Example
      expect(vocab1.examples!.length, 1);
      expect(vocab1.examples![0].index, 0);
      expect(vocab1.examples![0].japanese, '休暇はあっという間に終わった。');
      expect(vocab1.examples![0].english, 'The holiday ended all too soon.');
      // Japanese text index
      expect(vocab1.japaneseTextIndex.length, 4);
      expect(vocab1.japaneseTextIndex[0], 'あっというまに');
      expect(vocab1.japaneseTextIndex[1], 'あっという間に');
      expect(vocab1.japaneseTextIndex[2], 'あっと言う間に');
      expect(vocab1.japaneseTextIndex[3], 'あっとゆう間に');
      // Romaji text index
      expect(vocab1.romajiTextIndex.length, 2);
      expect(vocab1.romajiTextIndex[0], 'attoiumani');
      expect(vocab1.romajiTextIndex[1], 'atoimani');

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
          'surely; undoubtedly; almost certainly; most likely (e.g. 90 percent)');
      expect(vocab2.definitions[0].pos!.length, 1);
      expect(vocab2.definitions[0].pos![0], PartOfSpeech.adverb);
      expect(vocab2.definitions[0].miscInfo!.length, 2);
      expect(vocab2.definitions[0].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      expect(vocab2.definitions[0].miscInfo![1],
          MiscellaneousInfo.onomatopoeicOrMimeticWord);
      // Definition 2
      expect(vocab2.definitions[1].definition, 'sternly; severely');
      expect(vocab2.definitions[1].additionalInfo, 'esp. キッと');
      expect(vocab2.definitions[1].pos!.length, 1);
      expect(vocab2.definitions[1].pos![0], PartOfSpeech.adverb);
      expect(vocab2.definitions[1].miscInfo!.length, 2);
      expect(vocab2.definitions[1].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      expect(vocab2.definitions[1].miscInfo![1],
          MiscellaneousInfo.onomatopoeicOrMimeticWord);
      // Definition 3
      expect(vocab2.definitions[2].definition,
          'having no slack; rigid; stiff; tight');
      expect(vocab2.definitions[2].pos!.length, 1);
      expect(vocab2.definitions[2].pos![0], PartOfSpeech.adverb);
      expect(vocab2.definitions[2].miscInfo!.length, 2);
      expect(vocab2.definitions[2].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      expect(vocab2.definitions[2].miscInfo![1],
          MiscellaneousInfo.onomatopoeicOrMimeticWord);
      // Definition 4
      expect(vocab2.definitions[3].definition, 'suddenly; abruptly; instantly');
      expect(vocab2.definitions[3].pos!.length, 1);
      expect(vocab2.definitions[3].pos![0], PartOfSpeech.adverb);
      expect(vocab2.definitions[3].miscInfo!.length, 3);
      expect(vocab2.definitions[3].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      expect(vocab2.definitions[3].miscInfo![1],
          MiscellaneousInfo.onomatopoeicOrMimeticWord);
      expect(vocab2.definitions[3].miscInfo![2], MiscellaneousInfo.archaism);
      // Example
      expect(vocab2.examples!.length, 1);
      expect(vocab2.examples![0].index, 0);
      expect(vocab2.examples![0].japanese, 'でもよー、オラのおとうさんは良い気しねーよ、きっと。');
      expect(vocab2.examples![0].english,
          'But I don\'t think Dad would like me to.');
      // Japanese text index
      expect(vocab2.japaneseTextIndex.length, 3);
      expect(vocab2.japaneseTextIndex[0], 'きっと');
      expect(vocab2.japaneseTextIndex[1], '屹度');
      expect(vocab2.japaneseTextIndex[2], '急度');
      // Romaji text index
      expect(vocab2.romajiTextIndex.length, 2);
      expect(vocab2.romajiTextIndex[0], 'kitto');
      expect(vocab2.romajiTextIndex[1], 'kito');

      final vocab3 = await isar.vocabs.get(1578850);
      expect(vocab3!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab3.kanjiReadingPairs.length, 1);
      // Pair 1
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
          'to go; to move (in a direction or towards a specific location); to head (towards); to be transported (towards); to reach');
      expect(vocab3.definitions[0].pos!.length, 2);
      expect(vocab3.definitions[0].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[0].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 2
      expect(vocab3.definitions[1].definition, 'to proceed; to take place');
      expect(vocab3.definitions[1].additionalInfo,
          'い sometimes omitted in auxiliary use');
      expect(vocab3.definitions[1].pos!.length, 2);
      expect(vocab3.definitions[1].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[1].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 3
      expect(
          vocab3.definitions[2].definition, 'to pass through; to come and go');
      expect(vocab3.definitions[2].pos!.length, 2);
      expect(vocab3.definitions[2].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[2].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 4
      expect(vocab3.definitions[3].definition, 'to walk');
      expect(vocab3.definitions[3].pos!.length, 2);
      expect(vocab3.definitions[3].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[3].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 5
      expect(vocab3.definitions[4].definition, 'to die; to pass away');
      expect(vocab3.definitions[4].pos!.length, 2);
      expect(vocab3.definitions[4].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[4].pos![1], PartOfSpeech.verbIntransitive);
      expect(vocab3.definitions[4].appliesTo!.length, 1);
      expect(vocab3.definitions[4].appliesTo![0], '逝く');
      // Definition 6
      expect(vocab3.definitions[5].definition, 'to do (in a specific way)');
      expect(vocab3.definitions[5].pos!.length, 2);
      expect(vocab3.definitions[5].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[5].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 7
      expect(vocab3.definitions[6].definition, 'to stream; to flow');
      expect(vocab3.definitions[6].pos!.length, 2);
      expect(vocab3.definitions[6].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[6].pos![1], PartOfSpeech.verbIntransitive);
      // Definition 8
      expect(vocab3.definitions[7].definition, 'to continue');
      expect(
          vocab3.definitions[7].additionalInfo, 'after the -te form of a verb');
      expect(vocab3.definitions[7].pos!.length, 2);
      expect(vocab3.definitions[7].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[7].pos![1], PartOfSpeech.auxiliaryV);
      expect(vocab3.definitions[7].miscInfo!.length, 1);
      expect(vocab3.definitions[7].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      // Definition 9
      expect(vocab3.definitions[8].definition,
          'to have an orgasm; to come; to cum');
      expect(vocab3.definitions[8].pos!.length, 2);
      expect(vocab3.definitions[8].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[8].pos![1], PartOfSpeech.verbIntransitive);
      expect(vocab3.definitions[8].miscInfo!.length, 1);
      expect(vocab3.definitions[8].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      // Definition 10
      expect(vocab3.definitions[9].definition,
          'to trip; to get high; to have a drug-induced hallucination');
      expect(vocab3.definitions[9].pos!.length, 2);
      expect(vocab3.definitions[9].pos![0], PartOfSpeech.verbGodanKS);
      expect(vocab3.definitions[9].pos![1], PartOfSpeech.verbIntransitive);
      expect(vocab3.definitions[9].miscInfo!.length, 2);
      expect(vocab3.definitions[9].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      expect(vocab3.definitions[9].miscInfo![1], MiscellaneousInfo.slang);
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
      // Japanese text index
      expect(vocab3.japaneseTextIndex.length, 5);
      expect(vocab3.japaneseTextIndex[0], 'いく');
      expect(vocab3.japaneseTextIndex[1], 'ゆく');
      expect(vocab3.japaneseTextIndex[2], '行く');
      expect(vocab3.japaneseTextIndex[3], '逝く');
      expect(vocab3.japaneseTextIndex[4], '往く');
      // Romaji text index
      expect(vocab3.romajiTextIndex.length, 2);
      expect(vocab3.romajiTextIndex[0], 'iku');
      expect(vocab3.romajiTextIndex[1], 'yuku');

      final vocab4 = await isar.vocabs.get(2002400);
      expect(vocab4!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab4.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab4.kanjiReadingPairs[0].kanjiWritings, null);
      expect(vocab4.kanjiReadingPairs[0].readings.length, 3);
      expect(vocab4.kanjiReadingPairs[0].readings[0].reading, 'ううん');
      expect(vocab4.kanjiReadingPairs[0].readings[1].reading, 'うーん');
      expect(vocab4.kanjiReadingPairs[0].readings[2].reading, 'ウーン');
      // Definitions
      expect(vocab4.definitions.length, 3);
      // Definition 1
      expect(vocab4.definitions[0].definition, 'um; er; well');
      expect(vocab4.definitions[0].pos!.length, 1);
      expect(vocab4.definitions[0].pos![0], PartOfSpeech.interjection);
      // Definition 2
      expect(vocab4.definitions[1].definition, 'nuh-uh; no');
      expect(vocab4.definitions[1].pos!.length, 1);
      expect(vocab4.definitions[1].pos![0], PartOfSpeech.interjection);
      expect(vocab4.definitions[1].appliesTo!.length, 1);
      expect(vocab4.definitions[1].appliesTo![0], 'ううん');
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
      // Japanese text index
      expect(vocab4.japaneseTextIndex.length, 2);
      expect(vocab4.japaneseTextIndex[0], 'ううん');
      expect(vocab4.japaneseTextIndex[1], 'うーん');
      // Romaji text index
      expect(vocab4.romajiTextIndex.length, 3);
      expect(vocab4.romajiTextIndex[0], 'uun');
      expect(vocab4.romajiTextIndex[1], 'un');
      expect(vocab4.romajiTextIndex[2], 'u-n');

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
      // Japanese text index
      expect(vocab5.japaneseTextIndex.length, 9);
      expect(vocab5.japaneseTextIndex[0], 'おまちどおさま');
      expect(vocab5.japaneseTextIndex[1], 'お待ちどおさま');
      expect(vocab5.japaneseTextIndex[2], 'お待ちどお様');
      expect(vocab5.japaneseTextIndex[3], 'おまちどうさま');
      expect(vocab5.japaneseTextIndex[4], 'お待ち遠様');
      expect(vocab5.japaneseTextIndex[5], '御待ち遠様');
      expect(vocab5.japaneseTextIndex[6], 'お待ち遠さま');
      expect(vocab5.japaneseTextIndex[7], 'お待ちどうさま');
      expect(vocab5.japaneseTextIndex[8], 'お待ちどう様');
      // Romaji text index
      expect(vocab5.romajiTextIndex.length, 3);
      expect(vocab5.romajiTextIndex[0], 'omachidoosama');
      expect(vocab5.romajiTextIndex[1], 'omachidousama');
      expect(vocab5.romajiTextIndex[2], 'omachidosama');

      final vocab6 = await isar.vocabs.get(1001390);
      expect(vocab6!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab6.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings!.length, 2);
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings![0].kanji, '御田');
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings![0].info!.length, 1);
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings![0].info![0],
          KanjiInfo.rareKanjiForm);
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings![1].kanji, 'お田');
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings![1].info!.length, 1);
      expect(vocab6.kanjiReadingPairs[0].kanjiWritings![1].info![0],
          KanjiInfo.rareKanjiForm);
      expect(vocab6.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab6.kanjiReadingPairs[0].readings[0].reading, 'おでん');
      // Definition
      expect(vocab6.definitions.length, 1);
      expect(vocab6.definitions[0].definition,
          'oden; dish of various ingredients, e.g. egg, daikon, potato, chikuwa, konnyaku stewed in soy-flavored dashi');
      expect(vocab6.definitions[0].pos!.length, 1);
      expect(vocab6.definitions[0].pos![0], PartOfSpeech.noun);
      expect(vocab6.definitions[0].fields!.length, 1);
      expect(vocab6.definitions[0].fields![0], Field.foodCooking);
      expect(vocab6.definitions[0].miscInfo!.length, 1);
      expect(vocab6.definitions[0].miscInfo![0],
          MiscellaneousInfo.usuallyKanaAlone);
      // Japanese text index
      expect(vocab6.japaneseTextIndex.length, 3);
      expect(vocab6.japaneseTextIndex[0], 'おでん');
      expect(vocab6.japaneseTextIndex[1], '御田');
      expect(vocab6.japaneseTextIndex[2], 'お田');
      // Romaji text index
      expect(vocab6.romajiTextIndex.length, 1);
      expect(vocab6.romajiTextIndex[0], 'oden');

      final vocab7 = await isar.vocabs.get(2067590);
      expect(vocab7!.commonWord, false);
      // Kanji-reading pairs
      expect(vocab7.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab7.kanjiReadingPairs[0].readings.length, 3);
      expect(vocab7.kanjiReadingPairs[0].readings[0].reading, 'めんこい');
      expect(vocab7.kanjiReadingPairs[0].readings[1].reading, 'めごい');
      expect(vocab7.kanjiReadingPairs[0].readings[2].reading, 'めんごい');
      // Definition
      expect(vocab7.definitions.length, 1);
      expect(vocab7.definitions[0].definition,
          'dear; darling; adorable; precious; cute; lovely; sweet; beloved; charming');
      expect(vocab7.definitions[0].pos!.length, 1);
      expect(vocab7.definitions[0].pos![0], PartOfSpeech.adjectiveI);
      expect(vocab7.definitions[0].dialects!.length, 2);
      expect(vocab7.definitions[0].dialects![0], Dialect.touhokuBen);
      expect(vocab7.definitions[0].dialects![1], Dialect.hokkaidoBen);
      // Japanese text index
      expect(vocab7.japaneseTextIndex.length, 3);
      expect(vocab7.japaneseTextIndex[0], 'めんこい');
      expect(vocab7.japaneseTextIndex[1], 'めごい');
      expect(vocab7.japaneseTextIndex[2], 'めんごい');
      // Romaji text index
      expect(vocab7.romajiTextIndex.length, 3);
      expect(vocab7.romajiTextIndex[0], 'menkoi');
      expect(vocab7.romajiTextIndex[1], 'megoi');
      expect(vocab7.romajiTextIndex[2], 'mengoi');

      final vocab8 = await isar.vocabs.get(1000160);
      expect(vocab8!.commonWord, true);
      // Kanji-reading pairs
      expect(vocab8.kanjiReadingPairs.length, 1);
      // Pair 1
      expect(vocab8.kanjiReadingPairs[0].kanjiWritings!.length, 1);
      expect(vocab8.kanjiReadingPairs[0].kanjiWritings![0].kanji, 'Ｔシャツ');
      expect(vocab8.kanjiReadingPairs[0].readings.length, 1);
      expect(vocab8.kanjiReadingPairs[0].readings[0].reading, 'ティーシャツ');
      // Definition
      expect(vocab8.definitions.length, 1);
      expect(vocab8.definitions[0].definition, 'T-shirt; tee shirt');
      expect(vocab8.definitions[0].pos!.length, 1);
      expect(vocab8.definitions[0].pos![0], PartOfSpeech.noun);
      // Japanese text index
      expect(vocab8.japaneseTextIndex.length, 2);
      expect(vocab8.japaneseTextIndex[0], 'てぃいしゃつ');
      expect(vocab8.japaneseTextIndex[1], 'tしゃつ');
      // Romaji text index
      expect(vocab8.romajiTextIndex.length, 2);
      expect(vocab8.romajiTextIndex[0], 'teiishatsu');
      expect(vocab8.romajiTextIndex[1], 'teishatsu');
    });

    test('Kanji radicals database creation with short source', () async {
      await DictionaryUtils.createRadicalDictionaryIsolate(
        shortKanjiRadicalData,
        shortKanjiStrokeData,
        isar,
      );

      final radical1 = await isar.kanjiRadicals.getByRadical('一');
      expect(radical1!.radical, '一');
      expect(radical1.kangxiId, 1);
      expect(radical1.strokeCount, 1);
      expect(radical1.meaning, 'one');
      expect(radical1.reading, 'イチ');
      expect(radical1.position, KanjiRadicalPosition.none);
      expect(radical1.importance, KanjiRadicalImportance.top75);
      expect(radical1.strokes!.length, 1);
      expect(radical1.variants, null);
      expect(radical1.variantOf, null);

      final radical2 = await isar.kanjiRadicals.getByRadical('乙');
      expect(radical2!.radical, '乙');
      expect(radical2.strokeCount, 1);
      expect(radical2.meaning, 'second');
      expect(radical2.kangxiId, 5);
      expect(radical2.reading, 'オツ, おつにょう, つりばり');
      expect(radical2.position, KanjiRadicalPosition.none);
      expect(radical2.importance, KanjiRadicalImportance.none);
      expect(radical2.variants, ['乚']);
      expect(radical2.variantOf, null);

      final radical3 = await isar.kanjiRadicals.getByRadical('乚');
      expect(radical3!.radical, '乚');
      expect(radical3.kangxiId, null);
      expect(radical3.strokeCount, 1);
      expect(radical3.meaning, 'second');
      expect(radical3.reading, 'オツ, おつにょう, つりばり');
      expect(radical3.position, KanjiRadicalPosition.none);
      expect(radical3.importance, KanjiRadicalImportance.none);
      expect(radical3.variants, null);
      expect(radical3.variantOf, '乙');
    });

    test('Kanji database creation with short source dictionary', () async {
      // First create radicals
      await DictionaryUtils.createRadicalDictionaryIsolate(
        shortKanjiRadicalData,
        shortKanjiStrokeData,
        isar,
      );

      // Create kanji dictionary
      await DictionaryUtils.createKanjiDictionaryIsolate(
        shortKanjidic2,
        shortKanjiComponents,
        shortKanjiStrokeData,
        isar,
      );

      final kanji1 = await isar.kanjis.get(20811601);
      expect(kanji1!.kanji, '亜');
      await kanji1.radical.load();
      expect(kanji1.radical.value!.kangxiId, 7);
      await kanji1.componentLinks.load();
      expect(kanji1.componentLinks.length, 2);
      expect(kanji1.componentLinks.elementAt(0).kanji, '一');
      expect(kanji1.componentLinks.elementAt(1).kanji, '口');
      expect(kanji1.grade, 255);
      expect(kanji1.strokeCount, 7);
      expect(kanji1.frequency, 1509);
      expect(kanji1.jlpt, 1);
      expect(kanji1.meanings, 'Asia, rank next, come after, -ous');
      expect(kanji1.onReadings!.length, 1);
      expect(kanji1.onReadings![0], 'ア');
      expect(kanji1.kunReadings!.length, 1);
      expect(kanji1.kunReadings![0], 'つ.ぐ');
      expect(kanji1.nanori!.length, 3);
      expect(kanji1.nanori![0], 'や');
      expect(kanji1.nanori![1], 'つぎ');
      expect(kanji1.nanori![2], 'つぐ');
      expect(kanji1.strokes!.length, 7);

      final kanji2 = await isar.kanjis.get(20811613);
      expect(kanji2!.kanji, '悪');
      await kanji2.radical.load();
      expect(kanji2.radical.value!.kangxiId, 61);
      await kanji2.componentLinks.load();
      expect(kanji2.componentLinks.length, 2);
      expect(kanji2.componentLinks.elementAt(0).kanji, '一');
      expect(kanji2.componentLinks.elementAt(1).kanji, '口');
      expect(kanji2.grade, 3);
      expect(kanji2.strokeCount, 11);
      expect(kanji2.frequency, 530);
      expect(kanji2.jlpt, 3);
      expect(kanji2.meanings, 'bad, vice, rascal, false, evil, wrong');
      expect(kanji2.onReadings!.length, 2);
      expect(kanji2.onReadings![0], 'アク');
      expect(kanji2.onReadings![1], 'オ');
      expect(kanji2.kunReadings!.length, 9);
      expect(kanji2.kunReadings![0], 'わる.い');
      expect(kanji2.kunReadings![1], 'わる-');
      expect(kanji2.kunReadings![2], 'あ.し');
      expect(kanji2.kunReadings![3], 'にく.い');
      expect(kanji2.kunReadings![4], '-にく.い');
      expect(kanji2.kunReadings![5], 'ああ');
      expect(kanji2.kunReadings![6], 'いずくに');
      expect(kanji2.kunReadings![7], 'いずくんぞ');
      expect(kanji2.kunReadings![8], 'にく.む');
      expect(kanji2.nanori, null);

      final kanji3 = await isar.kanjis.get(20814819);
      expect(kanji3!.kanji, '亞');
      await kanji3.radical.load();
      expect(kanji3.radical.value!.kangxiId, 7);
      await kanji3.componentLinks.load();
      expect(kanji3.componentLinks.length, 1);
      expect(kanji3.componentLinks.elementAt(0).kanji, '一');
      expect(kanji3.grade, 255);
      expect(kanji3.strokeCount, 8);
      expect(kanji3.frequency, null);
      expect(kanji3.jlpt, 255);
      expect(kanji3.meanings, 'rank, follow');
      expect(kanji3.onReadings!.length, 1);
      expect(kanji3.onReadings![0], 'ア');
      expect(kanji3.kunReadings!.length, 1);
      expect(kanji3.kunReadings![0], 'つ.ぐ');
      expect(kanji3.nanori, null);
    });

    test('Vocab-kanji links', () async {
      await DictionaryUtils.createDictionaryIsolate(
        const DictionarySource(
          compoundTestJMdict,
          compoundTestKanjidic2,
          '# Nothing',
          '',
          '',
          '{}',
          '{}',
        ),
        testingIsar: isar,
      );

      final kanji = await isar.kanjis.get(20813521);
      expect(kanji!.compounds.length, 2);
      await kanji.compounds.load();
      expect(kanji.compounds.elementAt(0).id, 1227150);
      expect(kanji.compounds.elementAt(1).id, 1593670);
    });
  });
}
