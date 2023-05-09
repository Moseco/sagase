import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sagase/datamodels/kanji_radical.dart';
import 'package:sagase/ui/widgets/kanji_radical_position.dart';
import 'package:stacked/stacked.dart';

import 'kanji_radicals_viewmodel.dart';

class KanjiRadicalsView extends StatelessWidget {
  const KanjiRadicalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiRadicalsViewModel>.reactive(
      viewModelBuilder: () => KanjiRadicalsViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Radicals'),
          actions: [
            PopupMenuButton<RadicalSorting>(
              onSelected: viewModel.handleSortingChanged,
              itemBuilder: (context) => [
                CheckedPopupMenuItem<RadicalSorting>(
                  value: RadicalSorting.all,
                  checked: viewModel.radicalSorting == RadicalSorting.all,
                  child: const Text('All radicals'),
                ),
                CheckedPopupMenuItem<RadicalSorting>(
                  value: RadicalSorting.classic,
                  checked: viewModel.radicalSorting == RadicalSorting.classic,
                  child: const Text('Classic 214 radicals'),
                ),
                CheckedPopupMenuItem<RadicalSorting>(
                  value: RadicalSorting.important,
                  checked: viewModel.radicalSorting == RadicalSorting.important,
                  child: const Text('Important radicals'),
                ),
              ],
            ),
          ],
        ),
        body: viewModel.kanjiRadicals == null
            ? Container()
            : CustomScrollView(
                slivers: viewModel.radicalSorting == RadicalSorting.important
                    ? _getRadicalListByImportance(
                        context,
                        viewModel.kanjiRadicals!,
                      )
                    : _getRadicalListByStrokeCount(
                        context,
                        viewModel.kanjiRadicals!,
                      ),
              ),
      ),
    );
  }

  List<Widget> _getRadicalListByStrokeCount(
    BuildContext context,
    List<KanjiRadical> radicals,
  ) {
    final List<Widget> radicalGroups = [];

    int currentStrokeCount = -1;
    late List<Widget> currentRadicals;
    for (var radical in radicals) {
      if (radical.strokeCount != currentStrokeCount) {
        currentStrokeCount = radical.strokeCount;
        currentRadicals = [];
        radicalGroups.add(
          SliverStickyHeader(
            header: Container(
              width: double.infinity,
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.all(12),
              child: SelectionContainer.disabled(
                child: Text(
                  currentStrokeCount == 1
                      ? '$currentStrokeCount stroke'
                      : '$currentStrokeCount strokes',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(currentRadicals),
            ),
          ),
        );
      }

      currentRadicals.add(_KanjiRadicalItem(radical));
    }

    // Add padding to bottom of the last sliver
    radicalGroups.last = SliverPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      sliver: radicalGroups.last,
    );

    return radicalGroups;
  }

  List<Widget> _getRadicalListByImportance(
    BuildContext context,
    List<KanjiRadical> radicals,
  ) {
    final List<Widget> radicalGroups = [];

    KanjiRadicalImportance currentImportance = KanjiRadicalImportance.none;
    late List<Widget> currentRadicals;
    for (var radical in radicals) {
      if (radical.importance != currentImportance) {
        currentImportance = radical.importance;
        currentRadicals = [];
        late String headerText;
        switch (currentImportance) {
          case KanjiRadicalImportance.none:
            break;
          case KanjiRadicalImportance.top25:
            headerText = 'Top 25%';
            break;
          case KanjiRadicalImportance.top50:
            headerText = 'Top 50%';
            break;
          case KanjiRadicalImportance.top75:
            headerText = 'Top 75%';
            break;
        }
        radicalGroups.add(
          SliverStickyHeader(
            header: Container(
              width: double.infinity,
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.all(12),
              child: SelectionContainer.disabled(
                child: Text(
                  headerText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(currentRadicals),
            ),
          ),
        );
      }

      currentRadicals.add(_KanjiRadicalItem(radical));
    }

    // Add padding to bottom of the last sliver
    radicalGroups.last = SliverPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      sliver: radicalGroups.last,
    );

    return radicalGroups;
  }
}

class _KanjiRadicalItem extends ViewModelWidget<KanjiRadicalsViewModel> {
  final KanjiRadical radical;
  final bool showKangxiId;

  const _KanjiRadicalItem(
    this.radical, {
    this.showKangxiId = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, KanjiRadicalsViewModel viewModel) {
    return InkWell(
      onTap: () => viewModel.openKanjiRadical(radical),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Text(
                radical.radical,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  radical.kangxiId != null && showKangxiId
                      ? Text(
                          '#${radical.kangxiId} - ${radical.meaning}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(radical.meaning, maxLines: 1),
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
            if (radical.position != KanjiRadicalPosition.none)
              KanjiRadicalPositionImage(radical.position),
          ],
        ),
      ),
    );
  }
}
