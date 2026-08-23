import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/utils/furigana_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

void expectPairs(List<RubyTextPair> actual, List<(String, String?)> expected) {
  expect(actual.length, expected.length);
  for (int i = 0; i < actual.length; i++) {
    expect(actual[i].writing, expected[i].$1);
    expect(actual[i].reading, expected[i].$2);
  }
}

void main() {
  group('parseFurigana', () {
    test('reading at start of text', () {
      expectPairs(
        parseFurigana('例[たと]えば'),
        [('例', 'たと'), ('えば', null)],
      );
    });

    test('reading after preceding text', () {
      expectPairs(
        parseFurigana('と 言[い]ってもいい'),
        [('と', null), ('言', 'い'), ('ってもいい', null)],
      );
    });

    test('multiple kanji at start', () {
      expectPairs(
        parseFurigana('日本語[にほんご]を 勉強[べんきょう]する'),
        [
          ('日本語', 'にほんご'),
          ('を', null),
          ('勉強', 'べんきょう'),
          ('する', null),
        ],
      );
    });

    test('no readings', () {
      expectPairs(parseFurigana('たべたい'), [('たべたい', null)]);
    });

    test('empty text', () {
      expectPairs(parseFurigana(''), []);
    });

    test('consecutive readings', () {
      expectPairs(
        parseFurigana('食[た]べ 物[もの]'),
        [('食', 'た'), ('べ', null), ('物', 'もの')],
      );
    });

    test('unclosed bracket', () {
      expectPairs(parseFurigana('例[たと'), [('例[たと', null)]);
    });

    test('trailing space', () {
      expectPairs(
        parseFurigana('と 言[い]う '),
        [('と', null), ('言', 'い'), ('う', null)],
      );
    });
  });

  group('removeFurigana', () {
    test('with readings', () {
      expect(removeFurigana('が 嫌[きら]い'), 'が嫌い');
    });

    test('without readings', () {
      expect(removeFurigana('たべたい'), 'たべたい');
    });
  });
}
