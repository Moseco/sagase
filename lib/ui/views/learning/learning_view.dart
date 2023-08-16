import 'package:flutter/material.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/widgets/home_header.dart';
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
      body: HomeHeader(
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
        child: switch (viewModel.flashcardSets?.length) {
          null => const _Loading(),
          0 => const _NoFlashcards(),
          _ => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: viewModel.flashcardSets!.length,
              itemBuilder: (context, index) => _FlashcardSet(
                viewModel.flashcardSets![index],
              ),
            ),
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Shimmer.fromColors(
          baseColor: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade300,
          highlightColor:
              isDark ? const Color(0xFF4a4a4a) : Colors.grey.shade100,
          child: Container(
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoFlashcards extends ViewModelWidget<LearningViewModel> {
  const _NoFlashcards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, LearningViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }
}

class _FlashcardSet extends ViewModelWidget<LearningViewModel> {
  final FlashcardSet flashcardSet;

  const _FlashcardSet(this.flashcardSet, {Key? key}) : super(key: key);

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
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
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(Icons.query_stats),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => viewModel.editFlashcardSet(flashcardSet),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.edit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
