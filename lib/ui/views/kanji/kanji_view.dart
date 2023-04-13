import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/kanji_radical.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/list_item_loading.dart';
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
              StrokeOrderDiagram(kanji.strokes),
              CardWithTitleSection(
                title: 'Kanji info',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleInfoText(
                        title: 'Meaning',
                        content: kanji.meanings ?? 'NO MEANING',
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
                      if (kanji.onReadings != null)
                        _TitleInfoText(
                          title: 'On readings',
                          content: kanji.onReadings!.join(', '),
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
              SelectionContainer.disabled(
                child: CardWithTitleSection(
                  title: 'Components',
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 8, left: 8),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Radical',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: kanji.radical.isLoaded
                              ? _KanjiRadicalItem(
                                  radical: kanji.radical.value!,
                                  onPressed: viewModel.navigateToKanjiRadical,
                                )
                              : const ListItemLoading(showLeading: true),
                        ),
                        if (kanji.componentLinks.isNotEmpty)
                          Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    'Other components',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                primary: false,
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 16,
                                ),
                                itemCount: kanji.componentLinks.length,
                                itemBuilder: (context, index) => kanji
                                        .componentLinks.isLoaded
                                    ? KanjiListItem(
                                        kanji: kanji.componentLinks
                                            .elementAt(index),
                                        onPressed: () =>
                                            viewModel.navigateToKanji(
                                          kanji.componentLinks.elementAt(index),
                                        ),
                                      )
                                    : const ListItemLoading(showLeading: true),
                              ),
                            ],
                          ),
                      ],
                    ),
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
                          itemCount: min(kanji.compounds.length, 10),
                          itemBuilder: (context, index) => VocabListItem(
                            vocab: kanji.compounds.elementAt(index),
                            onPressed: () => viewModel.navigateToVocab(
                                kanji.compounds.elementAt(index)),
                          ),
                        ),
                        if (kanji.compounds.length > 10)
                          TextButton(
                            onPressed: viewModel.showAllCompounds,
                            child: Text('Show all ${kanji.compounds.length}'),
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

class _KanjiRadicalItem extends StatelessWidget {
  final KanjiRadical radical;
  final void Function() onPressed;

  const _KanjiRadicalItem({
    required this.radical,
    required this.onPressed,
    super.key,
  });

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
