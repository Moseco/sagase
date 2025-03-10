import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sagase/datamodels/writing_reading_pair.dart';
import 'package:sagase/ui/widgets/note_section.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/common_vocab.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/pitch_accent_text.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:stacked/stacked.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'vocab_viewmodel.dart';

class VocabView extends StackedView<VocabViewModel> {
  final Vocab vocab;
  final int? vocabListIndex;
  final List<Vocab>? vocabList;

  final pitchAccentKey = GlobalKey();

  VocabView(this.vocab, {this.vocabListIndex, this.vocabList, super.key});

  @override
  VocabViewModel viewModelBuilder(context) {
    final viewModel = VocabViewModel(vocab, vocabListIndex, vocabList);

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
          () {
            if (context.mounted) _showTutorial(context);
          },
        );
      }
    }

    return viewModel;
  }

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (vocabList != null)
            IconButton(
              onPressed: vocabListIndex == 0
                  ? null
                  : viewModel.navigateToPreviousVocab,
              icon: const Icon(Icons.chevron_left),
            ),
          if (vocabList != null)
            IconButton(
              onPressed: vocabListIndex! == vocabList!.length - 1
                  ? null
                  : viewModel.navigateToNextVocab,
              icon: const Icon(Icons.chevron_right),
            ),
          IconButton(
            key: pitchAccentKey,
            onPressed: vocab.readings[0].pitchAccents != null
                ? viewModel.toggleShowPitchAccent
                : null,
            icon: Icon(
              viewModel.showPitchAccent
                  ? Icons.visibility_off
                  : Icons.visibility,
            ),
          ),
          IconButton(
            onPressed: viewModel.openMyDictionaryListsSheet,
            icon: Icon(
              viewModel.inMyDictionaryList ? Icons.star : Icons.star_border,
            ),
          ),
        ],
      ),
      // Can throw exception "'!_selectionStartsInScrollable': is not true."
      // when long press then try to scroll on disabled areas.
      // But seems to work okay in release builds.
      body: SafeArea(
        bottom: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _KanjiReadingPairs(viewModel.writingReadingPairs),
              const _Definitions(),
              NoteSection(
                note: viewModel.vocab.note,
                editNote: viewModel.editNote,
              ),
              if (viewModel.kanjiList.isNotEmpty) const _KanjiList(),
              const _Examples(),
              if (viewModel.conjugations != null) const _Conjugations(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    TutorialCoachMark(
      pulseEnable: false,
      targets: [
        TargetFocus(
          identify: 'pitchAccentKey',
          keyTarget: pitchAccentKey,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              builder: (context, controller) => const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap to view or hide the pitch accent.',
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
      ],
    ).show(context: context);
  }
}

class _KanjiReadingPairs extends ViewModelWidget<VocabViewModel> {
  final List<WritingReadingPair> pairs;

  const _KanjiReadingPairs(this.pairs);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    bool forceOnlyReading =
        pairs[0].writings != null && viewModel.vocab.isUsuallyKanaAlone();

    // Primary writing/reading pair
    late Widget primary;
    if (viewModel.showPitchAccent &&
        pairs[0].readings[0].pitchAccents != null) {
      primary = Column(
        children: [
          PitchAccentText(
            text: pairs[0].readings[0].reading,
            pitchAccents: pairs[0].readings[0].pitchAccents!,
            fontSize:
                (pairs[0].writings == null || forceOnlyReading) ? 32 : 32 / 1.5,
          ),
          if (pairs[0].writings != null && !forceOnlyReading)
            Text(
              pairs[0].writings![0].writing,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, height: 1.2),
            ),
        ],
      );
    } else {
      if (pairs[0].writings == null || forceOnlyReading) {
        primary = Text(
          pairs[0].readings[0].reading,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32),
        );
      } else {
        primary = _RubyTextWrapper(
          pairs: viewModel.getRubyTextPairs(
            pairs[0].writings![0].writing,
            pairs[0].readings[0].reading,
          ),
          fontSize: 32,
          textAlign: TextAlign.center,
        );
      }
    }

    List<Widget> children = [];

    // If forcing only reading, skip this first pair alternatives section
    if (!forceOnlyReading) {
      // Show unique info from first pair
      if (pairs[0].writings == null && pairs[0].readings.length > 1) {
        // Only more readings available without kanji writing
        final buffer = StringBuffer(pairs[0].readings[1].reading);
        for (int i = 2; i < pairs[0].readings.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].readings[i].reading);
        }
        children.add(Text(buffer.toString()));
      } else if (pairs[0].writings?.length == 1 &&
          pairs[0].readings.length == 2) {
        // 1 additional reading available with only 1 kanji writing
        children.add(
          _RubyTextWrapper(
            pairs: viewModel.getRubyTextPairs(
              pairs[0].writings![0].writing,
              pairs[0].readings[1].reading,
            ),
          ),
        );
      } else if (pairs[0].writings?.length == 1 &&
          pairs[0].readings.length > 2) {
        // More then 2 readings available with only 1 kanji writing
        final buffer = StringBuffer(pairs[0].writings![0].writing);
        buffer.write('【');
        buffer.write(pairs[0].readings[1].reading);
        for (int i = 2; i < pairs[0].readings.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].readings[i].reading);
        }
        buffer.write('】');
        children.add(Text(buffer.toString()));
      } else if (pairs[0].writings != null &&
          pairs[0].writings!.length > 1 &&
          pairs[0].readings.length == 1) {
        // Additional kanji writing with only 1 reading
        final rubyTextPairs = viewModel.getRubyTextPairs(
          pairs[0].writings![1].writing,
          pairs[0].readings[0].reading,
        );
        for (int i = 2; i < pairs[0].writings!.length; i++) {
          rubyTextPairs.add(const RubyTextPair(writing: ', '));
          rubyTextPairs.addAll(
            viewModel.getRubyTextPairs(
              pairs[0].writings![i].writing,
              pairs[0].readings[0].reading,
            ),
          );
        }
        children.add(_RubyTextWrapper(pairs: rubyTextPairs));
      } else if (pairs[0].writings != null &&
          pairs[0].writings!.length > 1 &&
          pairs[0].readings.length > 1) {
        // Multiple kanji writings and readings
        final buffer = StringBuffer(pairs[0].writings![0].writing);
        for (int i = 1; i < pairs[0].writings!.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].writings![i].writing);
        }
        buffer.write('【');
        buffer.write(pairs[0].readings[0].reading);
        for (int i = 1; i < pairs[0].readings.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].readings[i].reading);
        }
        buffer.write('】');
        children.add(Text(buffer.toString()));
      }
    }

    // Handle remaining pairs
    // From 0 if forcing only reading, otherwise from 1
    for (int i = forceOnlyReading ? 0 : 1; i < pairs.length; i++) {
      if (pairs[i].writings != null && pairs[i].readings.length == 1) {
        // 1 or more kanji writings with only 1 reading
        final rubyTextPairs = viewModel.getRubyTextPairs(
          pairs[i].writings![0].writing,
          pairs[i].readings[0].reading,
        );
        for (int j = 1; j < pairs[i].writings!.length; j++) {
          rubyTextPairs.add(const RubyTextPair(writing: ', '));
          rubyTextPairs.addAll(
            viewModel.getRubyTextPairs(
              pairs[i].writings![j].writing,
              pairs[i].readings[0].reading,
            ),
          );
        }
        // Add padding above if not the first alternative
        if (children.isNotEmpty) {
          children.add(const SizedBox(height: 4));
        }
        children.add(_RubyTextWrapper(pairs: rubyTextPairs));
      } else {
        final buffer = StringBuffer();
        if (pairs[i].writings != null) {
          buffer.write(pairs[i].writings![0].writing);
          for (int j = 1; j < pairs[i].writings!.length; j++) {
            buffer.write(', ');
            buffer.write(pairs[i].writings![j].writing);
          }
          buffer.write('【');
        }
        buffer.write(pairs[i].readings[0].reading);
        for (int j = 1; j < pairs[i].readings.length; j++) {
          buffer.write(', ');
          buffer.write(pairs[i].readings[j].reading);
        }
        if (pairs[i].writings != null) buffer.write('】');
        children.add(Text(buffer.toString()));
      }
    }

    // Set up initial title if alternatives available
    late String title;
    if (children.isNotEmpty) {
      title = 'Alternatives';
    }

    // Get all the writing and reading info and sort by type
    Map<WritingInfo, List<String>> kanjiInfoMap = {};
    Map<ReadingInfo, List<String>> readingInfoMap = {};

    for (var pair in viewModel.writingReadingPairs) {
      if (pair.writings != null) {
        for (var writing in pair.writings!) {
          if (writing.info != null) {
            for (var info in writing.info!) {
              kanjiInfoMap[info] ??= [];
              kanjiInfoMap[info]!.add(writing.writing);
            }
          }
        }
      }

      for (var reading in pair.readings) {
        if (reading.info != null) {
          for (var info in reading.info!) {
            readingInfoMap[info] ??= [];
            readingInfoMap[info]!.add(reading.reading);
          }
        }
      }
    }

    // If both irregular kanji/kana exist, merge into kanji version
    if (kanjiInfoMap.containsKey(WritingInfo.irregularKana) &&
        readingInfoMap.containsKey(ReadingInfo.irregularKana)) {
      kanjiInfoMap[WritingInfo.irregularKana]!
          .addAll(readingInfoMap[ReadingInfo.irregularKana]!);
      readingInfoMap.remove(ReadingInfo.irregularKana);
    }

    // Set title and divider if needed
    if (kanjiInfoMap.isNotEmpty || readingInfoMap.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const Divider());
      } else {
        title = 'Kanji/kana info';
      }

      // Merge kanji/reading and info pairs
      List<(String, String)> infoList = [];

      outer:
      for (var entry in kanjiInfoMap.entries) {
        String text = entry.value.join(', ');
        for (int i = 0; i < infoList.length; i++) {
          if (infoList[i].$1 == text) {
            infoList[i] =
                (text, '${infoList[i].$2}, ${entry.key.displayTitle}');
            continue outer;
          }
        }
        infoList.add((text, entry.key.displayTitle));
      }

      outer:
      for (var entry in readingInfoMap.entries) {
        String text = entry.value.join(', ');
        for (int i = 0; i < infoList.length; i++) {
          if (infoList[i].$1 == text) {
            infoList[i] =
                (text, '${infoList[i].$2}, ${entry.key.displayTitle}');
            continue outer;
          }
        }
        infoList.add((text, entry.key.displayTitle));
      }

      for (var item in infoList) {
        children.add(Text('${item.$1}: ${item.$2}'));
      }
    }

    return Column(
      children: [
        Center(child: primary),
        if (children.isNotEmpty)
          CardWithTitleSection(
            title: title,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
      ],
    );
  }
}

