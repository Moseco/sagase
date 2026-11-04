import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:sagase/utils/furigana_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

void main() {
  group('ConjugationPracticeTest', () {
    ConjugationPracticeQuestion question(
      String writing,
      ConjugationPracticeForm form,
    ) {
      for (final type in ConjugationPracticeWordType.values) {
        for (final word in type.words) {
          if (word.writing == writing) {
            return ConjugationPracticeQuestion.create(word, type, form)!;
          }
        }
      }
      throw ArgumentError(writing);
    }

    test('Every word type has words', () {
      for (final type in ConjugationPracticeWordType.values) {
        expect(type.words, isNotEmpty, reason: type.name);
      }
    });

    test('Every word can be conjugated to every applicable form', () {
      for (final type in ConjugationPracticeWordType.values) {
        for (final word in type.words) {
          for (final form in ConjugationPracticeForm.values) {
            final result = ConjugationPracticeQuestion.create(word, type, form);
            if (!form.appliesTo(type) || word.excludedForms.contains(form)) {
              expect(result, null);
              continue;
            }
            expect(result, isNotNull, reason: '${word.writing} ${form.name}');
            expect(result!.readingAnswers, isNotEmpty);
            expect(
              result.readingAnswers.length,
              result.writingAnswers.length,
            );
            // Readings are kana only
            expect(
              RegExp(r'^[぀-ゟ]+$').hasMatch(result.readingAnswer),
              true,
              reason: result.readingAnswer,
            );
          }
        }
      }
    });

    test('Word writing and reading', () {
      const word = ConjugationPracticeWord(
        '思[おも]い 出[だ]す',
        'to remember',
        PartOfSpeech.verbGodanS,
      );
      expect(word.writing, '思い出す');
      expect(word.reading, 'おもいだす');
    });

    test('Conjugations', () {
      final past = question('飲む', ConjugationPracticeForm.past);
      expect(past.writingAnswer, '飲んだ');
      expect(past.readingAnswer, 'のんだ');

      expect(question('帰る', ConjugationPracticeForm.negative).readingAnswer,
          'かえらない');
      expect(
          question('食べる', ConjugationPracticeForm.politePastNegative)
              .writingAnswer,
          '食べませんでした');
      expect(
          question('行く', ConjugationPracticeForm.teForm).writingAnswer, '行って');
      expect(
          question('書く', ConjugationPracticeForm.teForm).writingAnswer, '書いて');
      expect(question('勉強する', ConjugationPracticeForm.potential).writingAnswer,
          '勉強できる');
      expect(
          question('ある', ConjugationPracticeForm.negative).writingAnswer, 'ない');
      expect(
          question('いい', ConjugationPracticeForm.past).writingAnswer, 'よかった');
      expect(question('高い', ConjugationPracticeForm.provisional).writingAnswer,
          '高ければ');
      expect(
          question('静か', ConjugationPracticeForm.polite).writingAnswer, '静かです');
      expect(
          question('静か', ConjugationPracticeForm.teForm).writingAnswer, '静かで');
      expect(question('静か', ConjugationPracticeForm.conditional).writingAnswer,
          '静かだったら');
    });

    test('来る keeps kanji', () {
      final negative = question('来る', ConjugationPracticeForm.negative);
      expect(negative.writingAnswer, '来ない');
      expect(negative.readingAnswer, 'こない');

      final polite = question('来る', ConjugationPracticeForm.polite);
      expect(polite.writingAnswer, '来ます');
      expect(polite.readingAnswer, 'きます');
    });

    test('answerFurigana', () {
      expect(question('飲む', ConjugationPracticeForm.past).answerFurigana,
          '飲[の]んだ');
      expect(question('楽しむ', ConjugationPracticeForm.polite).answerFurigana,
          '楽[たの]しみます');
      expect(question('行く', ConjugationPracticeForm.teForm).answerFurigana,
          '行[い]って');
      expect(question('来る', ConjugationPracticeForm.negative).answerFurigana,
          '来[こ]ない');
      expect(question('来る', ConjugationPracticeForm.polite).answerFurigana,
          '来[き]ます');
      expect(question('思い出す', ConjugationPracticeForm.negative).answerFurigana,
          '思[おも]い 出[だ]さない');
      expect(question('勉強する', ConjugationPracticeForm.potential).answerFurigana,
          '勉強[べんきょう]できる');
      expect(question('静か', ConjugationPracticeForm.polite).answerFurigana,
          '静[しず]かです');
      expect(
          question('いい', ConjugationPracticeForm.past).answerFurigana, 'よかった');
      expect(question('する', ConjugationPracticeForm.negative).answerFurigana,
          'しない');
    });

    test('answerFurigana matches the answer for every question', () {
      final hiragana = RegExp(r'[぀-ゟ]');
      for (final type in ConjugationPracticeWordType.values) {
        for (final word in type.words) {
          for (final form in ConjugationPracticeForm.values) {
            final q = ConjugationPracticeQuestion.create(word, type, form);
            if (q == null) continue;
            final reason = '${word.writing} ${form.name}: ${q.answerFurigana}';
            final pairs = parseFurigana(q.answerFurigana);

            expect(removeFurigana(q.answerFurigana), q.writingAnswer,
                reason: reason);
            expect(
              pairs.map((pair) => pair.reading ?? pair.writing).join(),
              q.readingAnswer,
              reason: reason,
            );
            // Readings are only over kanji
            for (final pair in pairs) {
              if (pair.reading == null) continue;
              expect(hiragana.hasMatch(pair.writing), false, reason: reason);
            }
          }
        }
      }
    });

    test('isCorrect', () {
      final q = question('飲む', ConjugationPracticeForm.negativeTeForm);
      expect(q.isCorrect('のまなくて'), true);
      expect(q.isCorrect('のまないで'), true);
      expect(q.isCorrect('飲まなくて'), true);
      expect(q.isCorrect(' のまなくて '), true);
      expect(q.isCorrect('のまない'), false);
      expect(q.isCorrect(''), false);

      final na = question('静か', ConjugationPracticeForm.politeNegative);
      expect(na.isCorrect('しずかじゃないです'), true);
      expect(na.isCorrect('しずかではありません'), true);
      expect(na.isCorrect('しずかです'), false);
    });

    test('Adjectives only get adjective forms', () {
      final questions = ConjugationPracticeQuestion.getAll(
        types: {ConjugationPracticeWordType.adjectiveI},
        forms: {
          ConjugationPracticeForm.potential,
          ConjugationPracticeForm.past,
        },
      );
      expect(questions.length,
          ConjugationPracticeWordType.adjectiveI.words.length);
      for (final q in questions) {
        expect(q.form, ConjugationPracticeForm.past);
      }

      expect(
        ConjugationPracticeQuestion.getAll(
          types: {ConjugationPracticeWordType.adjectiveNa},
          forms: {ConjugationPracticeForm.volitional},
        ),
        isEmpty,
      );
    });

    test('hasQuestions matches getAll', () {
      for (final type in ConjugationPracticeWordType.values) {
        for (final form in ConjugationPracticeForm.values) {
          expect(
            ConjugationPracticeQuestion.hasQuestions(
              types: {type},
              forms: {form},
            ),
            ConjugationPracticeQuestion.getAll(
              types: {type},
              forms: {form},
            ).isNotEmpty,
            reason: '${type.name} ${form.name}',
          );
        }
      }

      expect(
        ConjugationPracticeQuestion.hasQuestions(
          types: {ConjugationPracticeWordType.adjectiveNa},
          forms: {ConjugationPracticeForm.potential},
        ),
        false,
      );
      expect(
        ConjugationPracticeQuestion.hasQuestions(
          types: {
            ConjugationPracticeWordType.adjectiveNa,
            ConjugationPracticeWordType.godanMu,
          },
          forms: {ConjugationPracticeForm.potential},
        ),
        true,
      );
      expect(
        ConjugationPracticeQuestion.hasQuestions(
          types: {},
          forms: {ConjugationPracticeForm.past},
        ),
        false,
      );
      expect(
        ConjugationPracticeQuestion.hasQuestions(
          types: {ConjugationPracticeWordType.godanMu},
          forms: {},
        ),
        false,
      );
    });

    test('getRandom', () {
      final types = {
        ConjugationPracticeWordType.godanMu,
        ConjugationPracticeWordType.ichidan,
        ConjugationPracticeWordType.irregular,
      };
      final forms = {
        ConjugationPracticeForm.past,
        ConjugationPracticeForm.teForm,
      };
      final questions = ConjugationPracticeQuestion.getRandom(
        types: types,
        forms: forms,
        count: 10,
        random: Random(123),
      );

      expect(questions.length, 10);
      expect(questions.toSet().length, 10);
      // Forms are balanced and words are not repeated
      for (final form in forms) {
        expect(questions.where((e) => e.form == form).length, 5);
      }
      expect(questions.map((e) => e.word).toSet().length, 10);

      // Fewer questions than requested returns everything
      final few = ConjugationPracticeQuestion.getRandom(
        types: {ConjugationPracticeWordType.godanNu},
        forms: forms,
        count: 10,
      );
      expect(few.length, 2);
    });

    test('getRandom splits questions between word types by weighted size', () {
      final types = ConjugationPracticeWordType.values
          .where((e) => !e.isAdjective)
          .toSet();
      final forms = {
        ConjugationPracticeForm.polite,
        ConjugationPracticeForm.negative,
        ConjugationPracticeForm.past,
        ConjugationPracticeForm.teForm,
      };
      final all =
          ConjugationPracticeQuestion.getAll(types: types, forms: forms);
      final totalWeight = all.fold(0, (sum, e) => sum + e.type.weight);

      int godanNuSessions = 0;
      for (int seed = 0; seed < 100; seed++) {
        final questions = ConjugationPracticeQuestion.getRandom(
          types: types,
          forms: forms,
          count: 20,
          random: Random(seed),
        );
        expect(questions.length, 20);
        for (final type in types) {
          final share = 20 *
              type.weight *
              all.where((e) => e.type == type).length /
              totalWeight;
          expect(
            questions.where((e) => e.type == type).length,
            anyOf(share.floor(), share.ceil()),
          );
        }
        // Irregular verbs have a higher weight so they are in every session
        expect(
          questions.where(
            (e) => e.type == ConjugationPracticeWordType.irregular,
          ),
          isNotEmpty,
        );
        for (final form in forms) {
          expect(questions.where((e) => e.form == form).length, 5);
        }
        expect(questions.map((e) => e.word).toSet().length, 20);

        if (questions.any(
          (e) => e.type == ConjugationPracticeWordType.godanNu,
        )) {
          godanNuSessions++;
        }
      }

      // Godan ぬ only has 死ぬ so it is in about 1 in 5 sessions
      expect(godanNuSessions, inInclusiveRange(10, 35));
    });

    test('getRandom gives a weighted word type at most all its questions', () {
      final types = {
        ConjugationPracticeWordType.irregular,
        ConjugationPracticeWordType.godanNu,
        ConjugationPracticeWordType.adjectiveIi,
      };
      final forms = {
        ConjugationPracticeForm.polite,
        ConjugationPracticeForm.past,
        ConjugationPracticeForm.teForm,
      };
      final all =
          ConjugationPracticeQuestion.getAll(types: types, forms: forms);
      // The weighted share of irregular verbs is 20 * 24 / 33, about 14.5,
      // which is more than the 12 questions they have
      expect(all.length, 21);
      expect(
        all.where((e) => e.type == ConjugationPracticeWordType.irregular),
        hasLength(12),
      );

      for (int seed = 0; seed < 100; seed++) {
        final questions = ConjugationPracticeQuestion.getRandom(
          types: types,
          forms: forms,
          count: 20,
          random: Random(seed),
        );
        expect(questions.length, 20);
        expect(questions.toSet().length, 20);
        expect(
          questions.where(
            (e) => e.type == ConjugationPracticeWordType.irregular,
          ),
          hasLength(12),
        );
      }
    });

    test('getRandom balances forms that only some word types allow', () {
      final allTypes = ConjugationPracticeWordType.values.toSet();
      final selections = [
        // Adjectives only allow past
        (
          allTypes,
          {ConjugationPracticeForm.potential, ConjugationPracticeForm.past},
        ),
        // Adjectives only allow polite
        (
          allTypes,
          {
            ConjugationPracticeForm.polite,
            ConjugationPracticeForm.potential,
            ConjugationPracticeForm.volitional,
          },
        ),
        // Too few words to avoid repeating them, and ある has no potential or
        // volitional
        (
          {
            ConjugationPracticeWordType.irregular,
            ConjugationPracticeWordType.godanNu,
          },
          {
            ConjugationPracticeForm.polite,
            ConjugationPracticeForm.negative,
            ConjugationPracticeForm.past,
            ConjugationPracticeForm.teForm,
            ConjugationPracticeForm.potential,
            ConjugationPracticeForm.volitional,
          },
        ),
      ];

      for (final (types, forms) in selections) {
        for (int seed = 0; seed < 100; seed++) {
          final questions = ConjugationPracticeQuestion.getRandom(
            types: types,
            forms: forms,
            count: 20,
            random: Random(seed),
          );
          expect(questions.length, 20);
          final formCounts = [
            for (final form in forms)
              questions.where((e) => e.form == form).length,
          ];
          expect(
            formCounts.reduce(max) - formCounts.reduce(min),
            lessThanOrEqualTo(1),
            reason: 'forms $forms seed $seed counts $formCounts',
          );
        }
      }
    });
  });
}
