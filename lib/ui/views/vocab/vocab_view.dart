import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/common_vocab.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/pitch_accent_text.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:stacked/stacked.dart';
import 'package:ruby_text/ruby_text.dart';

import 'vocab_viewmodel.dart';

class VocabView extends StatelessWidget {
  final Vocab vocab;

  const VocabView(this.vocab, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<VocabViewModel>.reactive(
      viewModelBuilder: () => VocabViewModel(vocab),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed:
                  vocab.kanjiReadingPairs[0].readings[0].pitchAccents != null
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
                vocab.myDictionaryListLinks.isEmpty
                    ? Icons.star_border
                    : Icons.star,
              ),
            ),
          ],
        ),
        // Can throw exception "'!_selectionStartsInScrollable': is not true."
        // when long press then try to scroll on disabled areas.
        // But seems to work okay in release builds.
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _KanjiReadingPairs(vocab.kanjiReadingPairs),
              const _Definitions(),
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
}

class _KanjiReadingPairs extends ViewModelWidget<VocabViewModel> {
  final List<KanjiReadingPair> pairs;

  const _KanjiReadingPairs(this.pairs, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    bool forceOnlyReading =
        pairs[0].kanjiWritings != null && viewModel.vocab.isUsuallyKanaAlone();

    // Primary writing/reading pair
    late Widget primary;
    if (viewModel.showPitchAccent &&
        pairs[0].readings[0].pitchAccents != null) {
      primary = Column(
        children: [
          PitchAccentText(
            text: pairs[0].readings[0].reading,
            pitchAccent: pairs[0].readings[0].pitchAccents!,
            fontSize: (pairs[0].kanjiWritings == null || forceOnlyReading)
                ? 32
                : 32 / 1.5,
          ),
          if (pairs[0].kanjiWritings != null && !forceOnlyReading)
            Text(
              pairs[0].kanjiWritings![0].kanji,
              style: const TextStyle(fontSize: 32, height: 1.2),
            ),
        ],
      );
    } else {
      if (pairs[0].kanjiWritings == null || forceOnlyReading) {
        primary = Text(
          pairs[0].readings[0].reading,
          style: const TextStyle(fontSize: 32),
        );
      } else {
        primary = _RubyTextWrapper(
          pairs: viewModel.getRubyTextPairs(
            pairs[0].kanjiWritings![0].kanji,
            pairs[0].readings[0].reading,
          ),
          fontSize: 32,
        );
      }
    }

    List<Widget> alternatives = [];

    // If forcing only reading, skip this first pair alternatives section
    if (!forceOnlyReading) {
      // Show unique info from first pair
      if (pairs[0].kanjiWritings == null && pairs[0].readings.length > 1) {
        // Only more readings available without kanji writing
        final buffer = StringBuffer(pairs[0].readings[1].reading);
        for (int i = 2; i < pairs[0].readings.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].readings[i].reading);
        }
        alternatives.add(Text(buffer.toString()));
      } else if (pairs[0].kanjiWritings?.length == 1 &&
          pairs[0].readings.length == 2) {
        // 1 additional reading available with only 1 kanji writing
        alternatives.add(
          _RubyTextWrapper(
            pairs: viewModel.getRubyTextPairs(
              pairs[0].kanjiWritings![0].kanji,
              pairs[0].readings[1].reading,
            ),
          ),
        );
      } else if (pairs[0].kanjiWritings?.length == 1 &&
          pairs[0].readings.length > 2) {
        // More then 2 readings available with only 1 kanji writing
        final buffer = StringBuffer(pairs[0].kanjiWritings![0].kanji);
        buffer.write('【');
        buffer.write(pairs[0].readings[1].reading);
        for (int i = 2; i < pairs[0].readings.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].readings[i].reading);
        }
        buffer.write('】');
        alternatives.add(Text(buffer.toString()));
      } else if (pairs[0].kanjiWritings != null &&
          pairs[0].kanjiWritings!.length > 1 &&
          pairs[0].readings.length == 1) {
        // Additional kanji writing with only 1 reading
        final rubyTextPairs = viewModel.getRubyTextPairs(
          pairs[0].kanjiWritings![1].kanji,
          pairs[0].readings[0].reading,
        );
        for (int i = 2; i < pairs[0].kanjiWritings!.length; i++) {
          rubyTextPairs.add(const RubyTextPair(writing: ', '));
          rubyTextPairs.addAll(
            viewModel.getRubyTextPairs(
              pairs[0].kanjiWritings![i].kanji,
              pairs[0].readings[0].reading,
            ),
          );
        }
        alternatives.add(_RubyTextWrapper(pairs: rubyTextPairs));
      } else if (pairs[0].kanjiWritings != null &&
          pairs[0].kanjiWritings!.length > 1 &&
          pairs[0].readings.length > 1) {
        // Multiple kanji writings and readings
        final buffer = StringBuffer(pairs[0].kanjiWritings![0].kanji);
        for (int i = 1; i < pairs[0].kanjiWritings!.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].kanjiWritings![i].kanji);
        }
        buffer.write('【');
        buffer.write(pairs[0].readings[0].reading);
        for (int i = 1; i < pairs[0].readings.length; i++) {
          buffer.write(', ');
          buffer.write(pairs[0].readings[i].reading);
        }
        buffer.write('】');
        alternatives.add(Text(buffer.toString()));
      }
    }

    // Handle remaining pairs
    // From 0 if forcing only reading, otherwise from 1
    for (int i = forceOnlyReading ? 0 : 1; i < pairs.length; i++) {
      if (pairs[i].kanjiWritings != null && pairs[i].readings.length == 1) {
        // 1 or more kanji writings with only 1 reading
        final rubyTextPairs = viewModel.getRubyTextPairs(
          pairs[i].kanjiWritings![0].kanji,
          pairs[i].readings[0].reading,
        );
        for (int j = 1; j < pairs[i].kanjiWritings!.length; j++) {
          rubyTextPairs.add(const RubyTextPair(writing: ', '));
          rubyTextPairs.addAll(
            viewModel.getRubyTextPairs(
              pairs[i].kanjiWritings![j].kanji,
              pairs[i].readings[0].reading,
            ),
          );
        }
        alternatives.add(_RubyTextWrapper(pairs: rubyTextPairs));
      } else {
        final buffer = StringBuffer();
        if (pairs[i].kanjiWritings != null) {
          buffer.write(pairs[i].kanjiWritings![0].kanji);
          for (int j = 1; j < pairs[i].kanjiWritings!.length; j++) {
            buffer.write(', ');
            buffer.write(pairs[i].kanjiWritings![j].kanji);
          }
          buffer.write('【');
        }
        buffer.write(pairs[i].readings[0].reading);
        for (int j = 1; j < pairs[i].readings.length; j++) {
          buffer.write(', ');
          buffer.write(pairs[i].readings[j].reading);
        }
        if (pairs[i].kanjiWritings != null) buffer.write('】');
        alternatives.add(Text(buffer.toString()));
      }
    }

    return Column(
      children: [
        Center(child: primary),
        if (alternatives.isNotEmpty)
          CardWithTitleSection(
            title: 'Alternatives',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: alternatives,
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

  const _RubyTextWrapper({
    required this.pairs,
    this.fontSize,
    Key? key,
  }) : super(key: key);

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
      style: TextStyle(letterSpacing: 0, height: 1.1, fontSize: fontSize),
    );
  }
}

