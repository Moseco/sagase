import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/ui/widgets/pitch_accent_text.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'flashcards_viewmodel.dart';
import 'widgets/flashcard_deck.dart';

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
                          : viewModel.activeFlashcards[0] is Vocab
                              ? switch (viewModel.flashcardSet.frontType) {
                                  FrontType.japanese => _VocabFlashcardFront(
                                      flashcardSet: viewModel.flashcardSet,
                                      vocab: viewModel.activeFlashcards[0]
                                          as Vocab,
                                    ),
                                  FrontType.english =>
                                    _VocabFlashcardFrontEnglish(
                                      flashcardSet: viewModel.flashcardSet,
                                      vocab: viewModel.activeFlashcards[0]
                                          as Vocab,
                                    ),
                                }
                              : switch (viewModel.flashcardSet.frontType) {
                                  FrontType.japanese => _KanjiFlashcardFront(
                                      flashcardSet: viewModel.flashcardSet,
                                      kanji: viewModel.activeFlashcards[0]
                                          as Kanji,
                                    ),
                                  FrontType.english =>
                                    _KanjiFlashcardFrontEnglish(
                                      flashcardSet: viewModel.flashcardSet,
                                      kanji: viewModel.activeFlashcards[0]
                                          as Kanji,
                                    ),
                                },
                    ),
                    back: _Flashcard(
                      constraints: constraints,
                      child: viewModel.activeFlashcards.isEmpty
                          ? Container()
                          : viewModel.activeFlashcards[0] is Vocab
                              ? _VocabFlashcardBack(
                                  flashcardSet: viewModel.flashcardSet,
                                  vocab: viewModel.activeFlashcards[0] as Vocab,
                                )
                              : _KanjiFlashcardBack(
                                  flashcardSet: viewModel.flashcardSet,
                                  kanji: viewModel.activeFlashcards[0] as Kanji,
                                ),
                    ),
                  ),
                ),
                nextFlashcard: _Flashcard(
                  constraints: constraints,
                  child: viewModel.activeFlashcards.length < 2
                      ? Container()
                      : viewModel.activeFlashcards[1] is Vocab
                          ? switch (viewModel.flashcardSet.frontType) {
                              FrontType.japanese => _VocabFlashcardFront(
                                  flashcardSet: viewModel.flashcardSet,
                                  vocab: viewModel.activeFlashcards[1] as Vocab,
                                ),
                              FrontType.english => _VocabFlashcardFrontEnglish(
                                  flashcardSet: viewModel.flashcardSet,
                                  vocab: viewModel.activeFlashcards[1] as Vocab,
                                ),
                            }
                          : switch (viewModel.flashcardSet.frontType) {
                              FrontType.japanese => _KanjiFlashcardFront(
                                  flashcardSet: viewModel.flashcardSet,
                                  kanji: viewModel.activeFlashcards[1] as Kanji,
                                ),
                              FrontType.english => _KanjiFlashcardFrontEnglish(
                                  flashcardSet: viewModel.flashcardSet,
                                  kanji: viewModel.activeFlashcards[1] as Kanji,
                                ),
                            },
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

class _VocabFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const _VocabFlashcardFront({
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

class _VocabFlashcardFrontEnglish extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const _VocabFlashcardFrontEnglish({
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

class _KanjiFlashcardFront extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const _KanjiFlashcardFront({
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

class _KanjiFlashcardFrontEnglish extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const _KanjiFlashcardFrontEnglish({
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

class _VocabFlashcardBack extends ViewModelWidget<FlashcardsViewModel> {
  final FlashcardSet flashcardSet;
  final Vocab vocab;

  const _VocabFlashcardBack({
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
        } else {
          children.add(
            KanjiListItem(kanji: similarFlashcard as Kanji),
          );
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

class _KanjiFlashcardBack extends StatelessWidget {
  final FlashcardSet flashcardSet;
  final Kanji kanji;

  const _KanjiFlashcardBack({
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
        } else {
          children.add(
            KanjiListItem(kanji: similarFlashcard as Kanji),
          );
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
