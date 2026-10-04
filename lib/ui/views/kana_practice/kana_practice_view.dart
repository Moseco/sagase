import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/ui/views/flashcards/widgets/flashcard_deck.dart';
import 'package:stacked/stacked.dart';

import 'kana_practice_viewmodel.dart';

class KanaPracticeView extends HookWidget {
  final int? randomSeed;

  const KanaPracticeView({this.randomSeed, super.key});

  @override
  Widget build(BuildContext context) {
    final flashcardDeckController = use(const FlashcardDeckControllerHook());
    final flipCardController = useMemoized(() => FlipCardController());
    final textEditingController = useTextEditingController();
    return ViewModelBuilder<KanaPracticeViewModel>.reactive(
      viewModelBuilder: () => KanaPracticeViewModel(randomSeed: randomSeed),
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
              onPressed: () {
                textEditingController.clear();
                viewModel.toggleTypingEnabled();
              },
              icon: Icon(
                viewModel.typingEnabled ? Icons.style : Icons.keyboard,
              ),
            ),
            IconButton(
              onPressed: () async {
                if (!await viewModel.editSelection()) return;
                // Session was restarted so reset the current flashcard
                textEditingController.clear();
                if (!viewModel.typingEnabled) {
                  flipCardController.flipWithoutAnimation(CardSide.front);
                }
              },
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _ProgressIndicator(),
              if (viewModel.typingEnabled)
                _Typing(textEditingController)
              else
                _Flashcards(
                  flashcardDeckController: flashcardDeckController,
                  flipCardController: flipCardController,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Flashcards extends ViewModelWidget<KanaPracticeViewModel> {
  final FlashcardDeckController flashcardDeckController;
  final FlipCardController flipCardController;

  const _Flashcards({
    required this.flashcardDeckController,
    required this.flipCardController,
  });

  @override
  Widget build(BuildContext context, KanaPracticeViewModel viewModel) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: flipCardController.flip,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  constraints: BoxConstraints(
                    maxHeight: screenWidth * 0.85 * 1.5,
                    maxWidth: screenWidth * 0.85,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) => FlashcardDeck(
                      swipeUpEnabled: false,
                      controller: flashcardDeckController,
                      currentFlashcard: FlipCard(
                        flipOnTouch: viewModel.activeFlashcards.isNotEmpty,
                        controller: flipCardController,
                        duration: const Duration(milliseconds: 300),
                        front: _Flashcard(
                          constraints: constraints,
                          child: viewModel.activeFlashcards.isEmpty
                              ? Container()
                              : _FlashcardFront(viewModel.activeFlashcards[0]),
                        ),
                        back: _Flashcard(
                          constraints: constraints,
                          child: viewModel.activeFlashcards.isEmpty
                              ? Container()
                              : _FlashcardBack(viewModel.activeFlashcards[0]),
                        ),
                      ),
                      nextFlashcard: _Flashcard(
                        constraints: constraints,
                        child: viewModel.activeFlashcards.length < 2
                            ? Container()
                            : _FlashcardFront(viewModel.activeFlashcards[1]),
                      ),
                      blankFlashcard: _Flashcard(
                        constraints: constraints,
                        child: Container(),
                      ),
                      onSwipeFinished: (swipeAnimation) {
                        if (swipeAnimation != SwipeAnimation.reset) {
                          flipCardController
                              .flipWithoutAnimation(CardSide.front);
                        }

                        switch (swipeAnimation) {
                          case SwipeAnimation.wrong:
                            viewModel.answerFlashcard(KanaPracticeAnswer.wrong);
                            break;
                          case SwipeAnimation.correct:
                            viewModel
                                .answerFlashcard(KanaPracticeAnswer.correct);
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
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: flipCardController.flip,
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
                mainAxisSize: MainAxisSize.max,
                children: [
                  _AnswerButton(
                    icon: Icons.close,
                    color: Colors.red,
                    onTap: () => flashcardDeckController.swipeWrong(),
                  ),
                  _AnswerButton(
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
    );
  }
}

class _Typing extends ViewModelWidget<KanaPracticeViewModel> {
  final TextEditingController textEditingController;

  const _Typing(this.textEditingController);

  @override
  Widget build(BuildContext context, KanaPracticeViewModel viewModel) {
    final double screenWidth = MediaQuery.of(context).size.width;

    void submit() {
      viewModel.submitAnswer(textEditingController.text);
      // Keep a wrong answer visible until moving on to the next flashcard
      if (!viewModel.showingAnswer) textEditingController.clear();
    }

    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                constraints: BoxConstraints(
                  maxHeight: screenWidth * 0.85 * 1.5,
                  maxWidth: screenWidth * 0.85,
                ),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SizedBox.expand(
                    child: viewModel.activeFlashcards.isEmpty
                        ? null
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    viewModel.activeFlashcards[0].kana,
                                    style: const TextStyle(fontSize: 72),
                                  ),
                                  Visibility(
                                    visible: viewModel.showingAnswer,
                                    maintainSize: true,
                                    maintainAnimation: true,
                                    maintainState: true,
                                    child: Text(
                                      viewModel.activeFlashcards[0].romaji,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ],
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: textEditingController,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        onEditingComplete: submit,
                        // Reject edits while showing the answer
                        inputFormatters: [
                          TextInputFormatter.withFunction(
                            (oldValue, newValue) =>
                                viewModel.showingAnswer ? oldValue : newValue,
                          ),
                        ],
                        showCursor: !viewModel.showingAnswer,
                        style: viewModel.showingAnswer
                            ? const TextStyle(color: Colors.red)
                            : null,
                        decoration: const InputDecoration(
                          hintText: 'Romaji',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: submit,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color:
                            viewModel.showingAnswer ? Colors.red : Colors.green,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                      ),
                      child: Icon(
                        viewModel.showingAnswer
                            ? Icons.arrow_forward
                            : Icons.check,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardFront extends StatelessWidget {
  final Kana kana;

  const _FlashcardFront(this.kana);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        kana.kana,
        style: const TextStyle(fontSize: 72),
      ),
    );
  }
}

class _FlashcardBack extends StatelessWidget {
  final Kana kana;

  const _FlashcardBack(this.kana);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            kana.kana,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 16),
          Text(
            kana.romaji,
            style: const TextStyle(fontSize: 32),
          ),
        ],
      ),
    );
  }
}

class _AnswerButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final void Function() onTap;

  const _AnswerButton({
    required this.icon,
    required this.color,
    required this.onTap,
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
          child: Icon(icon, color: Colors.black),
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

class _ProgressIndicator extends ViewModelWidget<KanaPracticeViewModel> {
  const _ProgressIndicator();

  @override
  Widget build(BuildContext context, KanaPracticeViewModel viewModel) {
    int emptyBar = viewModel.activeFlashcards.length;
    int completedBar = viewModel.allFlashcards.length - emptyBar;
    final bottomLeftString = '$completedBar completed';
    final bottomRightString = '$emptyBar cards left';

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
            child: completedBar == 0
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
