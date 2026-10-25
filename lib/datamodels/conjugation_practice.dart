import 'dart:math';

import 'package:sagase/utils/conjugation_utils.dart';
import 'package:sagase/utils/furigana_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

/// Groups of words that conjugate the same way.
enum ConjugationPracticeWordType {
  godanU('Godan う', '買う, 会う, 使う', false),
  godanKu('Godan く', '書く, 聞く, 歩く', false),
  godanGu('Godan ぐ', '泳ぐ, 急ぐ, 脱ぐ', false),
  godanSu('Godan す', '話す, 貸す, 出す', false),
  godanTsu('Godan つ', '待つ, 持つ, 立つ', false),
  godanNu('Godan ぬ', '死ぬ', false),
  godanBu('Godan ぶ', '遊ぶ, 呼ぶ, 飛ぶ', false),
  godanMu('Godan む', '飲む, 読む, 住む', false),
  godanRu('Godan る', '帰る, 入る, 分かる', false),
  ichidan('Ichidan', '食べる, 見る, 起きる', false),
  suru('する verbs', '勉強する, 料理する', false),
  irregular('Irregular', 'する, 来る, 行く, ある', false),
  adjectiveI('い-adjectives', '高い, 新しい, 楽しい', true),
  adjectiveIi('いい-adjectives', 'いい, かっこいい', true),
  adjectiveNa('な-adjectives', '静か, 元気, 好き', true);

  final String title;
  final String examples;
  final bool isAdjective;

  const ConjugationPracticeWordType(
      this.title, this.examples, this.isAdjective);

  List<ConjugationPracticeWord> get words => _words[this]!;
}

/// The conjugations that can be practiced. [adjectiveExample] is null for
/// conjugations that are not practiced with adjectives.
enum ConjugationPracticeForm {
  polite('Polite', ConjugationForm.nonPast, false, true, '飲みます', '高いです'),
  negative('Negative', ConjugationForm.nonPast, true, false, '飲まない', '高くない'),
  politeNegative('Polite negative', ConjugationForm.nonPast, true, true,
      '飲みません', '高くないです'),
  past('Past', ConjugationForm.past, false, false, '飲んだ', '高かった'),
  pastNegative(
      'Past negative', ConjugationForm.past, true, false, '飲まなかった', '高くなかった'),
  politePast(
      'Polite past', ConjugationForm.past, false, true, '飲みました', '高かったです'),
  politePastNegative('Polite past negative', ConjugationForm.past, true, true,
      '飲みませんでした', '高くなかったです'),
  teForm('Te-form', ConjugationForm.conjunctive, false, false, '飲んで', '高くて'),
  negativeTeForm('Negative te-form', ConjugationForm.conjunctive, true, false,
      '飲まなくて', '高くなくて'),
  potential('Potential', ConjugationForm.potential, false, false, '飲める', null),
  passive('Passive', ConjugationForm.passive, false, false, '飲まれる', null),
  causative('Causative', ConjugationForm.causative, false, false, '飲ませる', null),
  causativePassive('Causative passive', ConjugationForm.causativePassive, false,
      false, '飲ませられる', null),
  volitional(
      'Volitional', ConjugationForm.volitional, false, false, '飲もう', null),
  politeVolitional('Polite volitional', ConjugationForm.volitional, false, true,
      '飲みましょう', null),
  imperative(
      'Imperative', ConjugationForm.imperative, false, false, '飲め', null),
  negativeImperative('Negative imperative', ConjugationForm.imperative, true,
      false, '飲むな', null),
  provisional('Provisional (ば)', ConjugationForm.provisional, false, false,
      '飲めば', '高ければ'),
  conditional('Conditional (たら)', ConjugationForm.conditional, false, false,
      '飲んだら', '高かったら');

  final String title;
  final ConjugationForm form;
  final bool isNegative;
  final bool isFormal;
  final String verbExample;
  final String? adjectiveExample;

  const ConjugationPracticeForm(
    this.title,
    this.form,
    this.isNegative,
    this.isFormal,
    this.verbExample,
    this.adjectiveExample,
  );