class _Definitions extends ViewModelWidget<VocabViewModel> {
  const _Definitions({Key? key}) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<String> partsOfSpeechStrings = [];
    List<String> otherInfo = [];
    for (var definition in viewModel.vocab.definitions) {
      // Parse parts of speech
      if (definition.pos == null) {
        partsOfSpeechStrings.add('');
      } else {
        final posBuffer = StringBuffer(definition.pos![0].displayTitle);
        for (int i = 1; i < definition.pos!.length; i++) {
          posBuffer.write(', ');
          posBuffer.write(definition.pos![i].displayTitle);
        }
        posBuffer.write('\n');
        partsOfSpeechStrings.add(posBuffer.toString());
      }

      // Parse other info
      final otherInfoBuffer = StringBuffer();
      if (definition.additionalInfo != null) {
        otherInfoBuffer.write(' (');
        otherInfoBuffer.write(definition.additionalInfo);
      }
      if (definition.appliesTo != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write('only apples to: ');
        otherInfoBuffer.write(definition.appliesTo!.join(', '));
      }
      if (definition.fields != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write(definition.fields![0].displayTitle);
        for (int i = 1; i < definition.fields!.length; i++) {
          otherInfoBuffer.write(', ');
          otherInfoBuffer.write(definition.fields![i].displayTitle);
        }
      }
      if (definition.miscInfo != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write(definition.miscInfo![0].displayTitle);
        for (int i = 1; i < definition.miscInfo!.length; i++) {
          otherInfoBuffer.write(', ');
          otherInfoBuffer.write(definition.miscInfo![i].displayTitle);
        }
      }
      if (definition.dialects != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write(definition.dialects![0].displayTitle);
        for (int i = 1; i < definition.dialects!.length; i++) {
          otherInfoBuffer.write(', ');
          otherInfoBuffer.write(definition.dialects![i].displayTitle);
        }
      }
      if (otherInfoBuffer.isNotEmpty) otherInfoBuffer.write(')');
      otherInfo.add(otherInfoBuffer.toString());
    }

