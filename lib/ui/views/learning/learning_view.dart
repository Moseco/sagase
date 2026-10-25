import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';

import 'learning_viewmodel.dart';

class LearningView extends StackedView<LearningViewModel> {
  const LearningView({super.key});

  @override
  LearningViewModel viewModelBuilder(context) => LearningViewModel();

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => viewModel.handleBackButton(),
        child: HomeHeader(
          title: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: BackButton(onPressed: () {}, color: Colors.transparent),
              ),
              const Expanded(
                child: Text(
                  'Learning',
                  softWrap: false,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: viewModel.createFlashcardSet,
                  color: Colors.white,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...switch (viewModel.flashcardSets) {
                null => const [_Loading()],
                [] => const [_NoFlashcards()],
                final flashcardSets => [
                    for (final flashcardSet in flashcardSets)
                      _FlashcardSet(flashcardSet),
                  ],
              },
              const _Practice(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade300,
        highlightColor: isDark ? const Color(0xFF4a4a4a) : Colors.grey.shade100,
        child: Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _NoFlashcards extends ViewModelWidget<LearningViewModel> {
  const _NoFlashcards();

  @override
  Widget build(BuildContext context, LearningViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          const Text(
            'You have no flashcards yet. Try creating one using the built in lists or your own lists.',
            textAlign: TextAlign.center,
          ),
          TextButton.icon(
            onPressed: viewModel.createFlashcardSet,
            icon: const Icon(Icons.add),
            label: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _FlashcardSet extends ViewModelWidget<LearningViewModel> {
  final FlashcardSet flashcardSet;

  const _FlashcardSet(this.flashcardSet);

  @override
  Widget build(BuildContext context, LearningViewModel viewModel) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => viewModel.openFlashcardSet(flashcardSet),
        onLongPress: () => viewModel.selectFlashcardStartMode(flashcardSet),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 12),
              child: Icon(Icons.style),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  flashcardSet.name,
                  style: const TextStyle(fontSize: 24),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (flashcardSet.usingSpacedRepetition)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => viewModel.openFlashcardSetInfo(flashcardSet),
                onLongPress: () {},
                child: Container(
                  padding: const EdgeInsets.only(
                    left: 9,
                    right: 9,
                    top: 18,
                    bottom: 18,
                  ),
                  child: const Icon(Icons.query_stats),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => viewModel.editFlashcardSet(flashcardSet),
              onLongPress: () {},
              child: Container(
                padding: const EdgeInsets.only(
                  left: 9,
                  right: 18,
                  top: 18,
                  bottom: 18,
                ),
                child: const Icon(Icons.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Practice extends ViewModelWidget<LearningViewModel> {
  const _Practice();

  @override
  Widget build(BuildContext context, LearningViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 24, bottom: 8),
            child: Row(
              children: [
                Text(
                  'Practice',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12),
                Expanded(child: Divider()),
              ],
            ),
          ),
          _PracticeItem(
            leadingText: 'あ',
            titleText: 'Kana practice',
            subtitleText: 'Read hiragana and katakana',
            onTap: viewModel.navigateToKanaPractice,
          ),
          const SizedBox(height: 8),
          _PracticeItem(
            leadingText: '活',
            titleText: 'Conjugation practice',
            subtitleText: 'Type verb and adjective forms',
            onTap: viewModel.navigateToConjugationPractice,
          ),
        ],
      ),
    );
  }
}

class _PracticeItem extends StatelessWidget {
  final String leadingText;
  final String titleText;
  final String subtitleText;
  final void Function() onTap;

  const _PracticeItem({
    required this.leadingText,
    required this.titleText,
    required this.subtitleText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.deepPurple.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                child: Center(
                  child: Text(
                    leadingText,
                    style: const TextStyle(
                      height: 1.2,
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titleText, style: const TextStyle(fontSize: 20)),
                      Text(
                        subtitleText,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_right,
                color: Colors.deepPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
