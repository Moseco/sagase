import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked_services/stacked_services.dart';

typedef FlashcardSetSelectData = ({
  List<FlashcardSet> matching,
  List<FlashcardSet> others,
});

sealed class FlashcardSetSelectResult {
  const FlashcardSetSelectResult();
}

class FlashcardSetSelectOpen extends FlashcardSetSelectResult {
  final FlashcardSet flashcardSet;
  const FlashcardSetSelectOpen(this.flashcardSet);
}

class FlashcardSetSelectAddToExisting extends FlashcardSetSelectResult {
  final FlashcardSet flashcardSet;
  const FlashcardSetSelectAddToExisting(this.flashcardSet);
}

class FlashcardSetSelectCreateNew extends FlashcardSetSelectResult {
  const FlashcardSetSelectCreateNew();
}

class FlashcardSetSelectDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const FlashcardSetSelectDialog({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final data = request.data as FlashcardSetSelectData;
    final matching = data.matching;
    final others = data.others;

    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
              child: Text(
                'Study flashcards',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  if (matching.isNotEmpty) ...[
                    const _SectionHeader('Open flashcard set with this list'),
                    for (final set in matching)
                      ListTile(
                        leading: const Icon(Icons.style),
                        title: Text(set.name),
                        onTap: () => completer(
                          DialogResponse(data: FlashcardSetSelectOpen(set)),
                        ),
                      ),
                    // const Divider(height: 1),
                  ],
                  if (others.isNotEmpty) ...[
                    const _SectionHeader('Add this list to flashcard set'),
                    for (final set in others)
                      ListTile(
                        leading: const Icon(Icons.playlist_add),
                        title: Text(set.name),
                        onTap: () => completer(
                          DialogResponse(
                            data: FlashcardSetSelectAddToExisting(set),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Material(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  title: Text(
                    'Create new flashcard set',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => completer(
                    DialogResponse(data: const FlashcardSetSelectCreateNew()),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