    return CardWithTitleSection(
      title: 'Definition',
      titleTrailing: viewModel.vocab.commonWord ? const CommonVocab() : null,
      child: ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.all(8),
        itemCount: viewModel.vocab.definitions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(
              children: [
                if (partsOfSpeechStrings[index].isNotEmpty)
                  WidgetSpan(
                    child: SelectionContainer.disabled(
                      child: Text(
                        '${index + 1}: ',
                        style: const TextStyle(color: Colors.transparent),
                      ),
                    ),
                  ),
                TextSpan(
                  text: partsOfSpeechStrings[index],
                  style: const TextStyle(color: Colors.grey),
                ),
                TextSpan(
                  text: '${index + 1}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: viewModel.vocab.definitions[index].definition),
                if (otherInfo[index].isNotEmpty)
                  TextSpan(
                    text: otherInfo[index],
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KanjiList extends ViewModelWidget<VocabViewModel> {
  const _KanjiList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Kanji',
        child: ListView.builder(
          shrinkWrap: true,
          primary: false,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: viewModel.kanjiList.length,
          itemBuilder: (context, index) {
            final current = viewModel.kanjiList[index];
            if (viewModel.kanjiLoaded) {
              return KanjiListItemLarge(
                kanji: current,
                onPressed: () => viewModel.navigateToKanji(current),
              );
            } else {
              return ListTile(title: Text(current.kanji));
            }
          },
        ),
      ),
    );
  }
}

class _Examples extends ViewModelWidget<VocabViewModel> {
  const _Examples({Key? key}) : super(key: key, reactive: false);
  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<Widget> children = [];
    for (int i = 0; i < viewModel.vocab.definitions.length; i++) {
      if (viewModel.vocab.definitions[i].examples != null) {
        children.add(
          Text(
            'For definition ${i + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        );

        for (var example in viewModel.vocab.definitions[i].examples!) {
          List<RubyTextData> data = [];
          for (var token in example.tokens) {
            for (var rubyPair in token.rubyTextPairs) {
              data.add(
                RubyTextData(
                  rubyPair.writing,
                  ruby: rubyPair.reading,
                ),
              );
            }
          }

          children.add(
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RubyText(
                    data,
                    style: const TextStyle(letterSpacing: 0, height: 1.1),
                  ),
                  Text(example.english),
                ],
              ),
            ),
          );
        }
      }
    }

    if (children.isEmpty) return Container();

    return CardWithTitleSection(
      title: 'Examples',
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

class _Conjugations extends ViewModelWidget<VocabViewModel> {
  const _Conjugations({Key? key}) : super(key: key, reactive: false);
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
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.grey),
          ),
          children: rows,
        ),
      ),
    );
  }
}
