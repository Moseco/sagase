import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final double screenWidth = MediaQuery.of(context).size.width;
    return ViewModelBuilder<FlashcardsViewModel>.reactive(
      viewModelBuilder: () => FlashcardsViewModel(flashcardSet),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Column(
          children: [
            const _ProgressIndicator(),
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
                    front: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenWidth * 0.85 * 1.5,
                        maxWidth: screenWidth * 0.85,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: viewModel.activeFlashcards.isEmpty
                              ? Container()
                              : viewModel.activeFlashcards[0] is Vocab
                                  ? _VocabFlashcardFront(
                                      flashcardSet: flashcardSet,
                                      vocab: viewModel.activeFlashcards[0]
                                          as Vocab,
                                    )
                                  : _KanjiFlashcardFront(
                                      flashcardSet: flashcardSet,
                                      kanji: viewModel.activeFlashcards[0]
                                          as Kanji,
                                    ),
                        ),
                      ),
                    ),
                    back: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: screenWidth * 0.85 * 1.5,
                        maxWidth: screenWidth * 0.85,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: viewModel.activeFlashcards.isEmpty
                              ? Container()
                              : viewModel.activeFlashcards[0] is Vocab
                                  ? _VocabFlashcardBack(
                                      flashcardSet: flashcardSet,
                                      vocab: viewModel.activeFlashcards[0]
                                          as Vocab,
                                    )
                                  : _KanjiFlashcardBack(
                                      flashcardSet: flashcardSet,
                                      kanji: viewModel.activeFlashcards[0]
                                          as Kanji,
                                    ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Card(
              elevation: 8,
              margin: EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: 8 + MediaQuery.of(context).padding.bottom * 1.2,
              ),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
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
                              viewModel
                                  .answerFlashcard(FlashcardAnswer.correct);
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
                              viewModel
                                  .answerFlashcard(FlashcardAnswer.correct);
                            },
                          ),
                        ],
                ),
              ),
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
          height: 40,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
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
            style: const TextStyle(fontSize: 40, color: Colors.grey),
          ),
          Text(
            vocab.kanjiReadingPairs[0].readings[0].reading,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 54),
          ),
        ]);
      } else {
        // Show kanji writing normally
        children.add(
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 54),
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
              style: const TextStyle(fontSize: 40),
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
          style: const TextStyle(fontSize: 54),
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
        style: const TextStyle(fontSize: 54),
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
            style: const TextStyle(fontSize: 32, color: Colors.grey),
          ),
        );
      } else {
        children.add(
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 32),
          ),
        );
      }
    }

    if (children.isEmpty) {
      children.addAll([
        Text(
          vocab.kanjiReadingPairs[0].readings[0].reading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32),
        ),
        const SizedBox(height: 16),
      ]);
    } else {
      children.addAll([
        Text(
          vocab.kanjiReadingPairs[0].readings[0].reading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 16),
      ]);
    }

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
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 16),
            Text(
              kanji.meanings ?? 'NO MEANING',
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
                kanji.kunReadings!,
                leading: const TextSpan(
                  text: 'Kun readings: ',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                maxLines: 99,
                alignCenter: true,
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
      textAlign: TextAlign.center,
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

class _ProgressIndicator extends ViewModelWidget<FlashcardsViewModel> {
  const _ProgressIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, FlashcardsViewModel viewModel) {
    // Set up widget elements
    int completedBar = 0;
    int emptyBar = 0;
    String bottomLeftString = '';
    String bottomRightString = '';

    if (viewModel.allFlashcards == null) {
      // Empty during loading
    } else if (viewModel.usingSpacedRepetition) {
      if (viewModel.dueFlashcardCount > 0) {
        // Answering due flashcards
        completedBar =
            viewModel.initialDueFlashcardCount - viewModel.dueFlashcardCount;
        emptyBar = viewModel.dueFlashcardCount;
        bottomLeftString = '${viewModel.dueFlashcardCount} cards remaining';
        bottomRightString = '${viewModel.initialDueFlashcardCount} cards due';
      } else {
        // Answering fresh flashcards
        completedBar = viewModel.nonFreshFlashcardCount;
        emptyBar =
            viewModel.allFlashcards!.length - viewModel.nonFreshFlashcardCount;
        bottomLeftString = '${viewModel.nonFreshFlashcardCount} completed';
        bottomRightString = '${viewModel.allFlashcards!.length} cards';
      }
    } else {
      completedBar =
          viewModel.allFlashcards!.length - viewModel.activeFlashcards.length;
      emptyBar = viewModel.activeFlashcards.length;
      bottomLeftString =
          '${viewModel.allFlashcards!.length - viewModel.activeFlashcards.length} completed';
      bottomRightString = '${viewModel.allFlashcards!.length} cards';
    }

    // If completedBar would be too small, set minimum size
    if (completedBar != 0 && completedBar / emptyBar < 0.04) {
      completedBar = 1;
      emptyBar = 25;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: viewModel.allFlashcards == null || completedBar == 0
                ? null
                : Row(
                    children: [
                      Flexible(
                        flex: completedBar,
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.all(Radius.circular(5)),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: emptyBar,
                        child: Container(),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(bottomLeftString, textAlign: TextAlign.start),
                ),
                Expanded(
                  child: Text(bottomRightString, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
