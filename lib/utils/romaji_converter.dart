/// Converts the romaji in [input] to hiragana the way a Japanese input method
/// does while the user is typing. Romaji that could still become kana (such as
/// a trailing 'k' or 'ky') is left as is so it can be completed by the next
/// keystroke. Characters that are not romaji (kana, kanji, spaces, etc.) are
/// left unchanged.
///
/// If [finalize] is true, a trailing 'n' or "nn" is converted to ん. This
/// should be used when the user submits their input.
///
/// Rules for ん:
/// * 'n' followed by a consonant other than 'n' or 'y' becomes ん
/// * "n'" and "xn" become ん
/// * "nn" becomes ん, but when followed by a vowel or 'y' only the first 'n'
///   becomes ん so that "konna" and "minna" give こんな and みんな
/// * A trailing 'n' or "nn" is kept as romaji until [finalize] is used
String romajiToHiragana(String input, {bool finalize = false}) {
  final text = input.toLowerCase();
  final buffer = StringBuffer();

  int i = 0;
  while (i < text.length) {
    final current = text[i];
    final next = i + 1 < text.length ? text[i + 1] : null;

    if (current == 'n') {
      if (next == null) {
        buffer.write(finalize ? 'ん' : 'n');
        i++;
        continue;
      }
      if (next == "'") {
        buffer.write('ん');
        i += 2;
        continue;
      }
      if (next == 'n') {
        final afterNext = i + 2 < text.length ? text[i + 2] : null;
        if (afterNext == null) {
          buffer.write(finalize ? 'ん' : 'nn');
          i += 2;
        } else if (_isVowel(afterNext) || afterNext == 'y') {
          // The second n starts the next syllable
          buffer.write('ん');
          i++;
        } else {
          buffer.write('ん');
          i += 2;
        }
        continue;
      }
      if (!_isVowel(next) && next != 'y') {
        buffer.write('ん');
        i++;
        continue;
      }
    }

    // Try to match the longest romaji sequence
    String? match;
    int matchLength = 0;
    for (int length = _maxRomajiLength; length > 0; length--) {
      if (i + length > text.length) continue;
      final kana = _romajiHiraganaMap[text.substring(i, i + length)];
      if (kana != null) {
        match = kana;
        matchLength = length;
        break;
      }
    }
    if (match != null) {
      buffer.write(match);
      i += matchLength;
      continue;
    }

    // Double consonants become a small tsu
    if (next != null &&
        _isConsonant(current) &&
        (next == current || (current == 't' && next == 'c'))) {
      buffer.write('っ');
      i++;
      continue;
    }

    // Keep incomplete romaji at the end of the input
    final remaining = text.substring(i);
    if (_romajiPrefixes.contains(remaining)) {
      buffer.write(remaining);
      break;
    }

    // Not romaji that can be converted, keep the original character
    buffer.write(input[i]);
    i++;
  }

  return buffer.toString();
}

bool _isVowel(String char) => 'aiueo'.contains(char);

bool _isConsonant(String char) =>
    char.length == 1 && 'bcdfghjklmpqrstvwxyz'.contains(char);

final int _maxRomajiLength =
    _romajiHiraganaMap.keys.fold(0, (a, b) => a > b.length ? a : b.length);

final Set<String> _romajiPrefixes = {
  for (final key in _romajiHiraganaMap.keys)
    for (int i = 1; i < key.length; i++) key.substring(0, i),
};

