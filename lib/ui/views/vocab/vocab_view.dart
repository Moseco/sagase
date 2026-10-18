import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sagase/datamodels/writing_reading_pair.dart';
import 'package:sagase/ui/widgets/note_section.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/bottom_padding_spacer.dart';
import 'package:sagase/ui/widgets/common_vocab.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/list_navigation_scaffold.dart';
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
    return ListNavigationScaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            key: pitchAccentKey,
            onPressed: viewModel.primaryReading.pitchAccents != null
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
              const BottomPaddingSpacer(),
            ],
          ),
        ),
      ),
      index: vocabListIndex,
      length: vocabList?.length,
      onPrevious: viewModel.navigateToPreviousVocab,
      onNext: viewModel.navigateToNextVocab,
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
    final firstPair = pairs[0];
    final primaryWriting = firstPair.writings?[0];
    final primaryReading = viewModel.primaryReading;
    final forceOnlyReading = viewModel.forceOnlyReading;
    final showPrimaryWriting = primaryWriting != null && !forceOnlyReading;
    final kanaOnlyReadings = viewModel.kanaOnlyReadings;

    // Info is numbered in the order it is shown and explained in a legend
    final legend = _InfoLegend();

    // Primary writing/reading pair
    late Widget primary;
    if (viewModel.showPitchAccent && primaryReading.pitchAccents != null) {
      primary = Column(
        children: [
          PitchAccentText(
            text: primaryReading.reading,
            pitchAccents: primaryReading.pitchAccents!,
            fontSize: showPrimaryWriting ? 32 / 1.5 : 32,
          ),
          if (showPrimaryWriting)
            Text(
              primaryWriting.writing,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, height: 1.2),
            ),
        ],
      );
    } else if (showPrimaryWriting) {
      primary = _RubyTextWrapper(
        pairs: viewModel.getRubyTextPairs(
          primaryWriting.writing,
          primaryReading.reading,
        ),
        fontSize: 32,
        textAlign: TextAlign.center,
      );
    } else {
      primary = Text(
        primaryReading.reading,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32),
      );
    }

    final List<(String, Widget)> sections = [];

    // Info of the primary form is kept out of the header and shown here
    // If forcing only reading, the info is shown with the kanji writings instead
    // unless the reading has no kanji
    final primaryWritingInfo =
        showPrimaryWriting ? _writingInfo(primaryWriting) : <String>[];
    final primaryReadingInfo =
        forceOnlyReading && !kanaOnlyReadings.contains(primaryReading)
            ? <String>[]
            : _readingInfo(primaryReading);
    if (primaryWritingInfo.isNotEmpty || primaryReadingInfo.isNotEmpty) {
      sections.add((
        'Main form',
        showPrimaryWriting
            ? _bracketForms(legend, [primaryWriting], [primaryReading])
            : Text.rich(
                TextSpan(children: _readingSpans(legend, [primaryReading])),
              ),
      ));
    }

    // Every other writing/reading combination is shown exactly once
    if (forceOnlyReading) {
      // Primary is kana so show all kanji writings with their readings
      sections.add((
        'Kanji writings',
        _pairsColumn(viewModel, legend, pairs),
      ));
    } else {
      // Remaining forms of the first pair share all readings with the primary
      if (firstPair.writings != null && firstPair.writings!.length > 1) {
        final writings = firstPair.writings!.sublist(1);
        sections.add((
          'Also written',
          // Info of a single reading is shown in the main form section
          firstPair.readings.length == 1
              ? _rubyWritings(viewModel, legend, writings, primaryReading)
              : _bracketForms(legend, writings, firstPair.readings),
        ));
      }
      if (firstPair.readings.length > 1) {
        final readings = firstPair.readings.sublist(1);
        sections.add((
          'Also read',
          primaryWriting == null
              ? Text.rich(TextSpan(children: _readingSpans(legend, readings)))
              : _writingsWithReadings(
                  viewModel,
                  legend,
                  [primaryWriting],
                  readings,
                ),
        ));
      }
      if (pairs.length > 1) {
        sections.add((
          'Other writings',
          _pairsColumn(viewModel, legend, pairs.sublist(1)),
        ));
      }
    }

    // Readings without kanji are not readings of the kanji so shown separately
    final kanaWritings = [
      for (final reading in kanaOnlyReadings)
        if (reading != primaryReading) reading,
    ];
    if (kanaWritings.isNotEmpty) {
      sections.add((
        'Kana writings',
        Text.rich(TextSpan(children: _readingSpans(legend, kanaWritings))),
      ));
    }

    List<Widget> children = [];
    for (int i = 0; i < sections.length; i++) {
      if (i != 0) children.add(const SizedBox(height: 8));
      children.addAll([
        SelectionContainer.disabled(
          child: Text(
            sections[i].$1,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        const SizedBox(height: 2),
        sections[i].$2,
      ]);
    }

    // Legend at the bottom explaining each number
    if (legend.titles.isNotEmpty) {
      if (children.isNotEmpty) children.add(const Divider());
      for (int i = 0; i < legend.titles.length; i++) {
        children.add(
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.top,
                  child: _Marker('${i + 1}'),
                ),
                TextSpan(text: ' ${legend.titles[i]}'),
              ],
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        );
      }
    }

    return Column(
      children: [
        Center(child: primary),
        if (children.isNotEmpty)
          CardWithTitleSection(
            title: 'Forms',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: DefaultTextStyle.merge(
                style: const TextStyle(fontSize: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Each pair on its own line
  Widget _pairsColumn(
    VocabViewModel viewModel,
    _InfoLegend legend,
    List<WritingReadingPair> pairs,
  ) {
    List<Widget> children = [];
    for (final pair in pairs) {
      if (children.isNotEmpty) children.add(const SizedBox(height: 4));
      if (pair.writings == null) {
        children.add(
          Text.rich(TextSpan(children: _readingSpans(legend, pair.readings))),
        );
      } else {
        children.add(
          _writingsWithReadings(
            viewModel,
            legend,
            pair.writings!,
            pair.readings,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _writingsWithReadings(
    VocabViewModel viewModel,
    _InfoLegend legend,
    List<VocabWriting> writings,
    List<VocabReading> readings,
  ) {
    if (readings.length == 1 && _readingInfo(readings[0]).isEmpty) {
      return _rubyWritings(viewModel, legend, writings, readings[0]);
    }
    return _bracketForms(legend, writings, readings);
  }

  Widget _bracketForms(
    _InfoLegend legend,
    List<VocabWriting> writings,
    List<VocabReading> readings,
  ) {
    return Text.rich(
      TextSpan(
        children: [
          ..._writingSpans(legend, writings),
          const TextSpan(text: '【'),
          ..._readingSpans(legend, readings),
          const TextSpan(text: '】'),
        ],
      ),
    );
  }

  Widget _rubyWritings(
    VocabViewModel viewModel,
    _InfoLegend legend,
    List<VocabWriting> writings,
    VocabReading reading,
  ) {
    List<Widget> children = [];
    for (int i = 0; i < writings.length; i++) {
      final marker = legend.marker(_writingInfo(writings[i]));
      children.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _RubyTextWrapper(
              pairs: viewModel.getRubyTextPairs(
                writings[i].writing,
                reading.reading,
              ),
            ),
            if (marker != null) _Marker(marker, afterRubyText: true),
            if (i != writings.length - 1) const Text(', '),
          ],
        ),
      );
    }

    return Wrap(
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: children,
    );
  }

  List<InlineSpan> _writingSpans(
    _InfoLegend legend,
    List<VocabWriting> writings,
  ) {
    return _formSpans(legend, [
      for (final writing in writings) (writing.writing, _writingInfo(writing)),
    ]);
  }

  List<InlineSpan> _readingSpans(
    _InfoLegend legend,
    List<VocabReading> readings,
  ) {
    return _formSpans(legend, [
      for (final reading in readings) (reading.reading, _readingInfo(reading)),
    ]);
  }

  List<InlineSpan> _formSpans(
    _InfoLegend legend,
    List<(String, List<String>)> forms,
  ) {
    List<InlineSpan> spans = [];
    for (int i = 0; i < forms.length; i++) {
      if (i != 0) spans.add(const TextSpan(text: ', '));
      spans.add(TextSpan(text: forms[i].$1));
      final marker = legend.marker(forms[i].$2);
      if (marker != null) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: _Marker(marker),
          ),
        );
      }
    }
    return spans;
  }

  List<String> _writingInfo(VocabWriting writing) {
    return [
      for (final info in writing.info ?? <WritingInfo>[])
        if (info != WritingInfo.searchOnlyForm) info.displayTitle,
    ];
  }

  List<String> _readingInfo(VocabReading reading) {
    return [
      for (final info in reading.info ?? <ReadingInfo>[])
        if (info != ReadingInfo.searchOnlyForm) info.displayTitle,
    ];
  }
}

// Gives each distinct writing/reading info a number in order of appearance
class _InfoLegend {
  final List<String> titles = [];

  // Returns the superscript text for the given info or null if there is none
  String? marker(List<String> infoTitles) {
    if (infoTitles.isEmpty) return null;
    final numbers = <int>[];
    for (final title in infoTitles) {
      int index = titles.indexOf(title);
      if (index == -1) {
        titles.add(title);
        index = titles.length - 1;
      }
      if (!numbers.contains(index + 1)) numbers.add(index + 1);
    }
    return numbers.join(',');
  }
}

// Small raised number referring to the legend
class _Marker extends StatelessWidget {
  final String text;
  // Ruby text can't hold the marker inline so it is placed after it in a row
  // aligned to the bottom and needs to be raised manually
  final bool afterRubyText;

  const _Marker(this.text, {this.afterRubyText = false});

  @override
  Widget build(BuildContext context) {
    const fontSize = 12.0;
    final marker = SelectionContainer.disabled(
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
    if (!afterRubyText) return marker;

    // Top of the marker is put 1.36 times the font size above the bottom of
    // the ruby text to match the height of markers in regular text
    final textScaler = MediaQuery.textScalerOf(context);
    final baseFontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    return Padding(
      padding: EdgeInsets.only(
        bottom:
            textScaler.scale(baseFontSize) * 1.36 - textScaler.scale(fontSize),
      ),
      child: marker,
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
