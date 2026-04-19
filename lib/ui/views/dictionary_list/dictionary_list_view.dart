import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/grammar_list_item.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'dictionary_list_viewmodel.dart';

class DictionaryListView extends StackedView<DictionaryListViewModel> {
  final DictionaryList dictionaryList;

  const DictionaryListView(this.dictionaryList, {super.key});

  @override
  DictionaryListViewModel viewModelBuilder(BuildContext context) =>
      DictionaryListViewModel(dictionaryList);

  @override
  Widget builder(context, viewModel, child) {
    final tabs = <_DictionaryListTab>[];
    if (viewModel.loaded) {
      if (viewModel.vocabList!.isNotEmpty) tabs.add(_DictionaryListTab.vocab);
      if (viewModel.kanjiList!.isNotEmpty) tabs.add(_DictionaryListTab.kanji);
      if (viewModel.grammarList!.isNotEmpty) {
        tabs.add(_DictionaryListTab.grammar);
      }
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(viewModel.dictionaryList.name),
          actions: viewModel.dictionaryList is MyDictionaryList
              ? [
                  PopupMenuButton<PopupMenuItemType>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: PopupMenuItemType.rename,
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: PopupMenuItemType.delete,
                        child: Text('Delete'),
                      ),
                      const PopupMenuItem(
                        value: PopupMenuItemType.share,
                        child: Text('Share'),
                      ),
                    ],
                    onSelected: viewModel.handlePopupMenuButton,
                  ),
                ]
              : null,
          bottom: tabs.length > 1
              ? TabBar(
                  tabs: tabs
                      .map((tab) => Tab(text: tab.label))
                      .toList(growable: false),
                )
              : null,
        ),
        body: SafeArea(
          bottom: false,
          child: !viewModel.loaded
              ? const Center(child: CircularProgressIndicator())
              : tabs.isEmpty
                  ? const _Empty()
                  : tabs.length == 1
                      ? _buildTabContent(tabs.first)
                      : TabBarView(
                          children: tabs
                              .map(_buildTabContent)
                              .toList(growable: false),
                        ),
        ),
      ),
    );
  }

  Widget _buildTabContent(_DictionaryListTab tab) {
    switch (tab) {
      case _DictionaryListTab.vocab:
        return const _VocabList();
      case _DictionaryListTab.kanji:
        return const _KanjiList();
      case _DictionaryListTab.grammar:
        return const _GrammarList();
    }
  }
}

enum _DictionaryListTab {
  vocab('Vocab'),
  kanji('Kanji'),
  grammar('Grammar');

  final String label;
  const _DictionaryListTab(this.label);
}

class _VocabList extends ViewModelWidget<DictionaryListViewModel> {
  const _VocabList();

  @override
  Widget build(BuildContext context, DictionaryListViewModel viewModel) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemCount: viewModel.vocabList!.length,
      itemBuilder: (context, index) {
        final current = viewModel.vocabList![index];

        return VocabListItem(
          vocab: current,
          onPressed: () => viewModel.navigateToVocab(current, index),
        );
      },
    );
  }
}

class _KanjiList extends ViewModelWidget<DictionaryListViewModel> {
  const _KanjiList();

  @override
  Widget build(BuildContext context, DictionaryListViewModel viewModel) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemCount: viewModel.kanjiList!.length,
      itemBuilder: (context, index) {
        final current = viewModel.kanjiList![index];

        return KanjiListItem(
          kanji: current,
          onPressed: () => viewModel.navigateToKanji(current, index),
        );
      },
    );
  }
}

class _GrammarList extends ViewModelWidget<DictionaryListViewModel> {
  const _GrammarList();

  @override
  Widget build(BuildContext context, DictionaryListViewModel viewModel) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemCount: viewModel.grammarList!.length,
      itemBuilder: (context, index) {
        final current = viewModel.grammarList![index];

        return GrammarListItem(
          grammar: current,
          onPressed: () => viewModel.navigateToGrammar(current, index),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text:
                    'This list is currently empty. You can add to it by pressing',
              ),
              WidgetSpan(child: Icon(Icons.star_border)),
              TextSpan(
                text: 'from any vocab, kanji, or grammar page.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
