import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'flashcard_set_settings_viewmodel.dart';

class FlashcardSetSettingsView
    extends StackedView<FlashcardSetSettingsViewModel> {
  final FlashcardSet flashcardSet;

  final orderTypeKey = GlobalKey();
  final spacedRepetitionKey = GlobalKey();
  final randomKey = GlobalKey();
  final appearanceKey = GlobalKey();

  FlashcardSetSettingsView(this.flashcardSet, {super.key});

  @override
  FlashcardSetSettingsViewModel viewModelBuilder(BuildContext context) {
    final viewModel = FlashcardSetSettingsViewModel(flashcardSet);

    if (viewModel.shouldShowTutorial()) {
      // Try to show tutorial after transition animation ends
      final animation = ModalRoute.of(context)?.animation;
      if (animation != null) {
        void handler(status) {
          if (status == AnimationStatus.completed) {
            _showTutorial(context);
            animation.removeStatusListener(handler);
          }
        }

        animation.addStatusListener(handler);
      } else {
        // Animation was not available, show tutorial after short delay
        Future.delayed(
          const Duration(milliseconds: 150),
          () => _showTutorial(context),
        );
      }
    }

    return viewModel;
  }

  @override
  Widget builder(context, viewModel, child) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  child: Text('Reset'),
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
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
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
                      child: Column(
                        children: [
                          viewModel.isBusy
                              ? Shimmer.fromColors(
                                  baseColor: isDark
                                      ? const Color(0xFF3a3a3a)
                                      : Colors.grey.shade300,
                                  highlightColor: isDark
                                      ? const Color(0xFF4a4a4a)
                                      : Colors.grey.shade100,
                                  child: Container(
                                    height: 64,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8),
                                      ),
                                    ),
                                  ),
                                )
                              : InkWell(
                                  customBorder: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  onTap: viewModel.editIncludedLists,
                                  child: Container(
                                    alignment: Alignment.topLeft,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
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
                    CardWithTitleSection(
                      key: orderTypeKey,
                      title: 'Order Type',
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              _ToggleOption(
                                key: spacedRepetitionKey,
                                text: 'Spaced repetition',
                                enabled: flashcardSet.usingSpacedRepetition,
                                onTap: () => viewModel.setOrderType(true),
                              ),
                              _ToggleOption(
                                key: randomKey,
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
                                enabled: flashcardSet.frontType ==
                                    FrontType.japanese,
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
                      key: appearanceKey,
                      title: 'Appearance',
                      child: Column(
                        key: ObjectKey(flashcardSet.frontType),
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
                                  value:
                                      flashcardSet.vocabShowReadingIfRareKanji,
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
                                  onChanged:
                                      viewModel.setVocabShowPartsOfSpeech,
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
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(8),
                        child: const Text(
                          'Open Flashcards',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, color: Colors.white),
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

  void _showTutorial(BuildContext context) {
    TutorialCoachMark(
      pulseEnable: false,
      targets: [
        TargetFocus(
          identify: 'orderTypeKey',
          keyTarget: orderTypeKey,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice using flashcards in two different ways.',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: 'spacedRepetitionKey',
          keyTarget: spacedRepetitionKey,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 16,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spaced repetition is a proven way of learning information. New and difficult flashcards are shown frequently while old and easy flashcards are shown less often.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: 'randomKey',
          keyTarget: randomKey,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          paddingFocus: 16,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Random order simply shuffles all the flashcards without saving progress between sessions.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        TargetFocus(
          identify: 'appearanceKey',
          keyTarget: appearanceKey,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          shape: ShapeLightFocus.RRect,
          radius: 8,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              builder: (context, controller) => const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customize what is shown on the front of flashcards.',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'The behavior of flashcards can also be customized in the app settings.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ).show(context: context);
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
    super.key,
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