  bool appliesTo(ConjugationPracticeWordType type) =>
      !type.isAdjective || adjectiveExample != null;

  String get examples => adjectiveExample == null
      ? verbExample
      : '$verbExample, $adjectiveExample';
}

/// A word to conjugate. [furigana] uses the Anki furigana format.
/// [excludedForms] are conjugations that are grammatical but unnatural for
/// the word and are not practiced.
class ConjugationPracticeWord {
  final String furigana;
  final String meaning;
  final PartOfSpeech pos;
  final Set<ConjugationPracticeForm> excludedForms;

  const ConjugationPracticeWord(
    this.furigana,
    this.meaning,
    this.pos, {
    this.excludedForms = const {},
  });

  String get writing => removeFurigana(furigana);

  String get reading => parseFurigana(furigana)
      .map((pair) => pair.reading ?? pair.writing)
      .join();
}

class ConjugationPracticeQuestion {
  final ConjugationPracticeWord word;
  final ConjugationPracticeWordType type;
  final ConjugationPracticeForm form;

  /// Accepted answers written in kana, the first is the main answer.
  final List<String> readingAnswers;

  /// Accepted answers written the same way as the word, the first is the
  /// main answer.
  final List<String> writingAnswers;

  const ConjugationPracticeQuestion({
    required this.word,
    required this.type,
    required this.form,
    required this.readingAnswers,
    required this.writingAnswers,
  });

  String get readingAnswer => readingAnswers.first;
  String get writingAnswer => writingAnswers.first;

  /// The main answer in the Anki furigana format. The word's furigana is kept
  /// for the start of the word that is unchanged by the conjugation.
  String get answerFurigana {
    final writing = writingAnswer;
    final reading = readingAnswer;
    if (writing == reading) return writing;

    final List<RubyTextPair> pairs = [];
    int length = 0;
    for (final pair in parseFurigana(word.furigana)) {
      if (!writing.startsWith(pair.writing, length)) break;
      pairs.add(pair);
      length += pair.writing.length;
    }

    // The conjugated ending is kana so it is the same in the reading
    final ending = writing.substring(length);
    if (!reading.endsWith(ending)) return '$writing[$reading]';
    final stemWriting = writing.substring(0, length);
    final stemReading = reading.substring(0, reading.length - ending.length);

    if (pairs.map((pair) => pair.reading ?? pair.writing).join() !=
        stemReading) {
      // The reading of the kanji changed, such as 来る becoming 来[こ]ない
      return '$stemWriting[$stemReading]$ending';
    }

    final buffer = StringBuffer();
    for (final pair in pairs) {
      if (pair.reading == null) {
        buffer.write(pair.writing);
      } else {
        // Separate the reading from preceding text it does not apply to
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write('${pair.writing}[${pair.reading}]');
      }
    }
    buffer.write(ending);
    return buffer.toString();
  }

  /// Returns whether [answer] matches any accepted answer.
  bool isCorrect(String answer) {
    answer = answer.trim();
    if (answer.isEmpty) return false;
    return readingAnswers.contains(answer) || writingAnswers.contains(answer);
  }

  /// Creates a question for [word] and [form]. Returns null if the word
  /// cannot be conjugated to [form].
  static ConjugationPracticeQuestion? create(
    ConjugationPracticeWord word,
    ConjugationPracticeWordType type,
    ConjugationPracticeForm form,
  ) {
    if (!form.appliesTo(type) || word.excludedForms.contains(form)) {
      return null;
    }

    final readingAnswers = _conjugateAll(word.reading, word.pos, form);
    final writingAnswers = _conjugateAll(word.writing, word.pos, form);
    if (readingAnswers.isEmpty || writingAnswers.isEmpty) return null;

    return ConjugationPracticeQuestion(
      word: word,
      type: type,
      form: form,
      readingAnswers: readingAnswers,
      writingAnswers: writingAnswers,
    );
  }

  static List<String> _conjugateAll(
    String base,
    PartOfSpeech pos,
    ConjugationPracticeForm form,
  ) {
    const conjugationUtils = ConjugationUtils();
    final List<String> results = [];
    for (int onum = 1; onum <= 9; onum++) {
      final result = conjugationUtils.conjugate(
        base,
        pos,
        form.form,
        form.isNegative,
        form.isFormal,
        onum,
      );
      if (result.isEmpty) break;
      results.add(result);
    }
    return results;
  }

