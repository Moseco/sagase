import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/radical_position_image.dart';
import 'package:stacked/stacked.dart';

import 'radicals_viewmodel.dart';

class RadicalsView extends StackedView<RadicalsViewModel> {
  const RadicalsView({super.key});

  @override
  RadicalsViewModel viewModelBuilder(context) => RadicalsViewModel();

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
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
      body: viewModel.radicals == null
          ? Container()
          : CustomScrollView(
              key: UniqueKey(),
              slivers: viewModel.radicalSorting == RadicalSorting.important
                  ? _getRadicalListByImportance(
                      context,
                      viewModel.radicals!,
                    )
                  : _getRadicalListByStrokeCount(
                      context,
                      viewModel.radicals!,
                    ),
            ),
    );
  }

  List<Widget> _getRadicalListByStrokeCount(
    BuildContext context,
    List<Radical> radicals,
  ) {
    final padding = MediaQuery.of(context).padding;

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
                child: Padding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                  ),
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
            ),
            sliver: SliverPadding(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(currentRadicals),
              ),
            ),
          ),
        );
      }

      currentRadicals.add(_RadicalItem(radical));
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
    List<Radical> radicals,
  ) {
    final padding = MediaQuery.of(context).padding;

    final List<Widget> radicalGroups = [];

    RadicalImportance? currentImportance;
    late List<Widget> currentRadicals;
    for (var radical in radicals) {
      if (radical.importance != currentImportance) {
        currentImportance = radical.importance;
        currentRadicals = [];
        radicalGroups.add(
          SliverStickyHeader(
            header: Container(
              width: double.infinity,
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.all(12),
              child: SelectionContainer.disabled(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: padding.left,
                    right: padding.right,
                  ),
                  child: Text(
                    currentImportance!.displayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            sliver: SliverPadding(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate(currentRadicals),
              ),
            ),
          ),
        );
      }

      currentRadicals.add(_RadicalItem(radical));
    }

    // Add padding to bottom of the last sliver
    radicalGroups.last = SliverPadding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      sliver: radicalGroups.last,
    );

    return radicalGroups;
  }
}

class _RadicalItem extends ViewModelWidget<RadicalsViewModel> {
  final Radical radical;

  const _RadicalItem(this.radical);

  @override
  Widget build(BuildContext context, RadicalsViewModel viewModel) {
    return InkWell(
      onTap: () => viewModel.openRadical(radical),
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
                  radical.kangxiId != null
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
            if (radical.position != null)
              RadicalPositionImage(radical.position!),
          ],
        ),
      ),
    );
  }
}