const Map<String, String> _romajiHiraganaMap = {
  'a': 'あ', 'i': 'い', 'u': 'う', 'e': 'え', 'o': 'お', //
  'ka': 'か', 'ki': 'き', 'ku': 'く', 'ke': 'け', 'ko': 'こ',
  'kya': 'きゃ', 'kyi': 'きぃ', 'kyu': 'きゅ', 'kye': 'きぇ', 'kyo': 'きょ',
  'ga': 'が', 'gi': 'ぎ', 'gu': 'ぐ', 'ge': 'げ', 'go': 'ご',
  'gya': 'ぎゃ', 'gyi': 'ぎぃ', 'gyu': 'ぎゅ', 'gye': 'ぎぇ', 'gyo': 'ぎょ',
  'sa': 'さ', 'si': 'し', 'shi': 'し', 'su': 'す', 'se': 'せ', 'so': 'そ',
  'sha': 'しゃ', 'shu': 'しゅ', 'she': 'しぇ', 'sho': 'しょ',
  'sya': 'しゃ', 'syi': 'しぃ', 'syu': 'しゅ', 'sye': 'しぇ', 'syo': 'しょ',
  'za': 'ざ', 'zi': 'じ', 'zu': 'ず', 'ze': 'ぜ', 'zo': 'ぞ',
  'ji': 'じ', 'ja': 'じゃ', 'ju': 'じゅ', 'je': 'じぇ', 'jo': 'じょ',
  'jya': 'じゃ', 'jyi': 'じぃ', 'jyu': 'じゅ', 'jye': 'じぇ', 'jyo': 'じょ',
  'zya': 'じゃ', 'zyi': 'じぃ', 'zyu': 'じゅ', 'zye': 'じぇ', 'zyo': 'じょ',
  'ta': 'た', 'ti': 'ち', 'chi': 'ち', 'tu': 'つ', 'tsu': 'つ', 'te': 'て',
  'to': 'と',
  'cha': 'ちゃ', 'chu': 'ちゅ', 'che': 'ちぇ', 'cho': 'ちょ',
  'tya': 'ちゃ', 'tyi': 'ちぃ', 'tyu': 'ちゅ', 'tye': 'ちぇ', 'tyo': 'ちょ',
  'cya': 'ちゃ', 'cyi': 'ちぃ', 'cyu': 'ちゅ', 'cye': 'ちぇ', 'cyo': 'ちょ',
  'tsa': 'つぁ', 'tsi': 'つぃ', 'tse': 'つぇ', 'tso': 'つぉ',
  'tha': 'てゃ', 'thi': 'てぃ', 'thu': 'てゅ', 'the': 'てぇ', 'tho': 'てょ',
  'twu': 'とぅ',
  'da': 'だ', 'di': 'ぢ', 'du': 'づ', 'de': 'で', 'do': 'ど',
  'dya': 'ぢゃ', 'dyi': 'ぢぃ', 'dyu': 'ぢゅ', 'dye': 'ぢぇ', 'dyo': 'ぢょ',
  'dha': 'でゃ', 'dhi': 'でぃ', 'dhu': 'でゅ', 'dhe': 'でぇ', 'dho': 'でょ',
  'dwu': 'どぅ',
  'na': 'な', 'ni': 'に', 'nu': 'ぬ', 'ne': 'ね', 'no': 'の',
  'nya': 'にゃ', 'nyi': 'にぃ', 'nyu': 'にゅ', 'nye': 'にぇ', 'nyo': 'にょ',
  'ha': 'は', 'hi': 'ひ', 'hu': 'ふ', 'fu': 'ふ', 'he': 'へ', 'ho': 'ほ',
  'hya': 'ひゃ', 'hyi': 'ひぃ', 'hyu': 'ひゅ', 'hye': 'ひぇ', 'hyo': 'ひょ',
  'fa': 'ふぁ', 'fi': 'ふぃ', 'fe': 'ふぇ', 'fo': 'ふぉ',
  'fya': 'ふゃ', 'fyu': 'ふゅ', 'fyo': 'ふょ',
  'ba': 'ば', 'bi': 'び', 'bu': 'ぶ', 'be': 'べ', 'bo': 'ぼ',
  'bya': 'びゃ', 'byi': 'びぃ', 'byu': 'びゅ', 'bye': 'びぇ', 'byo': 'びょ',
  'pa': 'ぱ', 'pi': 'ぴ', 'pu': 'ぷ', 'pe': 'ぺ', 'po': 'ぽ',
  'pya': 'ぴゃ', 'pyi': 'ぴぃ', 'pyu': 'ぴゅ', 'pye': 'ぴぇ', 'pyo': 'ぴょ',
  'ma': 'ま', 'mi': 'み', 'mu': 'む', 'me': 'め', 'mo': 'も',
  'mya': 'みゃ', 'myi': 'みぃ', 'myu': 'みゅ', 'mye': 'みぇ', 'myo': 'みょ',
  'ya': 'や', 'yu': 'ゆ', 'ye': 'いぇ', 'yo': 'よ',
  'ra': 'ら', 'ri': 'り', 'ru': 'る', 're': 'れ', 'ro': 'ろ',
  'rya': 'りゃ', 'ryi': 'りぃ', 'ryu': 'りゅ', 'rye': 'りぇ', 'ryo': 'りょ',
  'wa': 'わ', 'wi': 'うぃ', 'we': 'うぇ', 'wo': 'を',
  'va': 'ゔぁ', 'vi': 'ゔぃ', 'vu': 'ゔ', 've': 'ゔぇ', 'vo': 'ゔぉ',
  'ca': 'か', 'ci': 'し', 'cu': 'く', 'ce': 'せ', 'co': 'こ',
  'xa': 'ぁ', 'xi': 'ぃ', 'xu': 'ぅ', 'xe': 'ぇ', 'xo': 'ぉ',
  'la': 'ぁ', 'li': 'ぃ', 'lu': 'ぅ', 'le': 'ぇ', 'lo': 'ぉ',
  'xya': 'ゃ', 'xyu': 'ゅ', 'xyo': 'ょ',
  'lya': 'ゃ', 'lyu': 'ゅ', 'lyo': 'ょ',
  'xtu': 'っ', 'xtsu': 'っ', 'ltu': 'っ', 'ltsu': 'っ',
  'xwa': 'ゎ', 'lwa': 'ゎ',
  'xn': 'ん',
  '-': 'ー',
};