  /// Returns every question for the given word types and forms.
  static List<ConjugationPracticeQuestion> getAll({
    required Set<ConjugationPracticeWordType> types,
    required Set<ConjugationPracticeForm> forms,
  }) {
    final List<ConjugationPracticeQuestion> result = [];
    for (final type in ConjugationPracticeWordType.values) {
      if (!types.contains(type)) continue;
      for (final word in type.words) {
        for (final form in ConjugationPracticeForm.values) {
          if (!forms.contains(form)) continue;
          final question = create(word, type, form);
          if (question != null) result.add(question);
        }
      }
    }
    return result;
  }

  /// Returns up to [count] random questions for the given word types and
  /// forms. The questions are spread as evenly as possible over the selected
  /// word types and forms so each of them is practiced when [count] allows.
  static List<ConjugationPracticeQuestion> getRandom({
    required Set<ConjugationPracticeWordType> types,
    required Set<ConjugationPracticeForm> forms,
    required int count,
    Random? random,
  }) {
    final remaining = getAll(types: types, forms: forms)..shuffle(random);
    if (remaining.length <= count) return remaining;

    final typeUses = {for (final type in types) type: 0};
    final formUses = {for (final form in forms) form: 0};
    final Map<(ConjugationPracticeWordType, ConjugationPracticeForm), int>
        pairUses = {};

    final List<ConjugationPracticeQuestion> result = [];
    while (result.length < count) {
      // Take the question whose word type and form have been used the least,
      // breaking ties with how often the type and form pair has been used.
      // Remaining ties keep the shuffled order.
      late ConjugationPracticeQuestion best;
      int bestUses = -1;
      int bestPairUses = -1;
      for (final question in remaining) {
        final uses = typeUses[question.type]! + formUses[question.form]!;
        final pairs = pairUses[(question.type, question.form)] ?? 0;
        if (bestUses == -1 ||
            uses < bestUses ||
            (uses == bestUses && pairs < bestPairUses)) {
          best = question;
          bestUses = uses;
          bestPairUses = pairs;
        }
      }

      remaining.remove(best);
      result.add(best);
      typeUses[best.type] = typeUses[best.type]! + 1;
      formUses[best.form] = formUses[best.form]! + 1;
      pairUses[(best.type, best.form)] = bestPairUses + 1;
    }

    return result;
  }
}

const _unnaturalForms = {
  ConjugationPracticeForm.potential,
  ConjugationPracticeForm.passive,
  ConjugationPracticeForm.causativePassive,
  ConjugationPracticeForm.volitional,
  ConjugationPracticeForm.politeVolitional,
  ConjugationPracticeForm.imperative,
  ConjugationPracticeForm.negativeImperative,
};

