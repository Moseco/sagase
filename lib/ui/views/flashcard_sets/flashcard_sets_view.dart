import 'package:flutter/material.dart';
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
                itemBuilder: (context, index) {
                  return _FlashcardSet(
                    text: viewModel.flashcardSets![index].name,
                    openFlashcardSet: () => viewModel
                        .openFlashcardSet(viewModel.flashcardSets![index]),
                    editFlashcardSet: () => viewModel
                        .editFlashcardSet(viewModel.flashcardSets![index]),
                  );
                },
              ),
      ),
    );
  }
}

class _FlashcardSet extends StatelessWidget {
  final String text;
  final void Function() openFlashcardSet;
  final void Function() editFlashcardSet;

  const _FlashcardSet({
    required this.text,
    required this.openFlashcardSet,
    required this.editFlashcardSet,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: openFlashcardSet,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 24),
                  maxLines: 1,
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: editFlashcardSet,
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
