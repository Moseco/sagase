import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:stacked/stacked.dart';

import 'flashcards_viewmodel.dart';
import 'widgets/flashcard_deck.dart';

class FlashcardsView extends StatelessWidget {
  final FlashcardSet flashcardSet;

  const FlashcardsView(this.flashcardSet, {super.key});

  @override
  Widget build(BuildContext context) {
    final flashcardDeckController = FlashcardDeckController();
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
          systemOverlayStyle: Theme.of(context).brightness == Brightness.light
              ? const SystemUiOverlayStyle(
                  statusBarIconBrightness: Brightness.dark,
                  statusBarBrightness: Brightness.light,
                )
              : null,
          iconTheme: Theme.of(context).brightness == Brightness.light
              ? const IconThemeData(color: Colors.black)
              : null,
          actions: [
            IconButton(
              onPressed: viewModel.openFlashcardSetInfo,
              icon: const Icon(Icons.query_stats),
            ),
          ],
        ),
        body: Column(
          children: [
            const _ProgressIndicator(),
            Expanded(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  constraints: BoxConstraints(
                    maxHeight: screenWidth * 0.85 * 1.5,
                    maxWidth: screenWidth * 0.85,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => FlashcardDeck(
                      swipeUpEnabled: viewModel.usingSpacedRepetition,
                      controller: flashcardDeckController,
                      currentFlashcard: GestureDetector(
                        onLongPress: viewModel.openFlashcardItem,
                        child: FlipCard(
                          flipOnTouch: viewModel.activeFlashcards.isNotEmpty,
                          controller: flipCardController,
                          fill: Fill.fillBack,
                          direction: FlipDirection.HORIZONTAL,
                          speed: 300,
                          front: _Flashcard(
                            constraints: constraints,
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
                          back: _Flashcard(
                            constraints: constraints,
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
                      nextFlashcard: _Flashcard(
                        constraints: constraints,
                        child: viewModel.activeFlashcards.length < 2
                            ? Container()
                            : viewModel.activeFlashcards[1] is Vocab
                                ? _VocabFlashcardFront(
                                    flashcardSet: flashcardSet,
                                    vocab:
                                        viewModel.activeFlashcards[1] as Vocab,
                                  )
                                : _KanjiFlashcardFront(
                                    flashcardSet: flashcardSet,
                                    kanji:
                                        viewModel.activeFlashcards[1] as Kanji,
                                  ),
                      ),
                      blankFlashcard: _Flashcard(
                        constraints: constraints,
                        child: Container(),
                      ),
                      onSwipeFinished: (swipeAnimation) {
                        if (swipeAnimation != SwipeAnimation.reset) {
                          if (!flipCardController.state!.isFront) {
                            flipCardController.toggleCardWithoutAnimation();
                          }
                        }

                        switch (swipeAnimation) {
                          case SwipeAnimation.wrong:
                            viewModel.answerFlashcard(FlashcardAnswer.wrong);
                            break;
                          case SwipeAnimation.correct:
                            viewModel.answerFlashcard(FlashcardAnswer.correct);
                            break;
                          case SwipeAnimation.veryCorrect:
                            viewModel
                                .answerFlashcard(FlashcardAnswer.veryCorrect);
                            break;
                          case SwipeAnimation.repeat:
                            viewModel.answerFlashcard(FlashcardAnswer.repeat);
                            break;
                          default:
                            break;
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: viewModel.openFlashcardItem,
                    icon: const Icon(Icons.info_outline),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: viewModel.canUndo
                        ? () {
                            if (!flipCardController.state!.isFront) {
                              flipCardController.toggleCardWithoutAnimation();
                            }
                            viewModel.undo();
                            flashcardDeckController.undoSwipe();
                          }
                        : null,
                    icon: const Icon(Icons.undo),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 8,
              margin: EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: 8 + MediaQuery.of(context).padding.bottom * 1.2,
              ),
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
                            onTap: () => flashcardDeckController.swipeWrong(),
                            newInterval:
                                viewModel.getNewInterval(FlashcardAnswer.wrong),
                          ),
                          _FlashcardAnswerButton(
                            icon: Icons.refresh,
                            color: Colors.yellow,
                            onTap: () => flashcardDeckController.swipeRepeat(),
                            newInterval: viewModel
                                .getNewInterval(FlashcardAnswer.repeat),
                          ),
                          _FlashcardAnswerButton(
                            icon: Icons.check,
                            color: Colors.green,
                            onTap: () => flashcardDeckController.swipeCorrect(),
                            newInterval: viewModel
                                .getNewInterval(FlashcardAnswer.correct),
                          ),
                          _FlashcardAnswerButton(
                            icon: Icons.done_all,
                            color: Colors.blue,
                            onTap: () =>
                                flashcardDeckController.swipeVeryCorrect(),
                            newInterval: viewModel
                                .getNewInterval(FlashcardAnswer.veryCorrect),
                          ),
                        ]
                      : [
                          _FlashcardAnswerButton(
                            icon: Icons.close,
                            color: Colors.red,
                            onTap: () => flashcardDeckController.swipeWrong(),
                          ),
                          _FlashcardAnswerButton(
                            icon: Icons.check,
                            color: Colors.green,
                            onTap: () => flashcardDeckController.swipeCorrect(),
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
  final String? newInterval;

  const _FlashcardAnswerButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.newInterval,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.black),
              if (newInterval != null)
                Text(
                  newInterval!,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Flashcard extends StatelessWidget {
  final BoxConstraints constraints;
  final Widget child;

  const _Flashcard({
    required this.constraints,
    required this.child,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: constraints,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: child,
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
        // Usually written with kana alone, add faded kanji writing and reading
        children.addAll([
          Text(
            vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 54, color: Colors.grey),
          ),
          Text(
            vocab.kanjiReadingPairs[0].readings[0].reading,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 40),
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
          // Add reading to be shown with kanji writing
          children.add(
            Text(
              vocab.kanjiReadingPairs[0].readings[0].reading,
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

    // Add included kanji
    if (vocab.includedKanji != null) {
      children.add(const SizedBox(height: 16));
      for (var kanji in vocab.includedKanji!) {
        children.add(KanjiListItem(kanji: kanji));
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(
            text: ': ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: content),
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
      if (viewModel.answeringDueFlashcards) {
        // Answering due flashcards
        completedBar = viewModel.initialDueFlashcardCount -
            viewModel.activeFlashcards.length;
        emptyBar = viewModel.activeFlashcards.length;
        bottomLeftString = '$completedBar completed';
        bottomRightString = '${viewModel.initialDueFlashcardCount} cards due';
      } else {
        // Answering fresh flashcards
        completedBar =
            viewModel.allFlashcards!.length - viewModel.activeFlashcards.length;
        emptyBar = viewModel.activeFlashcards.length;
        bottomLeftString = '$completedBar completed';
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
                            borderRadius: BorderRadius.all(
                              Radius.circular(5),
                            ),
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
