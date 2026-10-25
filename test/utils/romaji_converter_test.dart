import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/utils/romaji_converter.dart';

void main() {
  group('romajiToHiragana', () {
    test('Basic syllables', () {
      expect(romajiToHiragana('aiueo'), 'あいうえお');
      expect(romajiToHiragana('nomimasu'), 'のみます');
      expect(romajiToHiragana('tabemasendeshita'), 'たべませんでした');
      expect(romajiToHiragana('shichitsufuji'), 'しちつふじ');
      expect(romajiToHiragana('sitihuzi'), 'しちふじ');
      expect(romajiToHiragana('kyoushuuchou'), 'きょうしゅうちょう');
      expect(romajiToHiragana('benkyou'), 'べんきょう');
      expect(romajiToHiragana('wo'), 'を');
      expect(romajiToHiragana('ra-men'), 'らーめn');
    });

    test('Uppercase input', () {
      expect(romajiToHiragana('Nomu'), 'のむ');
      expect(romajiToHiragana('TABERU'), 'たべる');
    });

    test('Small tsu', () {
      expect(romajiToHiragana('itta'), 'いった');
      expect(romajiToHiragana('matte'), 'まって');
      expect(romajiToHiragana('kekka'), 'けっか');
      expect(romajiToHiragana('zasshi'), 'ざっし');
      expect(romajiToHiragana('macchi'), 'まっち');
      expect(romajiToHiragana('matchi'), 'まっち');
      expect(romajiToHiragana('xtu'), 'っ');
      expect(romajiToHiragana('ltsu'), 'っ');
    });

    test('Small kana', () {
      expect(romajiToHiragana('xa'), 'ぁ');
      expect(romajiToHiragana('lyo'), 'ょ');
      expect(romajiToHiragana('fairu'), 'ふぁいる');
      expect(romajiToHiragana('thi'), 'てぃ');
    });

    test('N handling', () {
      expect(romajiToHiragana('shinde'), 'しんで');
      expect(romajiToHiragana('kanji'), 'かんじ');
      expect(romajiToHiragana('konna'), 'こんな');
      expect(romajiToHiragana('minna'), 'みんな');
      expect(romajiToHiragana('konnichiha'), 'こんにちは');
      expect(romajiToHiragana('konnnichiha'), 'こんにちは');
      expect(romajiToHiragana('kinnyou'), 'きんにょう');
      expect(romajiToHiragana("gen'an"), 'げんあn');
      expect(romajiToHiragana("gen'an", finalize: true), 'げんあん');
      expect(romajiToHiragana('xn'), 'ん');
      expect(romajiToHiragana('nnk'), 'んk');
      expect(romajiToHiragana('nyu'), 'にゅ');
    });

    test('Trailing romaji is kept while typing', () {
      expect(romajiToHiragana('n'), 'n');
      expect(romajiToHiragana('tabemasen'), 'たべませn');
      expect(romajiToHiragana('tabemasenn'), 'たべませnn');
      expect(romajiToHiragana('ky'), 'ky');
      expect(romajiToHiragana('nomimas'), 'のみまs');
      expect(romajiToHiragana('ts'), 'ts');
      expect(romajiToHiragana('ny'), 'ny');
      expect(romajiToHiragana('xt'), 'xt');
      expect(romajiToHiragana('k'), 'k');
    });

    test('Finalize converts trailing n', () {
      expect(romajiToHiragana('n', finalize: true), 'ん');
      expect(romajiToHiragana('tabemasen', finalize: true), 'たべません');
      expect(romajiToHiragana('tabemasenn', finalize: true), 'たべません');
      expect(romajiToHiragana('ky', finalize: true), 'ky');
    });

    test('Incremental typing', () {
      // Simulate typing one character at a time into already converted text
      String type(String keys) {
        String text = '';
        for (final key in keys.split('')) {
          text = romajiToHiragana(text + key);
        }
        return romajiToHiragana(text, finalize: true);
      }

      expect(type('nomimasen'), 'のみません');
      expect(type('tabesasenakatta'), 'たべさせなかった');
      expect(type('konna'), 'こんな');
      expect(type('shinkansen'), 'しんかんせん');
      expect(type('kyakka'), 'きゃっか');
      expect(type('benkyoushimashou'), 'べんきょうしましょう');
      expect(type('itte'), 'いって');
    });

    test('Non-romaji characters are kept', () {
      expect(romajiToHiragana('のm'), 'のm');
      expect(romajiToHiragana('のma'), 'のま');
      expect(romajiToHiragana('飲mu'), '飲む');
      expect(romajiToHiragana('a b'), 'あ b');
      expect(romajiToHiragana('qa'), 'qあ');
      expect(romajiToHiragana('1'), '1');
      expect(romajiToHiragana(''), '');
    });
  });
}
