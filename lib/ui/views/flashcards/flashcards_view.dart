import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'flashcards_viewmodel.dart';
import 'widgets/flashcard_deck.dart';
import 'widgets/flashcard_grammar.dart';
import 'widgets/flashcard_kanji.dart';
import 'widgets/flashcard_vocab.dart';

class FlashcardsView extends HookWidget {
  final FlashcardSet flashcardSet;
  final FlashcardStartMode? startMode;
  final int? randomSeed;

  final answersKey = GlobalKey();

  FlashcardsView(
    this.flashcardSet, {
    this.startMode,
    this.randomSeed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final flashcardDeckController = use(const FlashcardDeckControllerHook());
    final flipCardController = FlipCardController();
    return ViewModelBuilder<FlashcardsViewModel>.reactive(
      viewModelBuilder: () => FlashcardsViewModel(
        flashcardSet,
        startMode,
        randomSeed: randomSeed,
      ),
      fireOnViewModelReadyOnce: true,
      onViewModelReady: (viewModel) {
        if (viewModel.shouldShowTutorial()) {
          // Try to show tutorial after transition animation ends
          final animation = ModalRoute.of(context)?.animation;
          if (animation != null) {
            void handler(status) {
              if (status == AnimationStatus.completed) {
                _showTutorial(context);
                animation.removeStatusListener(handler);
              }
            }

            animation.addStatusListener(handler);
          } else {
            // Animation was not available, show tutorial after short delay
            Future.delayed(
              const Duration(milliseconds: 150),
              () {
                if (context.mounted) {
                  _showTutorial(context);
                }
              },
            );
          }
        }
      },
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _ProgressIndicator(),
              _Flashcards(
                flashcardDeckController: flashcardDeckController,
                flipCardController: flipCardController,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: viewModel.openFlashcardItem,
                        icon: const Icon(Icons.info_outline),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: flipCardController.flip,
                          onLongPress: () {},
                        ),
                      ),
                      IconButton(
                        onPressed: viewModel.canUndo
                            ? () {
                                flipCardController
                                    .flipWithoutAnimation(CardSide.front);
                                viewModel.undo();
                                flashcardDeckController.undoSwipe();
                              }
                            : null,
                        icon: const Icon(Icons.undo),
                      ),
                    ],
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    key: answersKey,
                    mainAxisSize: MainAxisSize.max,
                    children: viewModel.usingSpacedRepetition
                        ? [
                            _FlashcardAnswerButton(
                              icon: Icons.close,
                              color: Colors.red,
                              onTap: () => flashcardDeckController.swipeWrong(),
                              newInterval: viewModel
                                  .getNewInterval(FlashcardAnswer.wrong),
                            ),
                            _FlashcardAnswerButton(
                              icon: Icons.refresh,
                              color: Colors.yellow,
                              onTap: () =>
                                  flashcardDeckController.swipeRepeat(),
                              newInterval: viewModel
                                  .getNewInterval(FlashcardAnswer.repeat),
                            ),
                            _FlashcardAnswerButton(
                              icon: Icons.check,
                              color: Colors.green,
                              onTap: () =>
                                  flashcardDeckController.swipeCorrect(),
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
                              onTap: () =>
                                  flashcardDeckController.swipeCorrect(),
                            ),
                          ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    TutorialCoachMark(
      pulseEnable: false,
      onSkip: () => false,
      targets: [
        TargetFocus(
          identify: 'answersKey',
          keyTarget: answersKey,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 16,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              'Tap the flashcard to reveal the meaning or long press to see more details.\n\n',
                        ),
                        TextSpan(
                          text: 'Wrong',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' will reset the interval before the flashcard is shown again and put it back into the stack.\n\n',
                        ),
                        TextSpan(
                          text: 'Repeat',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' will put the flashcard back into the stack and not affect the interval.\n\n',
                        ),
                        TextSpan(
                          text: 'Correct',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' will increase the interval. New flashcards will take several correct answers to be completed.\n\n',
                        ),
                        TextSpan(
                          text: 'Very correct',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text:
                              ' will increase the interval and accelerate how fast it will grow. New flashcards are completed right away.',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).show(context: context);
  }
}

class _Flashcards extends ViewModelWidget<FlashcardsViewModel> {
  final FlashcardDeckController flashcardDeckController;
  final FlipCardController flipCardController;

  const _Flashcards({
    required this.flashcardDeckController,
    required this.flipCardController,
  });

  @override
  Widget build(BuildContext context, FlashcardsViewModel viewModel) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: flipCardController.flip,
        onLongPress: () {},
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
                    duration: const Duration(milliseconds: 300),
                    front: _Flashcard(
                      constraints: constraints,
                      child: viewModel.activeFlashcards.isEmpty
                          ? Container()
                          : _buildFlashcardFront(
                              viewModel.flashcardSet,
                              viewModel.activeFlashcards[0],
                            ),
                    ),
                    back: _Flashcard(
                      constraints: constraints,
                      child: viewModel.activeFlashcards.isEmpty
                          ? Container()
                          : _buildFlashcardBack(
                              viewModel.flashcardSet,
                              viewModel.activeFlashcards[0],
                            ),
                    ),
                  ),
                ),
                nextFlashcard: _Flashcard(
                  constraints: constraints,
                  child: viewModel.activeFlashcards.length < 2
                      ? Container()
                      : _buildFlashcardFront(
                          viewModel.flashcardSet,
                          viewModel.activeFlashcards[1],
                        ),
                ),
                blankFlashcard: _Flashcard(
                  constraints: constraints,
                  child: Container(),
                ),
                onSwipeFinished: (swipeAnimation) {
                  if (swipeAnimation != SwipeAnimation.reset) {
                    flipCardController.flipWithoutAnimation(CardSide.front);
                  }

                  switch (swipeAnimation) {
                    case SwipeAnimation.wrong:
                      viewModel.answerFlashcard(FlashcardAnswer.wrong);
                      break;
                    case SwipeAnimation.correct:
                      viewModel.answerFlashcard(FlashcardAnswer.correct);
                      break;
                    case SwipeAnimation.veryCorrect:
                      viewModel.answerFlashcard(FlashcardAnswer.veryCorrect);
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
    );
  }
}

Widget _buildFlashcardFront(
  FlashcardSet flashcardSet,
  DictionaryItem flashcard,
) {
  if (flashcard is Vocab) {
    return switch (flashcardSet.frontType) {
      FrontType.japanese =>
        VocabFlashcardFront(flashcardSet: flashcardSet, vocab: flashcard),
      FrontType.english => VocabFlashcardFrontEnglish(
          flashcardSet: flashcardSet,
          vocab: flashcard,
        ),
    };
  } else if (flashcard is Kanji) {
    return switch (flashcardSet.frontType) {
      FrontType.japanese =>
        KanjiFlashcardFront(flashcardSet: flashcardSet, kanji: flashcard),
      FrontType.english => KanjiFlashcardFrontEnglish(
          flashcardSet: flashcardSet,
          kanji: flashcard,
        ),
    };
  } else {
    return switch (flashcardSet.frontType) {
      FrontType.japanese =>
        GrammarFlashcardFront(grammar: flashcard as Grammar),
      FrontType.english =>
        GrammarFlashcardFrontEnglish(grammar: flashcard as Grammar),
    };
  }
}

Widget _buildFlashcardBack(
  FlashcardSet flashcardSet,
  DictionaryItem flashcard,
) {
  if (flashcard is Vocab) {
    return VocabFlashcardBack(flashcardSet: flashcardSet, vocab: flashcard);
  } else if (flashcard is Kanji) {
    return KanjiFlashcardBack(flashcardSet: flashcardSet, kanji: flashcard);
  } else {
    return GrammarFlashcardBack(grammar: flashcard as Grammar);
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
  });

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

class _ProgressIndicator extends ViewModelWidget<FlashcardsViewModel> {
  const _ProgressIndicator();

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
        if (viewModel.showDetailedProgress &&
            viewModel.newFlashcardsAdded != 0) {
          bottomLeftString =
              '${completedBar - viewModel.flashcardSetReport.newFlashcardsCompleted} (${viewModel.flashcardSetReport.newFlashcardsCompleted}) completed';
          int newFlashcardRemaining = viewModel.initialNewFlashcardsCompleted +
              viewModel.newFlashcardsAdded -
              viewModel.flashcardSetReport.newFlashcardsCompleted;
          bottomRightString =
              '${emptyBar - newFlashcardRemaining} ($newFlashcardRemaining) due cards left';
        } else {
          bottomLeftString = '$completedBar completed';
          bottomRightString = '$emptyBar due cards left';
        }
      } else {
        // Answering new flashcards
        completedBar =
            viewModel.allFlashcards!.length - viewModel.activeFlashcards.length;
        emptyBar = viewModel.activeFlashcards.length;
        bottomLeftString =
            '${viewModel.flashcardSetReport.newFlashcardsCompleted} new cards completed';
        bottomRightString = '$emptyBar new cards left';
      }
    } else {
      completedBar =
          viewModel.allFlashcards!.length - viewModel.activeFlashcards.length;
      emptyBar = viewModel.activeFlashcards.length;
      bottomLeftString =
          '${viewModel.allFlashcards!.length - viewModel.activeFlashcards.length} completed';
      bottomRightString = '${viewModel.allFlashcards!.length} cards left';
    }

    // If completedBar or emptyBar would be too small, set minimum size
    if (completedBar != 0 && completedBar / emptyBar < 0.04) {
      completedBar = 1;
      emptyBar = 25;
    } else if (emptyBar != 0 && emptyBar / completedBar < 0.04) {
      completedBar = 25;
      emptyBar = 1;
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
              crossAxisAlignment: CrossAxisAlignment.start,
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
