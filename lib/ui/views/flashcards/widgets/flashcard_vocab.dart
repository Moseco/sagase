import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/grammar_list_item.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/pitch_accent_text.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';

import '../flashcards_viewmodel.dart';

class VocabFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const VocabFlashcardFront({
    super.key,
    required this.flashcardSet,
    required this.vocab,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    if (vocab.writings != null &&
        (vocab.writings![0].info == null ||
            !vocab.writings![0].info!.contains(WritingInfo.searchOnlyForm))) {
      if (flashcardSet.vocabShowReadingIfRareKanji &&
          vocab.isUsuallyKanaAlone()) {
        // Usually written with kana alone, add faded kanji writing and reading
        children.addAll([
          Text(
            vocab.writings![0].writing,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 54, color: Colors.grey),
          ),
          Text(
            vocab.readings[0].reading,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40),
          ),
        ]);
      } else {
        // Show kanji writing normally
        children.add(
          Text(
            vocab.writings![0].writing,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 54),
          ),
        );

        if (flashcardSet.vocabShowReading) {
          // Add reading to be shown with kanji writing
          children.add(
            Text(
              vocab.readings[0].reading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40),
            ),
          );
        }
      }
    } else {
      // Show only reading normally
      children.add(
        Text(
          vocab.readings[0].reading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 54),
        ),
      );
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

class VocabFlashcardFrontEnglish extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const VocabFlashcardFrontEnglish({
    super.key,
    required this.flashcardSet,
    required this.vocab,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    // Add vocab level parts of speech
    if (flashcardSet.vocabShowPartsOfSpeech && vocab.pos != null) {
      final posBuffer = StringBuffer(vocab.pos![0].displayTitle);
      for (int i = 1; i < vocab.pos!.length; i++) {
        posBuffer.write(', ');
        posBuffer.write(vocab.pos![i].displayTitle);
      }

      children.addAll([
        Text(
          posBuffer.toString(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const Text(
          'Applies to all',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const Divider(),
      ]);
    }

    // Add definitions
    for (int i = 0; i < vocab.definitions.length; i++) {
      // Parts of speech
      if (flashcardSet.vocabShowPartsOfSpeech &&
          vocab.definitions[i].pos != null) {
        final posBuffer =
            StringBuffer(vocab.definitions[i].pos![0].displayTitle);
        for (int j = 1; j < vocab.definitions[i].pos!.length; j++) {
          posBuffer.write(', ');
          posBuffer.write(vocab.definitions[i].pos![j].displayTitle);
        }

        children.add(
          Text(
            posBuffer.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        );
      }

      // Actual definition
      children.add(
        Text(
          '${i + 1}: ${vocab.definitions[i].definition}',
          textAlign: TextAlign.center,
        ),
      );
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

class VocabFlashcardBack extends ViewModelWidget<FlashcardsViewModel> {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const VocabFlashcardBack({
    super.key,
    required this.flashcardSet,
    required this.vocab,
  });

  @override
  Widget build(BuildContext context, FlashcardsViewModel viewModel) {
    List<Widget> children = [];

    // Add kanji writing
    if (vocab.writings != null &&
        (vocab.writings![0].info == null ||
            !vocab.writings![0].info!.contains(WritingInfo.searchOnlyForm))) {
      late String writingText;
      if (flashcardSet.vocabShowAlternatives) {
        List<String> writings = [];
        for (var writing in vocab.writings!) {
          if (writing.info == null ||
              !writing.info!.contains(WritingInfo.searchOnlyForm)) {
            writings.add(writing.writing);
          }
        }
        writingText = writings.join(', ');
      } else {
        writingText = vocab.writings![0].writing;
      }

      children.add(
        Text(
          writingText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32,
            color: vocab.isUsuallyKanaAlone() ? Colors.grey : null,
          ),
        ),
      );
    }

    // Add reading
    List<InlineSpan> readingSpans = [];
    if (flashcardSet.vocabShowPitchAccent &&
        vocab.readings[0].pitchAccents != null) {
      readingSpans.add(
        WidgetSpan(
          child: PitchAccentText(
            text: vocab.readings[0].reading,
            pitchAccents: [
              vocab.readings[0].pitchAccents![0],
            ],
            fontSize: children.isEmpty ? 32 : 24,
          ),
        ),
      );

      if (flashcardSet.vocabShowAlternatives) {
        List<String> readings = [];
        // Remaining readings
        for (var reading in vocab.readings) {
          if (reading.info == null ||
              !reading.info!.contains(ReadingInfo.searchOnlyForm)) {
            readings.add(reading.reading);
          }
        }
        // Add to spans
        if (readings.isNotEmpty) {
          if (readingSpans.isNotEmpty) readings.insert(0, '');
          readingSpans.add(TextSpan(text: readings.join(', ')));
        }
      }
    } else {
      if (flashcardSet.vocabShowAlternatives) {
        List<String> readings = [];
        for (var reading in vocab.readings) {
          if (reading.info == null ||
              !reading.info!.contains(ReadingInfo.searchOnlyForm)) {
            readings.add(reading.reading);
          }
        }
        readingSpans.add(TextSpan(text: readings.join(', ')));
      } else {
        readingSpans.add(TextSpan(text: vocab.readings[0].reading));
      }
    }

    children.addAll([
      Text.rich(
        TextSpan(children: readingSpans),
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: children.isEmpty ? 32 : 24),
      ),
      const SizedBox(height: 16),
    ]);

    // Add definitions
    for (int i = 0; i < vocab.definitions.length; i++) {
      children.add(
        Text(
          '${i + 1}: ${vocab.definitions[i].definition}',
          textAlign: TextAlign.center,
        ),
      );
    }

    // Add note
    if (flashcardSet.showNote && vocab.note != null) {
      children.addAll([
        const SizedBox(height: 16),
        Text(
          vocab.note!,
          textAlign: TextAlign.center,
        ),
      ]);
    }

    // Add included kanji
    if (vocab.includedKanji != null) {
      children.add(const SizedBox(height: 16));
      for (var kanji in vocab.includedKanji!) {
        children.add(GestureDetector(
          onLongPress: () => viewModel.openKanji(kanji),
          child: KanjiListItemLarge(kanji: kanji),
        ));
      }
    }

    // Add similar flashcards
    if (vocab.similarFlashcards != null) {
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

      for (var similarFlashcard in vocab.similarFlashcards!) {
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
