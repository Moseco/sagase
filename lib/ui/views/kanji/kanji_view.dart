import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/card_with_title_expandable.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/list_item_loading.dart';
import 'package:sagase/ui/widgets/stroke_order_diagram.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_viewmodel.dart';

class KanjiView extends StackedView<KanjiViewModel> {
  final Kanji kanji;

  const KanjiView(this.kanji, {super.key});

  @override
  KanjiViewModel viewModelBuilder(context) => KanjiViewModel(kanji);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: viewModel.openMyDictionaryListsSheet,
            icon: Icon(viewModel.inMyLists ? Icons.star : Icons.star_border),
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
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: SelectionContainer.disabled(
                        child: GestureDetector(
                          onLongPress: viewModel.copyKanji,
                          child: Text(
                            kanji.kanji,
                            style: const TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: kanji.grade != 255
                                      ? kanji.grade.toString()
                                      : '—',
                                ),
                                const TextSpan(
                                  text: '\nGrade',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: kanji.strokeCount.toString()),
                                const TextSpan(
                                  text: '\nStrokes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: kanji.frequency != null
                                      ? kanji.frequency.toString()
                                      : '—',
                                ),
                                const TextSpan(
                                  text: '\nRank',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: kanji.jlpt != 255
                                      ? 'N${kanji.jlpt}'
                                      : '—',
                                ),
                                const TextSpan(
                                  text: '\nJLPT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (kanji.strokes != null && kanji.strokes!.isNotEmpty)
              CardWithTitleExpandable(
                title: 'Kanji stroke order',
                startExpanded: viewModel.strokeDiagramStartExpanded,
                expandedChanged: viewModel.setStrokeDiagramStartExpanded,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  child: StrokeOrderDiagram(kanji.strokes!),
                ),
              ),
            CardWithTitleSection(
              title: 'Kanji info',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Table(
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                  },
                  children: [
                    TableRow(
                      children: [
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Meaning: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(kanji.meanings?.join(', ') ?? '(no meaning)'),
                      ],
                    ),
                    if (kanji.kunReadings != null)
                      TableRow(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Kun reading: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          KanjiKunReadings(
                            kanji.kunReadings!,
                            maxLines: 99,
                          ),
                        ],
                      ),
                    if (kanji.onReadings != null)
                      TableRow(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'On reading: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(kanji.onReadings!.join(', ')),
                        ],
                      ),
                    if (kanji.nanori != null)
                      TableRow(
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Nanori: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(kanji.nanori!.join(', ')),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            SelectionContainer.disabled(
              child: CardWithTitleSection(
                title: 'Radical',
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: viewModel.kanjiRadical != null
                      ? _KanjiRadicalItem(
                          radical: viewModel.kanjiRadical!,
                          onPressed: viewModel.navigateToKanjiRadical,
                        )
                      : const ListItemLoading(showLeading: true),
                ),
              ),
            ),
            if (kanji.components != null)
              SelectionContainer.disabled(
                child: CardWithTitleSection(
                  title: 'Other components',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: List.generate(
                        kanji.components!.length,
                        (index) => viewModel.components != null
                            ? KanjiListItem(
                                kanji: viewModel.components![index],
                                onPressed: () => viewModel.navigateToKanji(
                                  viewModel.components![index],
                                ),
                              )
                            : const ListItemLoading(showLeading: true),
                      ),
                    ),
                  ),
                ),
              ),
            if (kanji.compounds != null) const _Compounds(),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class _KanjiRadicalItem extends StatelessWidget {
  final KanjiRadical radical;
  final void Function() onPressed;

  const _KanjiRadicalItem({
    required this.radical,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                radical.radical,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Radical #${radical.kangxiId} - ${radical.meaning}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    radical.reading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (radical.variants != null)
                    Text(
                      "Variants: ${radical.variants!.join(', ')}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (radical.variantOf != null)
                    Text(
                      'Variant of ${radical.variantOf}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Compounds extends ViewModelWidget<KanjiViewModel> {
  const _Compounds({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, KanjiViewModel viewModel) {
    late List<Widget> children;
    if (viewModel.compoundPreviewList == null) {
      children = [const ListItemLoading(showLeading: true)];
    } else {
      children = [
        VocabListItem(
            vocab: viewModel.compoundPreviewList![0],
            onPressed: () =>
                viewModel.navigateToVocab(viewModel.compoundPreviewList![0])),
      ];

      for (int i = 1; i < viewModel.compoundPreviewList!.length; i++) {
        children.addAll([
          const Divider(
            height: 1,
            indent: 8,
            endIndent: 8,
          ),
          VocabListItem(
              vocab: viewModel.compoundPreviewList![i],
              onPressed: () =>
                  viewModel.navigateToVocab(viewModel.compoundPreviewList![i])),
        ]);
      }
    }

    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Compounds',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: children),
            ),
            if (viewModel.compoundPreviewList != null &&
                viewModel.kanji.compounds!.length > 10)
              TextButton(
                onPressed: viewModel.showAllCompounds,
                child: Text('Show all ${viewModel.kanji.compounds!.length}'),
              ),
          ],
        ),
      ),
    );
  }
}
