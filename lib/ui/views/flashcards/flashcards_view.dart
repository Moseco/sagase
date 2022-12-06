import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:stacked/stacked.dart';

import 'flashcards_viewmodel.dart';

class FlashcardsView extends StatelessWidget {
  final FlashcardSet flashcardSet;

  const FlashcardsView(this.flashcardSet, {super.key});

  @override
  Widget build(BuildContext context) {
    final flipCardController = FlipCardController();
    return ViewModelBuilder<FlashcardsViewModel>.reactive(
      viewModelBuilder: () => FlashcardsViewModel(flashcardSet),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            viewModel.initialLoading
                ? 'Flashcards'
                : viewModel.usingSpacedRepetition
                    ? '(${viewModel.activeFlashcards.length}) ${viewModel.nonFreshFlashcardCount}/${viewModel.allFlashcards!.length}'
                    : '${viewModel.allFlashcards!.length - viewModel.activeFlashcards.length}/${viewModel.allFlashcards!.length}',
          ),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: GestureDetector(
                  onLongPress: viewModel.openFlashcardItem,
                  child: FlipCard(
                    flipOnTouch: viewModel.activeFlashcards.isNotEmpty,
                    controller: flipCardController,
                    fill: Fill.fillBack,
                    direction: FlipDirection.HORIZONTAL,
                    speed: 300,
                    front: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.85,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: viewModel.activeFlashcards.isEmpty
                            ? null
                            : viewModel.activeFlashcards[0] is Vocab
                                ? _VocabFlashcardFront(
                                    flashcardSet: flashcardSet,
                                    vocab:
                                        viewModel.activeFlashcards[0] as Vocab,
                                  )
                                : _KanjiFlashcardFront(
                                    flashcardSet: flashcardSet,
                                    kanji:
                                        viewModel.activeFlashcards[0] as Kanji,
                                  ),
                      ),
                    ),
                    back: SizedBox(
                      height: MediaQuery.of(context).size.width * 0.85,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: viewModel.activeFlashcards.isEmpty
                            ? null
                            : viewModel.activeFlashcards[0] is Vocab
                                ? _VocabFlashcardBack(
                                    flashcardSet: flashcardSet,
                                    vocab:
                                        viewModel.activeFlashcards[0] as Vocab,
                                  )
                                : _KanjiFlashcardBack(
                                    flashcardSet: flashcardSet,
                                    kanji:
                                        viewModel.activeFlashcards[0] as Kanji,
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: viewModel.usingSpacedRepetition
                  ? [
                      _FlashcardAnswerButton(
                        icon: Icons.close,
                        color: Colors.red,
                        onTap: () {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                          viewModel.answerFlashcard(FlashcardAnswer.wrong);
                        },
                      ),
                      _FlashcardAnswerButton(
                        icon: Icons.refresh,
                        color: Colors.yellow,
                        onTap: () {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                          viewModel.answerFlashcard(FlashcardAnswer.wrong);
                        },
                      ),
                      _FlashcardAnswerButton(
                        icon: Icons.check,
                        color: Colors.green,
                        onTap: () {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                          viewModel.answerFlashcard(FlashcardAnswer.correct);
                        },
                      ),
                      _FlashcardAnswerButton(
                        icon: Icons.done_all,
                        color: Colors.blue,
                        onTap: () {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                          viewModel
                              .answerFlashcard(FlashcardAnswer.veryCorrect);
                        },
                      ),
                    ]
                  : [
                      _FlashcardAnswerButton(
                        icon: Icons.close,
                        color: Colors.red,
                        onTap: () {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                          viewModel.answerFlashcard(FlashcardAnswer.wrong);
                        },
                      ),
                      _FlashcardAnswerButton(
                        icon: Icons.check,
                        color: Colors.green,
                        onTap: () {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                          viewModel.answerFlashcard(FlashcardAnswer.correct);
                        },
                      ),
                    ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FlashcardAnswerButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final void Function() onTap;

  const _FlashcardAnswerButton({
    required this.icon,
    required this.color,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40 + MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(color: color),
          child: Icon(icon),
        ),
      ),
    );
  }
}

class _VocabFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const _VocabFlashcardFront({
    required this.flashcardSet,
    required this.vocab,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    if (vocab.kanjiReadingPairs[0].kanjiWritings != null) {
      if (flashcardSet.vocabShowReadingIfRareKanji &&
          vocab.isUsuallyKanaAlone()) {
        // Usually written with kana alone, add faded kanji writing, divider, and reading
        children.addAll([
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, color: Colors.grey),
          ),
          const Divider(
            color: Colors.black,
            indent: 8,
            endIndent: 8,
          ),
          Text(
            vocab.kanjiReadingPairs[0].readings[0].reading,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32),
          ),
        ]);
      } else {
        // Show kanji writing normally
        children.add(
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32),
          ),
        );

        if (flashcardSet.vocabShowReading) {
          // Add divider and reading to be shown with kanji writing
          children.addAll([
            const Divider(
              color: Colors.black,
              indent: 8,
              endIndent: 8,
            ),
            Text(
              vocab.kanjiReadingPairs[0].readings[0].reading,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24),
            ),
          ]);
        }
      }
    } else {
      // Show only reading normally
      children.add(
        Text(
          vocab.kanjiReadingPairs[0].readings[0].reading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class _KanjiFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const _KanjiFlashcardFront({
    required this.flashcardSet,
    required this.kanji,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [
      Text(
        kanji.kanji,
        style: const TextStyle(fontSize: 32),
      ),
    ];

    if (flashcardSet.kanjiShowReading) {
      children.add(
        const Divider(
          color: Colors.black,
          indent: 8,
          endIndent: 8,
        ),
      );
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
            kanji.kunReadings!,
            leading: const TextSpan(
              text: 'Kun readings: ',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            maxLines: 99,
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class _VocabFlashcardBack extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const _VocabFlashcardBack({
    required this.flashcardSet,
    required this.vocab,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    // Add kanji writing and reading
    if (vocab.kanjiReadingPairs[0].kanjiWritings != null) {
      if (vocab.isUsuallyKanaAlone()) {
        children.add(
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, color: Colors.grey),
          ),
        );
      } else {
        children.add(
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
          ),
        );
      }
    }

    children.addAll([
      Text(
        vocab.kanjiReadingPairs[0].readings[0].reading,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 20),
      ),
      const Divider(
        color: Colors.black,
        indent: 8,
        endIndent: 8,
      ),
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

class _KanjiFlashcardBack extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const _KanjiFlashcardBack({
    required this.flashcardSet,
    required this.kanji,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              kanji.kanji,
              style: const TextStyle(fontSize: 24),
            ),
            const Divider(
              color: Colors.black,
              indent: 8,
              endIndent: 8,
            ),
            Text(
              kanji.meanings ?? 'NO MEANING',
              textAlign: TextAlign.center,
            ),
            const Divider(
              color: Colors.black,
              indent: 8,
              endIndent: 8,
            ),
            if (kanji.onReadings != null)
              _KanjiReadingText(
                title: 'On readings',
                content: kanji.onReadings!.join(', '),
              ),
            if (kanji.kunReadings != null)
              KanjiKunReadings(
                kanji.kunReadings!,
                leading: const TextSpan(
                  text: 'Kun readings: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                maxLines: 99,
              ),
            if (kanji.nanori != null)
              _KanjiReadingText(
                title: 'Nanori',
                content: kanji.nanori!.join(', '),
              ),
          ],
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const TextSpan(
            text: ': ',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: content,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}
