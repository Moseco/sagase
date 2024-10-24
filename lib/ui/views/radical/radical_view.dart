import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/card_with_title_expandable.dart';
import 'package:sagase/ui/widgets/list_item_loading.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/radical_position_image.dart';
import 'package:sagase/ui/widgets/stroke_order_diagram.dart';
import 'package:stacked/stacked.dart';

import 'radical_viewmodel.dart';

class RadicalView extends StackedView<RadicalViewModel> {
  final Radical radical;

  const RadicalView(this.radical, {super.key});

  @override
  RadicalViewModel viewModelBuilder(BuildContext context) =>
      RadicalViewModel(radical);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        bottom: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              SelectionContainer.disabled(
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: GestureDetector(
                            onLongPress: () =>
                                viewModel.copyToClipboard(radical.radical),
                            child: Text(
                              radical.radical,
                              style: const TextStyle(fontSize: 80),
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
                                      text: radical.kangxiId.toString(),
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
                                      text: radical.strokeCount.toString(),
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
                                      text: radical.importance?.displayTitle ??
                                          '—',
                                    ),
                                    const TextSpan(
                                      text: '\nImportance',
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
                                    radical.position == null
                                        ? const TextSpan(text: '—')
                                        : WidgetSpan(
                                            child: RadicalPositionImage(
                                              radical.position!,
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
              ),
              if (radical.strokes != null && radical.strokes!.isNotEmpty)
                CardWithTitleExpandable(
                  title: 'Radical stroke order',
                  startExpanded: viewModel.strokeDiagramStartExpanded,
                  expandedChanged: viewModel.setStrokeDiagramStartExpanded,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: StrokeOrderDiagram(radical.strokes!),
                  ),
                ),
              CardWithTitleSection(
                title: 'Radical info',
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
                          const Text(
                            'Meaning: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(radical.meaning),
                        ],
                      ),
                      TableRow(
                        children: [
                          const Text(
                            'Reading: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(radical.reading),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (viewModel.variants != null)
                SelectionContainer.disabled(
                  child: CardWithTitleSection(
                    title: 'Variants',
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: List.generate(
                          viewModel.variants!.length,
                          (index) => Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Center(
                                  child: GestureDetector(
                                    onLongPress: () =>
                                        viewModel.copyToClipboard(
                                            viewModel.variants![index].radical),
                                    child: Text(
                                      viewModel.variants![index].radical,
                                      style: const TextStyle(fontSize: 40),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: viewModel
                                              .variants![index].strokeCount
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
                                                null
                                            ? const TextSpan(text: '—')
                                            : WidgetSpan(
                                                child: RadicalPositionImage(
                                                  viewModel.variants![index]
                                                      .position!,
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
                    ),
                  ),
                ),
              const _KanjiUsage(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _KanjiUsage extends ViewModelWidget<RadicalViewModel> {
  const _KanjiUsage();

  @override
  Widget build(BuildContext context, RadicalViewModel viewModel) {
    late List<Widget> children;
    if (viewModel.kanjiWithRadical == null) {
      children = [const ListItemLoading(showLeading: true)];
    } else {
      children = [
        KanjiListItem(
          kanji: viewModel.kanjiWithRadical![0],
          onPressed: () => viewModel.navigateToKanji(
            viewModel.kanjiWithRadical![0],
          ),
        ),
      ];

      for (int i = 1; i < min(10, viewModel.kanjiWithRadical!.length); i++) {
        children.addAll([
          const Divider(
            height: 1,
            indent: 8,
            endIndent: 8,
          ),
          KanjiListItem(
            kanji: viewModel.kanjiWithRadical![i],
            onPressed: () => viewModel.navigateToKanji(
              viewModel.kanjiWithRadical![i],
            ),
          ),
        ]);
      }
    }

    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Kanji using the radical',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: children),
            ),
            if (viewModel.kanjiWithRadical != null &&
                viewModel.kanjiWithRadical!.length > 10)
              TextButton(
                onPressed: viewModel.showAllKanji,
                child: Text(
                  'Show all ${viewModel.kanjiWithRadical!.length}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
