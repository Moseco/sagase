import 'package:flutter_test/flutter_test.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/utils/conjugation_utils.dart';

void main() {
  group('ConjugationUtilsTest', () {
    const conjugationUtils = ConjugationUtils();

    test('conjugate adjectiveI', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '怖い']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.adjectiveI]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '怖い');
      expect(list[0].negative, '怖くない');
      expect(list[1].positive, '怖かった');
      expect(list[1].negative, '怖くなかった');
    });

    test('conjugate adjectiveI - vocab level pos', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '怖い']
        ]
        ..definitions = [VocabDefinition()]
        ..pos = [PartOfSpeech.adjectiveI];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '怖い');
      expect(list[0].negative, '怖くない');
      expect(list[1].positive, '怖かった');
      expect(list[1].negative, '怖くなかった');
    });

    test('conjugate adjectiveNa', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '綺麗']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.adjectiveNa]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '綺麗だ');
      expect(list[0].negative, '綺麗じゃない');
      expect(list[1].positive, '綺麗だった');
      expect(list[1].negative, '綺麗じゃなかった');
    });

    test('conjugate adjectiveNa short', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '神']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.adjectiveNa]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '神だ');
      expect(list[0].negative, '神じゃない');
      expect(list[1].positive, '神だった');
      expect(list[1].negative, '神じゃなかった');
    });

    test('conjugate adjectiveIx', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '頭がいい']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.adjectiveIx]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '頭がいい');
      expect(list[0].negative, '頭がよくない');
      expect(list[1].positive, '頭がよかった');
      expect(list[1].negative, '頭がよくなかった');
    });

    test('conjugate verbIchidan', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '上げる']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbIchidan]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '上げる');
      expect(list[0].negative, '上げない');
      expect(list[1].positive, '上げます');
      expect(list[1].negative, '上げません');
      expect(list[2].positive, '上げた');
      expect(list[2].negative, '上げなかった');
      expect(list[3].positive, '上げました');
      expect(list[3].negative, '上げませんでした');
      expect(list[4].positive, '上げて');
      expect(list[4].negative, '上げなくて');
      expect(list[5].positive, '上げよう');
      expect(list[5].negative, '上げまい');
      expect(list[6].positive, '上げましょう');
      expect(list[6].negative, '上げますまい');
      expect(list[7].positive, '上げられる');
      expect(list[7].negative, '上げられない');
      expect(list[8].positive, '上げられます');
      expect(list[8].negative, '上げられません');
      expect(list[9].positive, '上げられる');
      expect(list[9].negative, '上げられない');
      expect(list[10].positive, '上げられます');
      expect(list[10].negative, '上げられません');
      expect(list[11].positive, '上げさせる');
      expect(list[11].negative, '上げさせない');
      expect(list[12].positive, '上げさせます');
      expect(list[12].negative, '上げさせません');
      expect(list[13].positive, '上げさせられる');
      expect(list[13].negative, '上げさせられない');
      expect(list[14].positive, '上げろ');
      expect(list[14].negative, '上げるな');
      expect(list[15].positive, '上げなさい');
      expect(list[15].negative, '上げなさるな');
    });

    test('conjugate verbIchidanS', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()
            ..kanjiWritings = [VocabKanji()..kanji = '呉れる']
            ..readings = [VocabReading()..reading = 'くれる']
        ]
        ..definitions = [
          VocabDefinition()
            ..pos = [PartOfSpeech.verbIchidanS]
            ..miscInfo = [MiscellaneousInfo.usuallyKanaAlone]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, 'くれる');
      expect(list[0].negative, 'くれない');
      expect(list[1].positive, 'くれます');
      expect(list[1].negative, 'くれません');
      expect(list[2].positive, 'くれた');
      expect(list[2].negative, 'くれなかった');
      expect(list[3].positive, 'くれました');
      expect(list[3].negative, 'くれませんでした');
      expect(list[4].positive, 'くれて');
      expect(list[4].negative, 'くれなくて');
      expect(list[5].positive, 'くれよう');
      expect(list[5].negative, 'くれまい');
      expect(list[6].positive, 'くれましょう');
      expect(list[6].negative, 'くれますまい');
      expect(list[7].positive, 'くれられる');
      expect(list[7].negative, 'くれられない');
      expect(list[8].positive, 'くれられます');
      expect(list[8].negative, 'くれられません');
      expect(list[9].positive, 'くれられる');
      expect(list[9].negative, 'くれられない');
      expect(list[10].positive, 'くれられます');
      expect(list[10].negative, 'くれられません');
      expect(list[11].positive, 'くれさせる');
      expect(list[11].negative, 'くれさせない');
      expect(list[12].positive, 'くれさせます');
      expect(list[12].negative, 'くれさせません');
      expect(list[13].positive, 'くれさせられる');
      expect(list[13].negative, 'くれさせられない');
      expect(list[14].positive, 'くれ');
      expect(list[14].negative, 'くれるな');
      expect(list[15].positive, 'くれなさい');
      expect(list[15].negative, 'くれなさるな');
    });

    test('conjugate verbGodanAru', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()
            ..kanjiWritings = [VocabKanji()..kanji = '為さる']
            ..readings = [VocabReading()..reading = 'なさる']
        ]
        ..definitions = [
          VocabDefinition()
            ..pos = [PartOfSpeech.verbGodanAru]
            ..miscInfo = [MiscellaneousInfo.usuallyKanaAlone]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, 'なさる');
      expect(list[0].negative, 'なさらない');
      expect(list[1].positive, 'なさいます');
      expect(list[1].negative, 'なさいません');
      expect(list[2].positive, 'なさった');
      expect(list[2].negative, 'なさらなかった');
      expect(list[3].positive, 'なさいました');
      expect(list[3].negative, 'なさいませんでした');
      expect(list[4].positive, 'なさって');
      expect(list[4].negative, 'なさらなくて');
      expect(list[5].positive, 'なさろう');
      expect(list[5].negative, 'なさるまい');
      expect(list[6].positive, 'なさいましょう');
      expect(list[6].negative, 'なさいませんまい');
      expect(list[7].positive, 'なされる');
      expect(list[7].negative, 'なされない');
      expect(list[8].positive, 'なされます');
      expect(list[8].negative, 'なされません');
      expect(list[9].positive, 'なさられる');
      expect(list[9].negative, 'なさられない');
      expect(list[10].positive, 'なさられます');
      expect(list[10].negative, 'なさられません');
      expect(list[11].positive, 'なさらせる');
      expect(list[11].negative, 'なさらせない');
      expect(list[12].positive, 'なさらせます');
      expect(list[12].negative, 'なさらせません');
      expect(list[13].positive, 'なさらせられる');
      expect(list[13].negative, 'なさらせられない');
      expect(list[14].positive, 'なさい');
      expect(list[14].negative, 'なさるな');
      expect(list[15].positive, 'なさいなさい');
      expect(list[15].negative, 'なさいなさるな');
    });

    test('conjugate verbGodanB', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '呼ぶ']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanB]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '呼ぶ');
      expect(list[0].negative, '呼ばない');
      expect(list[1].positive, '呼びます');
      expect(list[1].negative, '呼びません');
      expect(list[2].positive, '呼んだ');
      expect(list[2].negative, '呼ばなかった');
      expect(list[3].positive, '呼びました');
      expect(list[3].negative, '呼びませんでした');
      expect(list[4].positive, '呼んで');
      expect(list[4].negative, '呼ばなくて');
      expect(list[5].positive, '呼ぼう');
      expect(list[5].negative, '呼ぶまい');
      expect(list[6].positive, '呼びましょう');
      expect(list[6].negative, '呼びませんまい');
      expect(list[7].positive, '呼べる');
      expect(list[7].negative, '呼べない');
      expect(list[8].positive, '呼べます');
      expect(list[8].negative, '呼べません');
      expect(list[9].positive, '呼ばれる');
      expect(list[9].negative, '呼ばれない');
      expect(list[10].positive, '呼ばれます');
      expect(list[10].negative, '呼ばれません');
      expect(list[11].positive, '呼ばせる');
      expect(list[11].negative, '呼ばせない');
      expect(list[12].positive, '呼ばせます');
      expect(list[12].negative, '呼ばせません');
      expect(list[13].positive, '呼ばせられる');
      expect(list[13].negative, '呼ばせられない');
      expect(list[14].positive, '呼べ');
      expect(list[14].negative, '呼ぶな');
      expect(list[15].positive, '呼びなさい');
      expect(list[15].negative, '呼びなさるな');
    });

    test('conjugate verbGodanG', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '泳ぐ']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanG]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '泳ぐ');
      expect(list[0].negative, '泳がない');
      expect(list[1].positive, '泳ぎます');
      expect(list[1].negative, '泳ぎません');
      expect(list[2].positive, '泳いだ');
      expect(list[2].negative, '泳がなかった');
      expect(list[3].positive, '泳ぎました');
      expect(list[3].negative, '泳ぎませんでした');
      expect(list[4].positive, '泳いで');
      expect(list[4].negative, '泳がなくて');
      expect(list[5].positive, '泳ごう');
      expect(list[5].negative, '泳ぐまい');
      expect(list[6].positive, '泳ぎましょう');
      expect(list[6].negative, '泳ぎませんまい');
      expect(list[7].positive, '泳げる');
      expect(list[7].negative, '泳げない');
      expect(list[8].positive, '泳げます');
      expect(list[8].negative, '泳げません');
      expect(list[9].positive, '泳がれる');
      expect(list[9].negative, '泳がれない');
      expect(list[10].positive, '泳がれます');
      expect(list[10].negative, '泳がれません');
      expect(list[11].positive, '泳がせる');
      expect(list[11].negative, '泳がせない');
      expect(list[12].positive, '泳がせます');
      expect(list[12].negative, '泳がせません');
      expect(list[13].positive, '泳がせられる');
      expect(list[13].negative, '泳がせられない');
      expect(list[14].positive, '泳げ');
      expect(list[14].negative, '泳ぐな');
      expect(list[15].positive, '泳ぎなさい');
      expect(list[15].negative, '泳ぎなさるな');
    });

    test('conjugate verbGodanK', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '書く']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanK]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '書く');
      expect(list[0].negative, '書かない');
      expect(list[1].positive, '書きます');
      expect(list[1].negative, '書きません');
      expect(list[2].positive, '書いた');
      expect(list[2].negative, '書かなかった');
      expect(list[3].positive, '書きました');
      expect(list[3].negative, '書きませんでした');
      expect(list[4].positive, '書いて');
      expect(list[4].negative, '書かなくて');
      expect(list[5].positive, '書こう');
      expect(list[5].negative, '書くまい');
      expect(list[6].positive, '書きましょう');
      expect(list[6].negative, '書きませんまい');
      expect(list[7].positive, '書ける');
      expect(list[7].negative, '書けない');
      expect(list[8].positive, '書けます');
      expect(list[8].negative, '書けません');
      expect(list[9].positive, '書かれる');
      expect(list[9].negative, '書かれない');
      expect(list[10].positive, '書かれます');
      expect(list[10].negative, '書かれません');
      expect(list[11].positive, '書かせる');
      expect(list[11].negative, '書かせない');
      expect(list[12].positive, '書かせます');
      expect(list[12].negative, '書かせません');
      expect(list[13].positive, '書かせられる');
      expect(list[13].negative, '書かせられない');
      expect(list[14].positive, '書け');
      expect(list[14].negative, '書くな');
      expect(list[15].positive, '書きなさい');
      expect(list[15].negative, '書きなさるな');
    });

    test('conjugate verbGodanKS', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '行く']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanKS]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '行く');
      expect(list[0].negative, '行かない');
      expect(list[1].positive, '行きます');
      expect(list[1].negative, '行きません');
      expect(list[2].positive, '行った');
      expect(list[2].negative, '行かなかった');
      expect(list[3].positive, '行きました');
      expect(list[3].negative, '行きませんでした');
      expect(list[4].positive, '行って');
      expect(list[4].negative, '行かなくて');
      expect(list[5].positive, '行こう');
      expect(list[5].negative, '行くまい');
      expect(list[6].positive, '行きましょう');
      expect(list[6].negative, '行きませんまい');
      expect(list[7].positive, '行ける');
      expect(list[7].negative, '行けない');
      expect(list[8].positive, '行けます');
      expect(list[8].negative, '行けません');
      expect(list[9].positive, '行かれる');
      expect(list[9].negative, '行かれない');
      expect(list[10].positive, '行かれます');
      expect(list[10].negative, '行かれません');
      expect(list[11].positive, '行かせる');
      expect(list[11].negative, '行かせない');
      expect(list[12].positive, '行かせます');
      expect(list[12].negative, '行かせません');
      expect(list[13].positive, '行かせられる');
      expect(list[13].negative, '行かせられない');
      expect(list[14].positive, '行け');
      expect(list[14].negative, '行くな');
      expect(list[15].positive, '行きなさい');
      expect(list[15].negative, '行きなさるな');
    });

    test('conjugate verbGodanM', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '飲む']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanM]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '飲む');
      expect(list[0].negative, '飲まない');
      expect(list[1].positive, '飲みます');
      expect(list[1].negative, '飲みません');
      expect(list[2].positive, '飲んだ');
      expect(list[2].negative, '飲まなかった');
      expect(list[3].positive, '飲みました');
      expect(list[3].negative, '飲みませんでした');
      expect(list[4].positive, '飲んで');
      expect(list[4].negative, '飲まなくて');
      expect(list[5].positive, '飲もう');
      expect(list[5].negative, '飲むまい');
      expect(list[6].positive, '飲みましょう');
      expect(list[6].negative, '飲みませんまい');
      expect(list[7].positive, '飲める');
      expect(list[7].negative, '飲めない');
      expect(list[8].positive, '飲めます');
      expect(list[8].negative, '飲めません');
      expect(list[9].positive, '飲まれる');
      expect(list[9].negative, '飲まれない');
      expect(list[10].positive, '飲まれます');
      expect(list[10].negative, '飲まれません');
      expect(list[11].positive, '飲ませる');
      expect(list[11].negative, '飲ませない');
      expect(list[12].positive, '飲ませます');
      expect(list[12].negative, '飲ませません');
      expect(list[13].positive, '飲ませられる');
      expect(list[13].negative, '飲ませられない');
      expect(list[14].positive, '飲め');
      expect(list[14].negative, '飲むな');
      expect(list[15].positive, '飲みなさい');
      expect(list[15].negative, '飲みなさるな');
    });

    test('conjugate verbGodanN', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '死ぬ']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanN]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '死ぬ');
      expect(list[0].negative, '死なない');
      expect(list[1].positive, '死にます');
      expect(list[1].negative, '死にません');
      expect(list[2].positive, '死んだ');
      expect(list[2].negative, '死ななかった');
      expect(list[3].positive, '死にました');
      expect(list[3].negative, '死にませんでした');
      expect(list[4].positive, '死んで');
      expect(list[4].negative, '死ななくて');
      expect(list[5].positive, '死のう');
      expect(list[5].negative, '死ぬまい');
      expect(list[6].positive, '死にましょう');
      expect(list[6].negative, '死にませんまい');
      expect(list[7].positive, '死ねる');
      expect(list[7].negative, '死ねない');
      expect(list[8].positive, '死ねます');
      expect(list[8].negative, '死ねません');
      expect(list[9].positive, '死なれる');
      expect(list[9].negative, '死なれない');
      expect(list[10].positive, '死なれます');
      expect(list[10].negative, '死なれません');
      expect(list[11].positive, '死なせる');
      expect(list[11].negative, '死なせない');
      expect(list[12].positive, '死なせます');
      expect(list[12].negative, '死なせません');
      expect(list[13].positive, '死なせられる');
      expect(list[13].negative, '死なせられない');
      expect(list[14].positive, '死ね');
      expect(list[14].negative, '死ぬな');
      expect(list[15].positive, '死になさい');
      expect(list[15].negative, '死になさるな');
    });

    test('conjugate verbGodanR', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '知る']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanR]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '知る');
      expect(list[0].negative, '知らない');
      expect(list[1].positive, '知ります');
      expect(list[1].negative, '知りません');
      expect(list[2].positive, '知った');
      expect(list[2].negative, '知らなかった');
      expect(list[3].positive, '知りました');
      expect(list[3].negative, '知りませんでした');
      expect(list[4].positive, '知って');
      expect(list[4].negative, '知らなくて');
      expect(list[5].positive, '知ろう');
      expect(list[5].negative, '知るまい');
      expect(list[6].positive, '知りましょう');
      expect(list[6].negative, '知りませんまい');
      expect(list[7].positive, '知れる');
      expect(list[7].negative, '知れない');
      expect(list[8].positive, '知れます');
      expect(list[8].negative, '知れません');
      expect(list[9].positive, '知られる');
      expect(list[9].negative, '知られない');
      expect(list[10].positive, '知られます');
      expect(list[10].negative, '知られません');
      expect(list[11].positive, '知らせる');
      expect(list[11].negative, '知らせない');
      expect(list[12].positive, '知らせます');
      expect(list[12].negative, '知らせません');
      expect(list[13].positive, '知らせられる');
      expect(list[13].negative, '知らせられない');
      expect(list[14].positive, '知れ');
      expect(list[14].negative, '知るな');
      expect(list[15].positive, '知りなさい');
      expect(list[15].negative, '知りなさるな');
    });

    test('conjugate verbGodanRI', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()
            ..kanjiWritings = [VocabKanji()..kanji = '有る']
            ..readings = [VocabReading()..reading = 'ある']
        ]
        ..definitions = [
          VocabDefinition()
            ..pos = [PartOfSpeech.verbGodanRI]
            ..miscInfo = [MiscellaneousInfo.usuallyKanaAlone]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, 'ある');
      expect(list[0].negative, 'ない');
      expect(list[1].positive, 'あります');
      expect(list[1].negative, 'ありません');
      expect(list[2].positive, 'あった');
      expect(list[2].negative, 'なかった');
      expect(list[3].positive, 'ありました');
      expect(list[3].negative, 'ありませんでした');
      expect(list[4].positive, 'あって');
      expect(list[4].negative, 'なくて');
      expect(list[5].positive, 'あろう');
      expect(list[5].negative, 'あるまい');
      expect(list[6].positive, 'ありましょう');
      expect(list[6].negative, 'ありませんまい');
      expect(list[7].positive, 'あれる');
      expect(list[7].negative, 'あれない');
      expect(list[8].positive, 'あれます');
      expect(list[8].negative, 'あれません');
      expect(list[9].positive, 'あられる');
      expect(list[9].negative, 'あられない');
      expect(list[10].positive, 'あられます');
      expect(list[10].negative, 'あられません');
      expect(list[11].positive, 'あらせる');
      expect(list[11].negative, 'あらせない');
      expect(list[12].positive, 'あらせます');
      expect(list[12].negative, 'あらせません');
      expect(list[13].positive, 'あらせられる');
      expect(list[13].negative, 'あらせられない');
      expect(list[14].positive, 'あれ');
      expect(list[14].negative, 'あるな');
      expect(list[15].positive, 'ありなさい');
      expect(list[15].negative, 'ありなさるな');
    });

    test('conjugate verbGodanS', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '話す']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanS]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '話す');
      expect(list[0].negative, '話さない');
      expect(list[1].positive, '話します');
      expect(list[1].negative, '話しません');
      expect(list[2].positive, '話した');
      expect(list[2].negative, '話さなかった');
      expect(list[3].positive, '話しました');
      expect(list[3].negative, '話しませんでした');
      expect(list[4].positive, '話して');
      expect(list[4].negative, '話さなくて');
      expect(list[5].positive, '話そう');
      expect(list[5].negative, '話すまい');
      expect(list[6].positive, '話しましょう');
      expect(list[6].negative, '話しませんまい');
      expect(list[7].positive, '話せる');
      expect(list[7].negative, '話せない');
      expect(list[8].positive, '話せます');
      expect(list[8].negative, '話せません');
      expect(list[9].positive, '話される');
      expect(list[9].negative, '話されない');
      expect(list[10].positive, '話されます');
      expect(list[10].negative, '話されません');
      expect(list[11].positive, '話させる');
      expect(list[11].negative, '話させない');
      expect(list[12].positive, '話させます');
      expect(list[12].negative, '話させません');
      expect(list[13].positive, '話させられる');
      expect(list[13].negative, '話させられない');
      expect(list[14].positive, '話せ');
      expect(list[14].negative, '話すな');
      expect(list[15].positive, '話しなさい');
      expect(list[15].negative, '話しなさるな');
    });

    test('conjugate verbGodanT', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '持つ']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanT]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '持つ');
      expect(list[0].negative, '持たない');
      expect(list[1].positive, '持ちます');
      expect(list[1].negative, '持ちません');
      expect(list[2].positive, '持った');
      expect(list[2].negative, '持たなかった');
      expect(list[3].positive, '持ちました');
      expect(list[3].negative, '持ちませんでした');
      expect(list[4].positive, '持って');
      expect(list[4].negative, '持たなくて');
      expect(list[5].positive, '持とう');
      expect(list[5].negative, '持つまい');
      expect(list[6].positive, '持ちましょう');
      expect(list[6].negative, '持ちませんまい');
      expect(list[7].positive, '持てる');
      expect(list[7].negative, '持てない');
      expect(list[8].positive, '持てます');
      expect(list[8].negative, '持てません');
      expect(list[9].positive, '持たれる');
      expect(list[9].negative, '持たれない');
      expect(list[10].positive, '持たれます');
      expect(list[10].negative, '持たれません');
      expect(list[11].positive, '持たせる');
      expect(list[11].negative, '持たせない');
      expect(list[12].positive, '持たせます');
      expect(list[12].negative, '持たせません');
      expect(list[13].positive, '持たせられる');
      expect(list[13].negative, '持たせられない');
      expect(list[14].positive, '持て');
      expect(list[14].negative, '持つな');
      expect(list[15].positive, '持ちなさい');
      expect(list[15].negative, '持ちなさるな');
    });

    test('conjugate verbGodanU', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '言う']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanU]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '言う');
      expect(list[0].negative, '言わない');
      expect(list[1].positive, '言います');
      expect(list[1].negative, '言いません');
      expect(list[2].positive, '言った');
      expect(list[2].negative, '言わなかった');
      expect(list[3].positive, '言いました');
      expect(list[3].negative, '言いませんでした');
      expect(list[4].positive, '言って');
      expect(list[4].negative, '言わなくて');
      expect(list[5].positive, '言おう');
      expect(list[5].negative, '言うまい');
      expect(list[6].positive, '言いましょう');
      expect(list[6].negative, '言いませんまい');
      expect(list[7].positive, '言える');
      expect(list[7].negative, '言えない');
      expect(list[8].positive, '言えます');
      expect(list[8].negative, '言えません');
      expect(list[9].positive, '言われる');
      expect(list[9].negative, '言われない');
      expect(list[10].positive, '言われます');
      expect(list[10].negative, '言われません');
      expect(list[11].positive, '言わせる');
      expect(list[11].negative, '言わせない');
      expect(list[12].positive, '言わせます');
      expect(list[12].negative, '言わせません');
      expect(list[13].positive, '言わせられる');
      expect(list[13].negative, '言わせられない');
      expect(list[14].positive, '言え');
      expect(list[14].negative, '言うな');
      expect(list[15].positive, '言いなさい');
      expect(list[15].negative, '言いなさるな');
    });

    test('conjugate verbGodanUS', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '問う']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbGodanUS]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '問う');
      expect(list[0].negative, '問わない');
      expect(list[1].positive, '問います');
      expect(list[1].negative, '問いません');
      expect(list[2].positive, '問うた');
      expect(list[2].negative, '問わなかった');
      expect(list[3].positive, '問いました');
      expect(list[3].negative, '問いませんでした');
      expect(list[4].positive, '問うて');
      expect(list[4].negative, '問わなくて');
      expect(list[5].positive, '問おう');
      expect(list[5].negative, '問うまい');
      expect(list[6].positive, '問いましょう');
      expect(list[6].negative, '問いませんまい');
      expect(list[7].positive, '問える');
      expect(list[7].negative, '問えない');
      expect(list[8].positive, '問えます');
      expect(list[8].negative, '問えません');
      expect(list[9].positive, '問われる');
      expect(list[9].negative, '問われない');
      expect(list[10].positive, '問われます');
      expect(list[10].negative, '問われません');
      expect(list[11].positive, '問わせる');
      expect(list[11].negative, '問わせない');
      expect(list[12].positive, '問わせます');
      expect(list[12].negative, '問わせません');
      expect(list[13].positive, '問わせられる');
      expect(list[13].negative, '問わせられない');
      expect(list[14].positive, '問え');
      expect(list[14].negative, '問うな');
      expect(list[15].positive, '問いなさい');
      expect(list[15].negative, '問いなさるな');
    });

    test('conjugate verbKuru', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '来る']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbKuru]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '来る');
      expect(list[0].negative, '来ない');
      expect(list[1].positive, '来ます');
      expect(list[1].negative, '来ません');
      expect(list[2].positive, '来た');
      expect(list[2].negative, '来なかった');
      expect(list[3].positive, '来ました');
      expect(list[3].negative, '来ませんでした');
      expect(list[4].positive, '来て');
      expect(list[4].negative, '来なくて');
      expect(list[5].positive, '来よう');
      expect(list[5].negative, '来まい');
      expect(list[6].positive, '来ましょう');
      expect(list[6].negative, '来ますまい');
      expect(list[7].positive, '来られる');
      expect(list[7].negative, '来られない');
      expect(list[8].positive, '来られます');
      expect(list[8].negative, '来られません');
      expect(list[9].positive, '来られる');
      expect(list[9].negative, '来られない');
      expect(list[10].positive, '来られます');
      expect(list[10].negative, '来られません');
      expect(list[11].positive, '来させる');
      expect(list[11].negative, '来させない');
      expect(list[12].positive, '来させます');
      expect(list[12].negative, '来させません');
      expect(list[13].positive, '来させられる');
      expect(list[13].negative, '来させられない');
      expect(list[14].positive, '来い');
      expect(list[14].negative, '来るな');
      expect(list[15].positive, '来なさい');
      expect(list[15].negative, '来なさるな');
    });

    test('conjugate verbSuru', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '電話']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbSuru]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '電話する');
      expect(list[0].negative, '電話しない');
      expect(list[1].positive, '電話します');
      expect(list[1].negative, '電話しません');
      expect(list[2].positive, '電話した');
      expect(list[2].negative, '電話しなかった');
      expect(list[3].positive, '電話しました');
      expect(list[3].negative, '電話しませんでした');
      expect(list[4].positive, '電話して');
      expect(list[4].negative, '電話しなくて');
      expect(list[5].positive, '電話しよう');
      expect(list[5].negative, '電話するまい');
      expect(list[6].positive, '電話しましょう');
      expect(list[6].negative, '電話ませんまい');
      expect(list[7].positive, '電話できる');
      expect(list[7].negative, '電話できない');
      expect(list[8].positive, '電話できます');
      expect(list[8].negative, '電話できません');
      expect(list[9].positive, '電話される');
      expect(list[9].negative, '電話されない');
      expect(list[10].positive, '電話されます');
      expect(list[10].negative, '電話されません');
      expect(list[11].positive, '電話させる');
      expect(list[11].negative, '電話させない');
      expect(list[12].positive, '電話させます');
      expect(list[12].negative, '電話させません');
      expect(list[13].positive, '電話させられる');
      expect(list[13].negative, '電話させられない');
      expect(list[14].positive, '電話しろ');
      expect(list[14].negative, '電話するな');
      expect(list[15].positive, '電話しなさい');
      expect(list[15].negative, '電話しなさるな');
    });

    test('conjugate verbSuru short', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '噂']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbSuru]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '噂する');
      expect(list[0].negative, '噂しない');
      expect(list[1].positive, '噂します');
      expect(list[1].negative, '噂しません');
      expect(list[2].positive, '噂した');
      expect(list[2].negative, '噂しなかった');
      expect(list[3].positive, '噂しました');
      expect(list[3].negative, '噂しませんでした');
      expect(list[4].positive, '噂して');
      expect(list[4].negative, '噂しなくて');
      expect(list[5].positive, '噂しよう');
      expect(list[5].negative, '噂するまい');
      expect(list[6].positive, '噂しましょう');
      expect(list[6].negative, '噂ませんまい');
      expect(list[7].positive, '噂できる');
      expect(list[7].negative, '噂できない');
      expect(list[8].positive, '噂できます');
      expect(list[8].negative, '噂できません');
      expect(list[9].positive, '噂される');
      expect(list[9].negative, '噂されない');
      expect(list[10].positive, '噂されます');
      expect(list[10].negative, '噂されません');
      expect(list[11].positive, '噂させる');
      expect(list[11].negative, '噂させない');
      expect(list[12].positive, '噂させます');
      expect(list[12].negative, '噂させません');
      expect(list[13].positive, '噂させられる');
      expect(list[13].negative, '噂させられない');
      expect(list[14].positive, '噂しろ');
      expect(list[14].negative, '噂するな');
      expect(list[15].positive, '噂しなさい');
      expect(list[15].negative, '噂しなさるな');
    });

    test('conjugate verbSuruSpecial', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()..kanjiWritings = [VocabKanji()..kanji = '愛する']
        ]
        ..definitions = [
          VocabDefinition()..pos = [PartOfSpeech.verbSuruSpecial]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, '愛する');
      expect(list[0].negative, '愛さない');
      expect(list[1].positive, '愛します');
      expect(list[1].negative, '愛しません');
      expect(list[2].positive, '愛した');
      expect(list[2].negative, '愛さなかった');
      expect(list[3].positive, '愛しました');
      expect(list[3].negative, '愛しませんでした');
      expect(list[4].positive, '愛して');
      expect(list[4].negative, '愛さなくて');
      expect(list[5].positive, '愛しよう');
      expect(list[5].negative, '愛するまい');
      expect(list[6].positive, '愛しましょう');
      expect(list[6].negative, '愛しますまい');
      expect(list[7].positive, '愛しえる');
      expect(list[7].negative, '愛しえない');
      expect(list[8].positive, '愛しえます');
      expect(list[8].negative, '愛しえません');
      expect(list[9].positive, '愛される');
      expect(list[9].negative, '愛されない');
      expect(list[10].positive, '愛されます');
      expect(list[10].negative, '愛されません');
      expect(list[11].positive, '愛させる');
      expect(list[11].negative, '愛させない');
      expect(list[12].positive, '愛させます');
      expect(list[12].negative, '愛させません');
      expect(list[13].positive, '愛させられる');
      expect(list[13].negative, '愛させられない');
      expect(list[14].positive, '愛しろ');
      expect(list[14].negative, '愛するな');
      expect(list[15].positive, '愛しなさい');
      expect(list[15].negative, '愛しなさるな');
    });

    test('conjugate verbSuruIncluded', () {
      Vocab vocab = Vocab()
        ..kanjiReadingPairs = [
          KanjiReadingPair()
            ..kanjiWritings = [VocabKanji()..kanji = '為る']
            ..readings = [VocabReading()..reading = 'する']
        ]
        ..definitions = [
          VocabDefinition()
            ..pos = [PartOfSpeech.verbSuruIncluded]
            ..miscInfo = [MiscellaneousInfo.usuallyKanaAlone]
        ];

      final list = conjugationUtils.getConjugations(vocab);

      expect(list![0].positive, 'する');
      expect(list[0].negative, 'しない');
      expect(list[1].positive, 'します');
      expect(list[1].negative, 'しません');
      expect(list[2].positive, 'した');
      expect(list[2].negative, 'しなかった');
      expect(list[3].positive, 'しました');
      expect(list[3].negative, 'しませんでした');
      expect(list[4].positive, 'して');
      expect(list[4].negative, 'しなくて');
      expect(list[5].positive, 'しよう');
      expect(list[5].negative, 'するまい');
      expect(list[6].positive, 'しましょう');
      expect(list[6].negative, 'しますまい');
      expect(list[7].positive, 'できる');
      expect(list[7].negative, 'できない');
      expect(list[8].positive, 'できます');
      expect(list[8].negative, 'できません');
      expect(list[9].positive, 'される');
      expect(list[9].negative, 'されない');
      expect(list[10].positive, 'されます');
      expect(list[10].negative, 'されません');
      expect(list[11].positive, 'させる');
      expect(list[11].negative, 'させない');
      expect(list[12].positive, 'させます');
      expect(list[12].negative, 'させません');
      expect(list[13].positive, 'させられる');
      expect(list[13].negative, 'させられない');
      expect(list[14].positive, 'しろ');
      expect(list[14].negative, 'するな');
      expect(list[15].positive, 'しなさい');
      expect(list[15].negative, 'しなさるな');
    });
  });
}
