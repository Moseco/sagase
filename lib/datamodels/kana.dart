enum KanaScript {
  hiragana,
  katakana,
}

enum KanaType {
  basic,
  voiced,
  semiVoiced,
  combination,
}

class Kana {
  final String kana;
  final String romaji;
  final KanaScript script;
  final KanaType type;

  const Kana({
    required this.kana,
    required this.romaji,
    required this.script,
    required this.type,
  });

  static List<Kana> getKana({
    required Set<KanaScript> scripts,
    required Set<KanaType> types,
  }) {
    final List<Kana> result = [];
    for (final script in KanaScript.values) {
      if (!scripts.contains(script)) continue;
      for (final type in KanaType.values) {
        if (!types.contains(type)) continue;
        for (final entry in _getHiragana(type).entries) {
          result.add(
            Kana(
              kana: script == KanaScript.hiragana
                  ? entry.key
                  : _hiraganaToKatakana(entry.key),
              romaji: entry.value,
              script: script,
              type: type,
            ),
          );
        }
      }
    }
    return result;
  }

  static Map<String, String> _getHiragana(KanaType type) {
    return switch (type) {
      KanaType.basic => _basicHiragana,
      KanaType.voiced => _voicedHiragana,
      KanaType.semiVoiced => _semiVoicedHiragana,
      KanaType.combination => _combinationHiragana,
    };
  }

  // Katakana are in the same order as hiragana and offset by 0x60 in unicode
  static String _hiraganaToKatakana(String hiragana) {
    return String.fromCharCodes(hiragana.codeUnits.map((e) => e + 0x60));
  }
}

const Map<String, String> _basicHiragana = {
  // base
  'あ': 'a', 'い': 'i', 'う': 'u', 'え': 'e', 'お': 'o',
  // k
  'か': 'ka', 'き': 'ki', 'く': 'ku', 'け': 'ke', 'こ': 'ko',
  // s
  'さ': 'sa', 'し': 'shi', 'す': 'su', 'せ': 'se', 'そ': 'so',
  // t
  'た': 'ta', 'ち': 'chi', 'つ': 'tsu', 'て': 'te', 'と': 'to',
  // n
  'な': 'na', 'に': 'ni', 'ぬ': 'nu', 'ね': 'ne', 'の': 'no',
  // h
  'は': 'ha', 'ひ': 'hi', 'ふ': 'fu', 'へ': 'he', 'ほ': 'ho',
  // m
  'ま': 'ma', 'み': 'mi', 'む': 'mu', 'め': 'me', 'も': 'mo',
  // y
  'や': 'ya', 'ゆ': 'yu', 'よ': 'yo',
  // r
  'ら': 'ra', 'り': 'ri', 'る': 'ru', 'れ': 're', 'ろ': 'ro',
  // w
  'わ': 'wa', 'を': 'o',
  // n
  'ん': 'n',
};

const Map<String, String> _voicedHiragana = {
  // g
  'が': 'ga', 'ぎ': 'gi', 'ぐ': 'gu', 'げ': 'ge', 'ご': 'go',
  // z
  'ざ': 'za', 'じ': 'ji', 'ず': 'zu', 'ぜ': 'ze', 'ぞ': 'zo',
  // d
  'だ': 'da', 'ぢ': 'ji', 'づ': 'zu', 'で': 'de', 'ど': 'do',
  // b
  'ば': 'ba', 'び': 'bi', 'ぶ': 'bu', 'べ': 'be', 'ぼ': 'bo',
};

const Map<String, String> _semiVoicedHiragana = {
  // p
  'ぱ': 'pa', 'ぴ': 'pi', 'ぷ': 'pu', 'ぺ': 'pe', 'ぽ': 'po',
};

const Map<String, String> _combinationHiragana = {
  // k
  'きゃ': 'kya', 'きゅ': 'kyu', 'きょ': 'kyo',
  // s
  'しゃ': 'sha', 'しゅ': 'shu', 'しょ': 'sho',
  // t
  'ちゃ': 'cha', 'ちゅ': 'chu', 'ちょ': 'cho',
  // n
  'にゃ': 'nya', 'にゅ': 'nyu', 'にょ': 'nyo',
  // h
  'ひゃ': 'hya', 'ひゅ': 'hyu', 'ひょ': 'hyo',
  // m
  'みゃ': 'mya', 'みゅ': 'myu', 'みょ': 'myo',
  // r
  'りゃ': 'rya', 'りゅ': 'ryu', 'りょ': 'ryo',
  // g
  'ぎゃ': 'gya', 'ぎゅ': 'gyu', 'ぎょ': 'gyo',
  // z
  'じゃ': 'ja', 'じゅ': 'ju', 'じょ': 'jo',
  // b
  'びゃ': 'bya', 'びゅ': 'byu', 'びょ': 'byo',
  // p
  'ぴゃ': 'pya', 'ぴゅ': 'pyu', 'ぴょ': 'pyo',
};
