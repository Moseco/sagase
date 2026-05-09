import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:stacked/stacked.dart';

import '../search_viewmodel.dart';
import 'kanji_components.dart';

class RadicalInput extends ViewModelWidget<SearchViewModel> {
  final TextEditingController searchController;
  final FocusNode keyboardFocusNode;

  const RadicalInput({
    super.key,
    required this.searchController,
    required this.keyboardFocusNode,
  });

  void _insertKanji(String kanji) {
    int cursor = searchController.selection.base.offset;
    if (cursor < 0) cursor = searchController.text.length;
    if (cursor == 0) {
      searchController.text = kanji + searchController.text;
    } else {
      searchController.text = searchController.text.substring(0, cursor) +
          kanji +
          searchController.text.substring(cursor);
    }
    searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: cursor + kanji.length),
    );
  }

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    return Expanded(
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: viewModel.radicalKanjiResult.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              viewModel.selectedRadicals.isEmpty
                                  ? 'Select radicals to find kanji'
                                  : 'No kanji match',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: viewModel.radicalKanjiResult.length,
                          itemBuilder: (context, index) {
                            final kanji = viewModel.radicalKanjiResult[index];
                            return GestureDetector(
                              onTap: () {
                                _insertKanji(kanji.kanji);
                                viewModel.searchOnChange(searchController.text);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 13),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                ),
                                child: Center(child: Text(kanji.kanji)),
                              ),
                            );
                          },
                        ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                IconButton(
                  onPressed: () => viewModel.setInputMode(InputMode.ocr),
                  icon: const Icon(Icons.camera_alt),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                IconButton(
                  onPressed: () =>
                      viewModel.setInputMode(InputMode.handWriting),
                  icon: const Icon(Icons.draw),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                IconButton(
                  onPressed: () {
                    viewModel.setInputMode(InputMode.text);
                    keyboardFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.keyboard),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                IconButton(
                  onPressed: () => viewModel.setInputMode(InputMode.text),
                  icon: const Icon(Icons.close),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          const Expanded(child: _ComponentGrid()),
          const Divider(indent: 16, endIndent: 16, height: 1),
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: viewModel.selectedRadicals.isEmpty
                      ? null
                      : viewModel.clearSelectedRadicals,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear selection'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComponentGrid extends StatelessWidget {
  const _ComponentGrid();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        for (final group in kanjiComponentGroups)
          SliverStickyHeader(
            header: Container(
              width: double.infinity,
              color: Theme.of(context).appBarTheme.backgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                group.$1 == 1 ? '1 stroke' : '${group.$1} strokes',
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final component in group.$2)
                      _ComponentTile(component),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ComponentTile extends ViewModelWidget<SearchViewModel> {
  final KanjiComponent component;

  const _ComponentTile(this.component);

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    final isSelected = viewModel.selectedRadicals.contains(component.search);
    final isViable =
        isSelected || viewModel.viableRadicals.contains(component.search);

    final theme = Theme.of(context);
    final Color background;
    final Color foreground;
    if (isSelected) {
      background = theme.colorScheme.primary;
      foreground = theme.colorScheme.onPrimary;
    } else if (isViable) {
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurface;
    } else {
      background = theme.colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      );
      foreground = theme.colorScheme.onSurface.withValues(alpha: 0.3);
    }

    return GestureDetector(
      onTap: isViable ? () => viewModel.toggleRadical(component.search) : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          component.display,
          style: TextStyle(fontSize: 20, color: foreground),
        ),
      ),
    );
  }
}
