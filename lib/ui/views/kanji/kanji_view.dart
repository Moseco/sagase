import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/stroke_order_diagram.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_viewmodel.dart';

class KanjiView extends StatelessWidget {
  final Kanji kanji;

  const KanjiView(this.kanji, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiViewModel>.reactive(
      viewModelBuilder: () => KanjiViewModel(kanji),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(kanji.kanji),
          actions: [
            IconButton(
              onPressed: viewModel.openMyDictionaryListsSheet,
              icon: Icon(
                kanji.myDictionaryListLinks.isEmpty
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      kanji.kanji,
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                  Expanded(child: Text(kanji.meanings ?? 'NO MEANING')),
                ],
              ),
              StrokeOrderDiagram(kanji.strokes),
              CardWithTitleSection(
                title: 'Reading',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.onReadings != null)
                        _TitleInfoText(
                          title: 'On readings',
                          content: kanji.onReadings!.join(', '),
                        ),
                      if (kanji.kunReadings != null)
                        KanjiKunReadings(
                          kanji.kunReadings!,
                          leading: const TextSpan(
                            text: 'Kun readings: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          maxLines: 99,
                        ),
                      if (kanji.nanori != null)
                        _TitleInfoText(
                          title: 'Nanori',
                          content: kanji.nanori!.join(', '),
                        ),
                    ],
                  ),
                ),
              ),
              CardWithTitleSection(
                title: 'Info',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleInfoText(
                        title: 'Radical',
                        content: kanji.radical.value?.radical ?? 'UNKNOWN',
                      ),
                      if (kanji.components != null)
                        _TitleInfoText(
                          title: 'Components',
                          content: kanji.components!.join(', '),
                        ),
                      _TitleInfoText(
                        title: 'Stroke count',
                        content: kanji.strokeCount.toString(),
                      ),
                      if (kanji.grade != 255)
                        _TitleInfoText(
                          title: 'Grade',
                          content: kanji.grade.toString(),
                        ),
                      if (kanji.frequency != null)
                        _TitleInfoText(
                          title: 'Frequency',
                          content: kanji.frequency.toString(),
                        ),
                      if (kanji.jlpt != 255)
                        _TitleInfoText(
                          title: 'JLPT',
                          content: kanji.jlpt.toString(),
                        ),
                    ],
                  ),
                ),
              ),
              if (kanji.compounds.isNotEmpty)
                SelectionContainer.disabled(
                  child: CardWithTitleSection(
                    title: 'Compounds',
                    child: Column(
                      children: [
                        ListView.separated(
                          separatorBuilder: (_, __) => const Divider(
                            height: 1,
                            indent: 8,
                            endIndent: 8,
                          ),
                          shrinkWrap: true,
                          primary: false,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: kanji.compounds.length < 10
                              ? kanji.compounds.length
                              : 10,
                          itemBuilder: (context, index) => VocabListItem(
                            vocab: kanji.compounds.elementAt(index),
                            onPressed: () => viewModel.navigateToVocab(
                                kanji.compounds.elementAt(index)),
                          ),
                        ),
                        if (kanji.compounds.length > 10)
                          TextButton(
                            onPressed: viewModel.showAllCompounds,
                            child: const Text('Show all'),
                          ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleInfoText extends StatelessWidget {
  final String title;
  final String content;

  const _TitleInfoText({
    required this.title,
    required this.content,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const TextSpan(
            text: ': ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: content),
        ],
      ),
    );
  }
}
