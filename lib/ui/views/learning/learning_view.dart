import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';

import 'learning_viewmodel.dart';

class LearningView extends StatelessWidget {
  const LearningView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<LearningViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<LearningViewModel>(),
      builder: (context, viewModel, child) => Scaffold(
        body: HomeHeader(
          title: const Text(
            'Learning',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MainListItem(
                icon: Icons.web_stories,
                titleText: 'Flashcards',
                onTap: viewModel.navigateToFlashcardSets,
              ),
              if (viewModel.recentFlashcardSet != null)
                _RecentFlashcardSet(viewModel.recentFlashcardSet!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainListItem extends StatelessWidget {
  final IconData icon;
  final String titleText;
  final void Function() onTap;

  const _MainListItem({
    required this.icon,
    required this.titleText,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Text(
                  titleText,
                  style: const TextStyle(fontSize: 24),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentFlashcardSet extends ViewModelWidget<LearningViewModel> {
  final FlashcardSet flashcardSet;

  const _RecentFlashcardSet(this.flashcardSet, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, LearningViewModel viewModel) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => viewModel.openRecentFlashcardSet(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      flashcardSet.name,
                      style: const TextStyle(fontSize: 24),
                      maxLines: 1,
                    ),
                  ),
                ),
                if (flashcardSet.usingSpacedRepetition)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => viewModel.openRecentFlashcardSetInfo(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(Icons.query_stats),
                    ),
                  ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => viewModel.editRecentFlashcardSet(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(Icons.edit),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text(
                'Recent flashcard set',
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
