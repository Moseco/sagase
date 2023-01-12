import 'package:flutter/material.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:stacked/stacked.dart';

import 'flashcard_sets_viewmodel.dart';

class FlashcardSetsView extends StatelessWidget {
  const FlashcardSetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FlashcardSetsViewModel>.reactive(
      viewModelBuilder: () => FlashcardSetsViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Flashcards'),
          actions: [
            IconButton(
              onPressed: viewModel.createFlashcardSet,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: viewModel.flashcardSets == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: viewModel.flashcardSets!.length,
                itemBuilder: (context, index) => _FlashcardSet(
                  viewModel.flashcardSets![index],
                ),
              ),
      ),
    );
  }
}

class _FlashcardSet extends ViewModelWidget<FlashcardSetsViewModel> {
  final FlashcardSet flashcardSet;

  const _FlashcardSet(this.flashcardSet, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, FlashcardSetsViewModel viewModel) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => viewModel.openFlashcardSet(flashcardSet),
        child: Row(
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
                onTap: () => viewModel.openFlashcardSetInfo(flashcardSet),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.black,
                  ),
                ),
              ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => viewModel.editFlashcardSet(flashcardSet),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.edit,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
