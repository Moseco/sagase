import 'package:flutter/material.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:stacked/stacked.dart';

import 'flashcard_set_settings_viewmodel.dart';

class FlashcardSetSettingsView extends StatelessWidget {
  final FlashcardSet flashcardSet;

  const FlashcardSetSettingsView(this.flashcardSet, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<FlashcardSetSettingsViewModel>.reactive(
      viewModelBuilder: () => FlashcardSetSettingsViewModel(flashcardSet),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(flashcardSet.name),
          actions: [
            PopupMenuButton<PopupMenuItemType>(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: PopupMenuItemType.rename,
                  child: Text('Rename'),
                ),
                const PopupMenuItem(
                  value: PopupMenuItemType.delete,
                  child: Text('Delete'),
                ),
                if (flashcardSet.usingSpacedRepetition)
                  const PopupMenuItem(
                    value: PopupMenuItemType.reset,
                    child: Text('Reset progress'),
                  ),
                if (flashcardSet.usingSpacedRepetition)
                  const PopupMenuItem(
                    value: PopupMenuItemType.statistics,
                    child: Text('View statistics'),
                  ),
              ],
              onSelected: viewModel.handlePopupMenuButton,
            ),
          ],
        ),
        body: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 8 + MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    CardWithTitleSection(
                      title: 'Included Lists',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            flashcardSet.myDictionaryListLinks.isLoaded
                                ? GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: viewModel.editIncludedLists,
                                    child: Align(
                                      alignment: Alignment.topLeft,
                                      child: Wrap(
                                        spacing: 4,
                                        children: List.generate(
                                          flashcardSet
                                                  .predefinedDictionaryListLinks
                                                  .length +
                                              flashcardSet.myDictionaryListLinks
                                                  .length +
                                              1,
                                          (index) {
                                            if (index ==
                                                flashcardSet
                                                        .predefinedDictionaryListLinks
                                                        .length +
                                                    flashcardSet
                                                        .myDictionaryListLinks
                                                        .length) {
                                              return const Chip(
                                                label: Text('Add list'),
                                                avatar: Icon(Icons.add),
                                              );
                                            } else if (index <
                                                flashcardSet
                                                    .predefinedDictionaryListLinks
                                                    .length) {
                                              return Chip(
                                                label: Text(
                                                  flashcardSet
                                                      .predefinedDictionaryListLinks
                                                      .elementAt(index)
                                                      .name,
                                                ),
                                              );
                                            } else {
                                              return Chip(
                                                label: Text(
                                                  flashcardSet
                                                      .myDictionaryListLinks
                                                      .elementAt(index -
                                                          flashcardSet
                                                              .predefinedDictionaryListLinks
                                                              .length)
                                                      .name,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: CircularProgressIndicator()),
                          ],
                        ),
                      ),
                    ),
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        child: Text(
                          'Order Type',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.grey.shade300
                            : Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _ToggleOption(
                              text: 'Spaced repetition',
                              enabled: flashcardSet.usingSpacedRepetition,
                              onTap: () => viewModel.setOrderType(true),
                            ),
                            _ToggleOption(
                              text: 'Random',
                              enabled: !flashcardSet.usingSpacedRepetition,
                              onTap: () => viewModel.setOrderType(false),
                            ),
                          ],
                        ),
                      ),
                    ),
                    CardWithTitleSection(
                      title: 'Appearance',
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('Show reading'),
                            subtitle: const Text('Vocab flashcards'),
                            trailing: Switch(
                              activeColor: Colors.deepPurple,
                              value: flashcardSet.vocabShowReading,
                              onChanged: viewModel.setVocabShowReading,
                            ),
                          ),
                          ListTile(
                            title: const Text(
                              'Show reading if kanji rarely used',
                            ),
                            subtitle: const Text('Vocab flashcards'),
                            trailing: Switch(
                              activeColor: Colors.deepPurple,
                              value: flashcardSet.vocabShowReadingIfRareKanji,
                              onChanged:
                                  viewModel.setVocabShowReadingIfRareKanji,
                            ),
                          ),
                          ListTile(
                            title: const Text(
                              'Show alternative kanji and reading',
                            ),
                            subtitle: const Text('Vocab flashcards'),
                            trailing: Switch(
                              activeColor: Colors.deepPurple,
                              value: flashcardSet.vocabShowAlternatives,
                              onChanged: viewModel.setVocabShowAlternatives,
                            ),
                          ),
                          ListTile(
                            title: const Text('Show reading'),
                            subtitle: const Text('Kanji flashcards'),
                            trailing: Switch(
                              activeColor: Colors.deepPurple,
                              value: flashcardSet.kanjiShowReading,
                              onChanged: viewModel.setKanjiShowReading,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                      onPressed: viewModel.openFlashcardSet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: const Center(
                          child: Text(
                            'Open Flashcards',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String text;
  final bool enabled;
  final void Function() onTap;

  const _ToggleOption({
    required this.text,
    required this.enabled,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: enabled ? Colors.deepPurple : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: enabled ? Colors.white : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
