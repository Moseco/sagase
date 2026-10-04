import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/kana.dart';

void main() {
  group('KanaTest', () {
    test('getKana with single script and type', () {
      final kana = Kana.getKana(
        scripts: {KanaScript.hiragana},
        types: {KanaType.semiVoiced},
      );

      expect(kana.length, 5);
      expect(kana.map((e) => e.kana), ['ぱ', 'ぴ', 'ぷ', 'ぺ', 'ぽ']);
      expect(kana.map((e) => e.romaji), ['pa', 'pi', 'pu', 'pe', 'po']);
      for (final current in kana) {
        expect(current.script, KanaScript.hiragana);
        expect(current.type, KanaType.semiVoiced);
      }
    });

    test('getKana converts to katakana', () {
      final kana = Kana.getKana(
        scripts: {KanaScript.katakana},
        types: {KanaType.semiVoiced, KanaType.combination},
      );

      expect(kana.length, 38);
      expect(
        kana.take(5).map((e) => e.kana),
        ['パ', 'ピ', 'プ', 'ペ', 'ポ'],
      );
      expect(kana[5].kana, 'キャ');
      expect(kana[5].romaji, 'kya');
      expect(kana.last.kana, 'ピョ');
      expect(kana.last.romaji, 'pyo');
      for (final current in kana) {
        expect(current.script, KanaScript.katakana);
      }
    });

    test('getKana amount for each type', () {
      for (final script in KanaScript.values) {
        expect(
          Kana.getKana(scripts: {script}, types: {KanaType.basic}).length,
          46,
        );
        expect(
          Kana.getKana(scripts: {script}, types: {KanaType.voiced}).length,
          20,
        );
        expect(
          Kana.getKana(scripts: {script}, types: {KanaType.semiVoiced}).length,
          5,
        );
        expect(
          Kana.getKana(scripts: {script}, types: {KanaType.combination}).length,
          33,
        );
      }
    });

    test('getKana with everything has no duplicates', () {
      final kana = Kana.getKana(
        scripts: KanaScript.values.toSet(),
        types: KanaType.values.toSet(),
      );

      expect(kana.length, 208);
      expect(kana.map((e) => e.kana).toSet().length, 208);
    });

    test('getKana with nothing selected', () {
      expect(
        Kana.getKana(scripts: {}, types: KanaType.values.toSet()),
        isEmpty,
      );
      expect(
        Kana.getKana(scripts: KanaScript.values.toSet(), types: {}),
        isEmpty,
      );
    });
  });
}
