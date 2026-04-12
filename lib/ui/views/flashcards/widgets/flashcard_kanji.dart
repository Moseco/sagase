import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/grammar_list_item.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class KanjiFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const KanjiFlashcardFront({
    super.key,
    required this.flashcardSet,
    required this.kanji,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Text(
        kanji.kanji,
        style: const TextStyle(fontSize: 54),
      ),
    ];

    if (flashcardSet.kanjiShowReading) {
      if (kanji.onReadings != null) {
        children.add(
          _KanjiReadingText(
            title: 'On readings',
            content: kanji.onReadings!.join(', '),
          ),
        );
      }
      if (kanji.kunReadings != null) {
        children.add(
          KanjiKunReadings(
            kanji.kunReadings!.map((e) => e.reading).toList(),
            leading: const TextSpan(
              text: 'Kun readings: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            maxLines: 99,
            alignCenter: true,
          ),
        );
      }
      if (kanji.nanori != null) {
        children.add(
          _KanjiReadingText(
            title: 'Nanori',
            content: kanji.nanori!.join(', '),
          ),
        );
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class KanjiFlashcardFrontEnglish extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const KanjiFlashcardFrontEnglish({
    super.key,
    required this.flashcardSet,
    required this.kanji,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Text(
          kanji.meaning ?? '(no meaning)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class KanjiFlashcardBack extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const KanjiFlashcardBack({
    super.key,
    required this.flashcardSet,
    required this.kanji,
  });

  @override
  Widget build(BuildContext context) {
    // Create list with base elements
    List<Widget> children = [
      Text(
        kanji.kanji,
        style: const TextStyle(fontSize: 40),
      ),
      const SizedBox(height: 16),
      Text(
        kanji.meaning ?? '(no meaning)',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      if (kanji.onReadings != null)
        _KanjiReadingText(
          title: 'On readings',
          content: kanji.onReadings!.join(', '),
        ),
      if (kanji.kunReadings != null)
        KanjiKunReadings(
          kanji.kunReadings!.map((e) => e.reading).toList(),
          leading: const TextSpan(
            text: 'Kun readings: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          maxLines: 99,
          alignCenter: true,
        ),
      if (kanji.nanori != null)
        _KanjiReadingText(
          title: 'Nanori',
          content: kanji.nanori!.join(', '),
        ),
    ];

    // Add similar flashcards
    if (kanji.similarFlashcards != null) {
      children.addAll([
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(child: Divider(endIndent: 8)),
            Text(
              'Similar flashcards',
              style: TextStyle(color: Colors.grey),
            ),
            Expanded(child: Divider(indent: 8)),
          ],
        ),
      ]);

      for (var similarFlashcard in kanji.similarFlashcards!) {
        if (similarFlashcard is Vocab) {
          children.add(
            VocabListItem(
              vocab: similarFlashcard,
              showCommonWord: false,
            ),
          );
        } else if (similarFlashcard is Kanji) {
          children.add(KanjiListItem(kanji: similarFlashcard));
        } else {
          children.add(GrammarListItem(grammar: similarFlashcard as Grammar));
        }
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class _KanjiReadingText extends StatelessWidget {
  final String title;
  final String content;

  const _KanjiReadingText({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(
            text: ': ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: content),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
