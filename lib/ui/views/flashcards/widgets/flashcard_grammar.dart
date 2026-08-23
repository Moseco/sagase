import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/furigana_text.dart';
import 'package:sagase/ui/widgets/grammar_list_item.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class GrammarFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Grammar grammar;

  const GrammarFlashcardFront({
    required this.flashcardSet,
    required this.grammar,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: FuriganaText(
          grammar.form,
          showReading: flashcardSet.grammarShowReading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }
}

class GrammarFlashcardFrontEnglish extends StatelessWidget {
  final Grammar grammar;

  const GrammarFlashcardFrontEnglish({required this.grammar, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Text(
          grammar.meaning,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class GrammarFlashcardBack extends StatelessWidget {
  final Grammar grammar;

  const GrammarFlashcardBack({required this.grammar, super.key});

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      FuriganaText(
        grammar.form,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32),
      ),
      const SizedBox(height: 16),
      Text(
        grammar.meaning,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      FuriganaText(
        grammar.exampleJapanese,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 4),
      Text(
        grammar.exampleEnglish,
        textAlign: TextAlign.center,
      ),
    ];

    if (grammar.similarFlashcards != null) {
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

      for (var similarFlashcard in grammar.similarFlashcards!) {
        if (similarFlashcard is Vocab) {
          children.add(VocabListItem(
            vocab: similarFlashcard,
            showCommonWord: false,
          ));
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