class _RubyTextWrapper extends StatelessWidget {
  final List<RubyTextPair> pairs;
  final double? fontSize;
  final TextAlign? textAlign;

  const _RubyTextWrapper({
    required this.pairs,
    this.fontSize,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    List<RubyTextData> rubyTextData = [];
    for (var rubyTextPair in pairs) {
      rubyTextData.add(
        RubyTextData(
          rubyTextPair.writing,
          ruby: rubyTextPair.reading,
        ),
      );
    }
    return RubyText(
      rubyTextData,
      textAlign: textAlign,
      style: TextStyle(letterSpacing: 0, height: 1.1, fontSize: fontSize),
    );
  }
}

class _Definitions extends ViewModelWidget<VocabViewModel> {
  const _Definitions() : super(reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<Widget> children = [];
    // Create vocab level pos
    if (viewModel.vocab.pos != null) {
      final posBuffer = StringBuffer(viewModel.vocab.pos![0].displayTitle);
      for (int i = 1; i < viewModel.vocab.pos!.length; i++) {
        posBuffer.write(', ');
        posBuffer.write(viewModel.vocab.pos![i].displayTitle);
      }

      children.addAll([
        Text(
          posBuffer.toString(),
          style: const TextStyle(color: Colors.grey),
        ),
        if (viewModel.vocab.definitions.length > 1)
          const Text(
            'Applies to all',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        const Divider(),
      ]);
    }

    // Create the definitions
    List<TableRow> rows = [];
    for (int defIndex = 0;
        defIndex < viewModel.vocab.definitions.length;
        defIndex++) {
      var definition = viewModel.vocab.definitions[defIndex];
      // Parse parts of speech
      if (definition.pos != null) {
        final posBuffer = StringBuffer(definition.pos![0].displayTitle);
        for (int i = 1; i < definition.pos!.length; i++) {
          posBuffer.write(', ');
          posBuffer.write(definition.pos![i].displayTitle);
        }

        rows.add(
          TableRow(
            children: [
              Container(),
              Text(
                posBuffer.toString(),
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        );
      }

      // Parse other info
      final List<TextSpan> otherInfoTextSpans = [];
      if (definition.additionalInfo != null) {
        otherInfoTextSpans.add(TextSpan(text: definition.additionalInfo));
      }
      if (definition.appliesTo != null) {
        final buffer = StringBuffer();
        if (otherInfoTextSpans.isNotEmpty) buffer.write('; ');
        buffer.write('only applies to: ${definition.appliesTo!.join(', ')}');
        otherInfoTextSpans.add(TextSpan(text: buffer.toString()));
      }
      if (definition.fields != null) {
        final buffer = StringBuffer();
        if (otherInfoTextSpans.isNotEmpty) buffer.write('; ');
        buffer.write(definition.fields![0].displayTitle);
        for (int i = 1; i < definition.fields!.length; i++) {
          buffer.write(', ');
          buffer.write(definition.fields![i].displayTitle);
        }
        otherInfoTextSpans.add(TextSpan(text: buffer.toString()));
      }
      if (definition.miscInfo != null) {
        final buffer = StringBuffer();
        if (otherInfoTextSpans.isNotEmpty) buffer.write('; ');
        buffer.write(definition.miscInfo![0].displayTitle);
        for (int i = 1; i < definition.miscInfo!.length; i++) {
          buffer.write(', ');
          buffer.write(definition.miscInfo![i].displayTitle);
        }
        otherInfoTextSpans.add(TextSpan(text: buffer.toString()));
      }
      if (definition.dialects != null) {
        final buffer = StringBuffer();
        if (otherInfoTextSpans.isNotEmpty) buffer.write('; ');
        buffer.write(definition.dialects![0].displayTitle);
        for (int i = 1; i < definition.dialects!.length; i++) {
          buffer.write(', ');
          buffer.write(definition.dialects![i].displayTitle);
        }
        otherInfoTextSpans.add(TextSpan(text: buffer.toString()));
      }
      if (definition.languageSource != null) {
        final buffer = StringBuffer();
        if (otherInfoTextSpans.isNotEmpty) buffer.write('; ');
        if (definition.waseieigo) {
          buffer.write('original Japanese word (waseieigo) derived from ');
        } else {
          buffer.write('loan word from ');
        }
        buffer.write(definition.languageSource![0].displayTitle);
        for (int i = 1; i < definition.languageSource!.length; i++) {
          buffer.write(', ');
          buffer.write(definition.languageSource![i].displayTitle);
        }
        otherInfoTextSpans.add(TextSpan(text: buffer.toString()));
      }
      if (definition.crossReferences != null) {
        if (otherInfoTextSpans.isNotEmpty) {
          otherInfoTextSpans.add(const TextSpan(text: '; '));
        }
        otherInfoTextSpans.add(const TextSpan(text: 'see also: '));
        otherInfoTextSpans.add(
          TextSpan(
            text: definition.crossReferences![0].text,
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () =>
                  viewModel.openVocabReference(definition.crossReferences![0]),
          ),
        );
        for (int i = 1; i < definition.crossReferences!.length; i++) {
          otherInfoTextSpans.add(const TextSpan(text: ', '));
          otherInfoTextSpans.add(
            TextSpan(
              text: definition.crossReferences![i].text,
              style: const TextStyle(decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap = () => viewModel
                    .openVocabReference(definition.crossReferences![i]),
            ),
          );
        }
      }
      if (definition.antonyms != null) {
        if (otherInfoTextSpans.isNotEmpty) {
          otherInfoTextSpans.add(const TextSpan(text: '; '));
        }
        otherInfoTextSpans.add(const TextSpan(text: 'antonym: '));
        otherInfoTextSpans.add(
          TextSpan(
            text: definition.antonyms![0].text,
            style: const TextStyle(decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap =
                  () => viewModel.openVocabReference(definition.antonyms![0]),
          ),
        );
        for (int i = 1; i < definition.antonyms!.length; i++) {
          otherInfoTextSpans.add(const TextSpan(text: ', '));
          otherInfoTextSpans.add(
            TextSpan(
              text: definition.antonyms![i].text,
              style: const TextStyle(decoration: TextDecoration.underline),
              recognizer: TapGestureRecognizer()
                ..onTap =
                    () => viewModel.openVocabReference(definition.antonyms![i]),
            ),
          );
        }
      }
      if (otherInfoTextSpans.isNotEmpty) {
        otherInfoTextSpans.insert(0, const TextSpan(text: ' ('));
        otherInfoTextSpans.add(const TextSpan(text: ')'));
      }

      // Add definition itself followed by other info
      rows.add(
        TableRow(
          children: [
            Text(
              '${defIndex + 1}: ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: definition.definition),
                  if (otherInfoTextSpans.isNotEmpty)
                    TextSpan(
                      children: otherInfoTextSpans,
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    children.add(
      Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        children: rows,
      ),
    );

    return CardWithTitleSection(
      title: 'Definition',
      titleTrailing: viewModel.vocab.common ? const CommonVocab() : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _KanjiList extends ViewModelWidget<VocabViewModel> {
  const _KanjiList();

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Kanji',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: viewModel.isBusy
                ? List.generate(
                    viewModel.kanjiList.length,
                    (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 4,
                                right: 12,
                              ),
                              child: Text(
                                viewModel.kanjiList[index],
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [Text(''), Text(''), Text('')],
                            ),
                          ],
                        ),
                      );
                    },
                  )
                : List.generate(
                    viewModel.kanjiList.length,
                    (index) {
                      final current = viewModel.kanjiList[index];
                      return KanjiListItemLarge(
                        kanji: current,
                        onPressed: () => viewModel.navigateToKanji(current),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _Examples extends ViewModelWidget<VocabViewModel> {
  const _Examples() : super(reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<Widget> children = [];
    for (int i = 0; i < viewModel.vocab.definitions.length; i++) {
      if (viewModel.vocab.definitions[i].examples != null) {
        for (var example in viewModel.vocab.definitions[i].examples!) {
          List<RubyTextData> data = [];
          for (var token in example.tokens) {
            // Add main pairs
            for (var rubyPair in token.rubyTextPairs) {
              data.add(
                RubyTextData(
                  rubyPair.writing,
                  ruby: rubyPair.reading,
                ),
              );
            }
            // Add any trailing pairs
            if (token.trailing != null) {
              for (var trailing in token.trailing!) {
                for (var rubyPair in trailing.rubyTextPairs) {
                  data.add(
                    RubyTextData(
                      rubyPair.writing,
                      ruby: rubyPair.reading,
                    ),
                  );
                }
              }
            }
          }

          children.addAll(
            [
              InkWell(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RubyText(
                        data,
                        style: const TextStyle(letterSpacing: 0, height: 1.1),
                      ),
                      Text(example.english),
                      Text(
                        'Applies to definition ${i + 1}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                onTap: () => viewModel.openExampleInAnalysis(example),
              ),
              const Divider(indent: 8, endIndent: 8),
            ],
          );
        }
      }
    }

    if (children.isEmpty) {
      return Container();
    } else {
      // Removes the final divider
      children.removeLast();
    }

    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Examples',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Conjugations extends ViewModelWidget<VocabViewModel> {
  const _Conjugations() : super(reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<TableRow> rows = [
      TableRow(
        children: [
          Container(),
          const Padding(
            padding: EdgeInsets.all(4),
            child: Center(child: Text('Positive')),
          ),
          const Padding(
            padding: EdgeInsets.all(4),
            child: Center(child: Text('Negative')),
          ),
        ],
      ),
    ];

    for (var conjugation in viewModel.conjugations!) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(conjugation.title),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(conjugation.positive),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(conjugation.negative),
            ),
          ],
        ),
      );
    }

    return CardWithTitleSection(
      title: 'Conjugations — ${viewModel.getConjugationPos().displayTitle}',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Table(
          border: const TableBorder.symmetric(
            inside: BorderSide(color: Colors.grey),
          ),
          children: rows,
        ),
      ),
    );
  }
}
