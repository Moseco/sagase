import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/card_with_title_expandable.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/kanji_radical_position.dart';
import 'package:sagase/ui/widgets/stroke_order_diagram.dart';
import 'package:stacked/stacked.dart';

import 'kanji_radical_viewmodel.dart';

class KanjiRadicalView extends StatelessWidget {
  final KanjiRadical kanjiRadical;

  const KanjiRadicalView(this.kanjiRadical, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiRadicalViewModel>.reactive(
      viewModelBuilder: () => KanjiRadicalViewModel(kanjiRadical),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(),
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
                            onLongPress: viewModel.copyKanjiRadical,
                            child: Text(
                              kanjiRadical.radical,
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
                                    text: kanjiRadical.kangxiId.toString(),
                                  ),
                                  const TextSpan(
                                    text: '\nRadical #',
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
                                    text: kanjiRadical.strokeCount.toString(),
                                  ),
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
                                    text: kanjiRadical.kanjiWithRadical.length
                                        .toString(),
                                  ),
                                  const TextSpan(
                                    text: '\nFrequency',
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
                                  kanjiRadical.position ==
                                          KanjiRadicalPosition.none
                                      ? const TextSpan(text: '—')
                                      : WidgetSpan(
                                          child: KanjiRadicalPositionImage(
                                            kanjiRadical.position,
                                          ),
                                        ),
                                  const TextSpan(
                                    text: '\nPosition',
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
              if (kanjiRadical.strokes != null &&
                  kanjiRadical.strokes!.isNotEmpty)
                CardWithTitleExpandable(
                  title: 'Radical stroke order',
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: StrokeOrderDiagram(kanjiRadical.strokes!),
                  ),
                ),
              CardWithTitleSection(
                title: 'Radical info',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TitleInfoText(
                        title: 'Meaning',
                        content: kanjiRadical.meaning,
                      ),
                      _TitleInfoText(
                        title: 'Reading',
                        content: kanjiRadical.reading,
                      ),
                      if (kanjiRadical.importance !=
                          KanjiRadicalImportance.none)
                        _TitleInfoText(
                          title: 'Importance',
                          content: _getImportanceString(),
                        ),
                    ],
                  ),
                ),
              ),
              if (viewModel.variants != null)
                CardWithTitleSection(
                  title: 'Variants',
                  child: ListView.builder(
                    shrinkWrap: true,
                    primary: false,
                    padding: const EdgeInsets.all(8),
                    itemCount: viewModel.variants!.length,
                    itemBuilder: (context, index) => Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Center(
                            child: Text(
                              viewModel.variants![index].radical,
                              style: const TextStyle(fontSize: 40),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: viewModel.variants![index].strokeCount
                                        .toString(),
                                  ),
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
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  viewModel.variants![index].position ==
                                          KanjiRadicalPosition.none
                                      ? const TextSpan(text: '—')
                                      : WidgetSpan(
                                          child: KanjiRadicalPositionImage(
                                            viewModel.variants![index].position,
                                          ),
                                        ),
                                  const TextSpan(
                                    text: '\nPosition',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (kanjiRadical.kanjiWithRadical.isNotEmpty)
                SelectionContainer.disabled(
                  child: CardWithTitleSection(
                    title: 'Kanji using the radical',
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
                          itemCount: kanjiRadical.kanjiWithRadical.length < 10
                              ? kanjiRadical.kanjiWithRadical.length
                              : 10,
                          itemBuilder: (context, index) => KanjiListItem(
                            kanji:
                                kanjiRadical.kanjiWithRadical.elementAt(index),
                            onPressed: () => viewModel.navigateToKanji(
                              kanjiRadical.kanjiWithRadical.elementAt(index),
                            ),
                          ),
                        ),
                        if (kanjiRadical.kanjiWithRadical.length > 10)
                          TextButton(
                            onPressed: viewModel.showAllKanji,
                            child: Text(
                              'Show all ${kanjiRadical.kanjiWithRadical.length}',
                            ),
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

  String _getImportanceString() {
    switch (kanjiRadical.importance) {
      case KanjiRadicalImportance.top25:
        return 'Top 25%';
      case KanjiRadicalImportance.top50:
        return 'Top 50%';
      case KanjiRadicalImportance.top75:
        return 'Top 75%';
      case KanjiRadicalImportance.none:
        return '';
    }
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
