import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:sagase/ui/widgets/furigana_text.dart';
import 'package:sagase/ui/widgets/practice_progress_bar.dart';
import 'package:sagase/ui/widgets/typing_answer_bar.dart';
import 'package:stacked/stacked.dart';

import 'conjugation_practice_viewmodel.dart';

class ConjugationPracticeView extends HookWidget {
  final int? randomSeed;

  const ConjugationPracticeView({this.randomSeed, super.key});

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    return ViewModelBuilder<ConjugationPracticeViewModel>.reactive(
      viewModelBuilder: () =>
          ConjugationPracticeViewModel(randomSeed: randomSeed),
      builder: (context, viewModel, child) {
        void submit(String answer) {
          viewModel.submitAnswer(answer);
          if (!viewModel.showingAnswer) textEditingController.clear();
        }

        return Scaffold(
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
                onPressed: () async {
                  if (!await viewModel.editSelection()) return;
                  textEditingController.clear();
                },
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PracticeProgressBar(
                  completed:
                      viewModel.allItems.length - viewModel.activeItems.length,
                  remaining: viewModel.activeItems.length,
                  remainingLabel: 'left',
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SizedBox.expand(
                          child: viewModel.activeItems.isEmpty
                              ? null
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: _Question(
                                      question: viewModel.activeItems[0],
                                      showingAnswer: viewModel.showingAnswer,
                                      answerCorrect: viewModel.answerCorrect,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                TypingAnswerBar(
                  controller: textEditingController,
                  onSubmit: submit,
                  showingAnswer: viewModel.showingAnswer,
                  answerCorrect: viewModel.answerCorrect,
                  onRetry: viewModel.retryAnswer,
                  convertToHiragana: true,
                  hintText: 'Type in romaji or kana',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Question extends StatelessWidget {
  final ConjugationPracticeQuestion question;
  final bool showingAnswer;
  final bool answerCorrect;

  const _Question({
    required this.question,
    required this.showingAnswer,
    required this.answerCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final answerColor = answerCorrect ? Colors.green : Colors.red;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          question.form.title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FuriganaText(
          question.word.furigana,
          style: const TextStyle(fontSize: 48),
        ),
        Text(
          question.word.meaning,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Visibility(
          visible: showingAnswer,
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: Column(
            children: [
              FuriganaText(
                question.answerFurigana,
                style: TextStyle(fontSize: 32, color: answerColor),
              ),
              Text(
                question.type.title,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
