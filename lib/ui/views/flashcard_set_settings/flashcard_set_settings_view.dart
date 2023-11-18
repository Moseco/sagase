import 'package:flutter/material.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:stacked/stacked.dart';

import 'flashcard_set_settings_viewmodel.dart';

class FlashcardSetSettingsView
    extends StackedView<FlashcardSetSettingsViewModel> {
  final FlashcardSet flashcardSet;

  const FlashcardSetSettingsView(this.flashcardSet, {super.key});

  @override
  FlashcardSetSettingsViewModel viewModelBuilder(BuildContext context) =>
      FlashcardSetSettingsViewModel(flashcardSet);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
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
                          viewModel.isBusy
                              ? const Center(child: CircularProgressIndicator())
                              : GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: viewModel.editIncludedLists,
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Wrap(
                                      spacing: 4,
                                      children: List.generate(
                                        viewModel.predefinedDictionaryLists
                                                .length +
                                            viewModel.myDictionaryLists.length +
                                            1,
                                        (index) {
                                          if (index ==
                                              viewModel
                                                      .predefinedDictionaryLists
                                                      .length +
                                                  viewModel.myDictionaryLists
                                                      .length) {
                                            return const Chip(
                                              label: Text('Add list'),
                                              avatar: Icon(Icons.add),
                                            );
                                          } else if (index <
                                              viewModel
                                                  .predefinedDictionaryLists
                                                  .length) {
                                            return Chip(
                                              label: Text(
                                                viewModel
                                                    .predefinedDictionaryLists[
                                                        index]
                                                    .name,
                                              ),
                                            );
                                          } else {
                                            return Chip(
                                              label: Text(
                                                viewModel
                                                    .myDictionaryLists[index -
                                                        viewModel
                                                            .predefinedDictionaryLists
                                                            .length]
                                                    .name,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                  CardWithTitleSection(
                    title: 'Order Type',
                    child: Padding(
                      padding: const EdgeInsets.all(8),
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
                  ),
                  CardWithTitleSection(
                    title: 'Front type',
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _ToggleOption(
                              text: 'Japanese',
                              enabled:
                                  flashcardSet.frontType == FrontType.japanese,
                              onTap: () =>
                                  viewModel.setFrontType(FrontType.japanese),
                            ),
                            _ToggleOption(
                              text: 'Definition',
                              enabled:
                                  flashcardSet.frontType == FrontType.english,
                              onTap: () =>
                                  viewModel.setFrontType(FrontType.english),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CardWithTitleSection(
                    key: ObjectKey(flashcardSet.frontType),
                    title: 'Appearance',
                    child: Column(
                      children: switch (flashcardSet.frontType) {
                        FrontType.japanese => [
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
                              title: const Text('Show pitch accent'),
                              subtitle: const Text('Vocab flashcards'),
                              trailing: Switch(
                                activeColor: Colors.deepPurple,
                                value: flashcardSet.vocabShowPitchAccent,
                                onChanged: viewModel.setVocabShowPitchAccent,
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
                        FrontType.english => [
                            ListTile(
                              title: const Text('Show parts of speech'),
                              subtitle: const Text('Vocab flashcards'),
                              trailing: Switch(
                                activeColor: Colors.deepPurple,
                                value: flashcardSet.vocabShowPartsOfSpeech,
                                onChanged: viewModel.setVocabShowPartsOfSpeech,
                              ),
                            ),
                            ListTile(
                              title: const Text('Show pitch accent'),
                              subtitle: const Text('Vocab flashcards'),
                              trailing: Switch(
                                activeColor: Colors.deepPurple,
                                value: flashcardSet.vocabShowPitchAccent,
                                onChanged: viewModel.setVocabShowPitchAccent,
                              ),
                            ),
                          ],
                      },
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 8),
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
  });

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