const _words = {
  ConjugationPracticeWordType.godanU: [
    ConjugationPracticeWord('買[か]う', 'to buy', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('会[あ]う', 'to meet', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('使[つか]う', 'to use', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('言[い]う', 'to say', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('歌[うた]う', 'to sing', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('洗[あら]う', 'to wash', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('笑[わら]う', 'to laugh', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('習[なら]う', 'to learn', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('思[おも]う', 'to think', PartOfSpeech.verbGodanU),
    ConjugationPracticeWord('手伝[てつだ]う', 'to help', PartOfSpeech.verbGodanU),
  ],
  ConjugationPracticeWordType.godanKu: [
    ConjugationPracticeWord('書[か]く', 'to write', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('聞[き]く', 'to listen', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('歩[ある]く', 'to walk', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('働[はたら]く', 'to work', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('置[お]く', 'to put', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('泣[な]く', 'to cry', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('着[つ]く', 'to arrive', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('引[ひ]く', 'to pull', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('開[あ]く', 'to open', PartOfSpeech.verbGodanK),
    ConjugationPracticeWord('磨[みが]く', 'to polish', PartOfSpeech.verbGodanK),
  ],
  ConjugationPracticeWordType.godanGu: [
    ConjugationPracticeWord('泳[およ]ぐ', 'to swim', PartOfSpeech.verbGodanG),
    ConjugationPracticeWord('急[いそ]ぐ', 'to hurry', PartOfSpeech.verbGodanG),
    ConjugationPracticeWord(
        '脱[ぬ]ぐ', 'to take off (clothes)', PartOfSpeech.verbGodanG),
    ConjugationPracticeWord('騒[さわ]ぐ', 'to make noise', PartOfSpeech.verbGodanG),
    ConjugationPracticeWord('稼[かせ]ぐ', 'to earn', PartOfSpeech.verbGodanG),
    ConjugationPracticeWord('防[ふせ]ぐ', 'to prevent', PartOfSpeech.verbGodanG),
    ConjugationPracticeWord('注[そそ]ぐ', 'to pour', PartOfSpeech.verbGodanG),
  ],
  ConjugationPracticeWordType.godanSu: [
    ConjugationPracticeWord('話[はな]す', 'to speak', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord('貸[か]す', 'to lend', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord(
        '返[かえ]す', 'to return (something)', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord('出[だ]す', 'to take out', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord('消[け]す', 'to erase', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord('押[お]す', 'to push', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord('探[さが]す', 'to look for', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord('渡[わた]す', 'to hand over', PartOfSpeech.verbGodanS),
    ConjugationPracticeWord(
        '思[おも]い 出[だ]す', 'to remember', PartOfSpeech.verbGodanS),
  ],
  ConjugationPracticeWordType.godanTsu: [
    ConjugationPracticeWord('待[ま]つ', 'to wait', PartOfSpeech.verbGodanT),
    ConjugationPracticeWord('持[も]つ', 'to hold', PartOfSpeech.verbGodanT),
    ConjugationPracticeWord('立[た]つ', 'to stand', PartOfSpeech.verbGodanT),
    ConjugationPracticeWord('勝[か]つ', 'to win', PartOfSpeech.verbGodanT),
    ConjugationPracticeWord('打[う]つ', 'to hit', PartOfSpeech.verbGodanT),
    ConjugationPracticeWord('育[そだ]つ', 'to grow up', PartOfSpeech.verbGodanT),
    ConjugationPracticeWord(
        '役立[やくだ]つ', 'to be useful', PartOfSpeech.verbGodanT),
  ],
  ConjugationPracticeWordType.godanNu: [
    ConjugationPracticeWord('死[し]ぬ', 'to die', PartOfSpeech.verbGodanN),
  ],
  ConjugationPracticeWordType.godanBu: [
    ConjugationPracticeWord('遊[あそ]ぶ', 'to play', PartOfSpeech.verbGodanB),
    ConjugationPracticeWord('呼[よ]ぶ', 'to call', PartOfSpeech.verbGodanB),
    ConjugationPracticeWord('飛[と]ぶ', 'to fly', PartOfSpeech.verbGodanB),
    ConjugationPracticeWord('選[えら]ぶ', 'to choose', PartOfSpeech.verbGodanB),
    ConjugationPracticeWord('学[まな]ぶ', 'to study', PartOfSpeech.verbGodanB),
    ConjugationPracticeWord('並[なら]ぶ', 'to line up', PartOfSpeech.verbGodanB),
    ConjugationPracticeWord('運[はこ]ぶ', 'to carry', PartOfSpeech.verbGodanB),
  ],
  ConjugationPracticeWordType.godanMu: [
    ConjugationPracticeWord('飲[の]む', 'to drink', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('読[よ]む', 'to read', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('住[す]む', 'to live', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('休[やす]む', 'to rest', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('頼[たの]む', 'to ask for', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('進[すす]む', 'to advance', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('楽[たの]しむ', 'to enjoy', PartOfSpeech.verbGodanM),
    ConjugationPracticeWord('噛[か]む', 'to bite', PartOfSpeech.verbGodanM),
  ],
  ConjugationPracticeWordType.godanRu: [
    ConjugationPracticeWord('帰[かえ]る', 'to go home', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('入[はい]る', 'to enter', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('走[はし]る', 'to run', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('知[し]る', 'to know', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('切[き]る', 'to cut', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('要[い]る', 'to need', PartOfSpeech.verbGodanR,
        excludedForms: _unnaturalForms),
    ConjugationPracticeWord('分[わ]かる', 'to understand', PartOfSpeech.verbGodanR,
        excludedForms: _unnaturalForms),
    ConjugationPracticeWord('作[つく]る', 'to make', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('乗[の]る', 'to ride', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('取[と]る', 'to take', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('終[お]わる', 'to end', PartOfSpeech.verbGodanR),
    ConjugationPracticeWord('座[すわ]る', 'to sit', PartOfSpeech.verbGodanR),
  ],
  ConjugationPracticeWordType.ichidan: [
    ConjugationPracticeWord('食[た]べる', 'to eat', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('見[み]る', 'to see', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('寝[ね]る', 'to sleep', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('起[お]きる', 'to wake up', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('教[おし]える', 'to teach', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('着[き]る', 'to wear', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('出[で]る', 'to leave', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('開[あ]ける', 'to open', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('閉[し]める', 'to close', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('忘[わす]れる', 'to forget', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('借[か]りる', 'to borrow', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('覚[おぼ]える', 'to memorize', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('決[き]める', 'to decide', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('始[はじ]める', 'to begin', PartOfSpeech.verbIchidan),
    ConjugationPracticeWord('浴[あ]びる', 'to bathe', PartOfSpeech.verbIchidan),
  ],
  ConjugationPracticeWordType.suru: [
    ConjugationPracticeWord(
        '勉強[べんきょう]する', 'to study', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '料理[りょうり]する', 'to cook', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '運転[うんてん]する', 'to drive', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '掃除[そうじ]する', 'to clean', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '電話[でんわ]する', 'to phone', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '結婚[けっこん]する', 'to marry', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '練習[れんしゅう]する', 'to practice', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord(
        '散歩[さんぽ]する', 'to take a walk', PartOfSpeech.verbSuruIncluded),
  ],
  ConjugationPracticeWordType.irregular: [
    ConjugationPracticeWord('する', 'to do', PartOfSpeech.verbSuruIncluded),
    ConjugationPracticeWord('来[く]る', 'to come', PartOfSpeech.verbKuru),
    ConjugationPracticeWord('行[い]く', 'to go', PartOfSpeech.verbGodanKS),
    ConjugationPracticeWord('ある', 'to exist (things)', PartOfSpeech.verbGodanRI,
        excludedForms: _unnaturalForms),
  ],
  ConjugationPracticeWordType.adjectiveI: [
    ConjugationPracticeWord(
        '高[たか]い', 'expensive, tall', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('安[やす]い', 'cheap', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('大[おお]きい', 'big', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('小[ちい]さい', 'small', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('新[あたら]しい', 'new', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('古[ふる]い', 'old', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('暑[あつ]い', 'hot', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('寒[さむ]い', 'cold', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('楽[たの]しい', 'fun', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('難[むずか]しい', 'difficult', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('忙[いそが]しい', 'busy', PartOfSpeech.adjectiveI),
    ConjugationPracticeWord('おいしい', 'delicious', PartOfSpeech.adjectiveI),
  ],
  ConjugationPracticeWordType.adjectiveIi: [
    ConjugationPracticeWord('いい', 'good', PartOfSpeech.adjectiveIx),
    ConjugationPracticeWord('かっこいい', 'cool', PartOfSpeech.adjectiveIx),
  ],
  ConjugationPracticeWordType.adjectiveNa: [
    ConjugationPracticeWord('静[しず]か', 'quiet', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord(
        '綺麗[きれい]', 'pretty, clean', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord(
        '元気[げんき]', 'healthy, energetic', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('有名[ゆうめい]', 'famous', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('便利[べんり]', 'convenient', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('好[す]き', 'liked', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('簡単[かんたん]', 'easy', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('大切[たいせつ]', 'important', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('親切[しんせつ]', 'kind', PartOfSpeech.adjectiveNa),
    ConjugationPracticeWord('暇[ひま]', 'free (time)', PartOfSpeech.adjectiveNa),
  ],
};
