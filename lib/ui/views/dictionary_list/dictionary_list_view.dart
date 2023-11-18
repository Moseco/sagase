import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(viewModel.dictionaryList.name),
          actions: viewModel.dictionaryList is MyDictionaryList
              ? [
                  IconButton(
                    onPressed: viewModel.renameMyList,
                    icon: const Icon(Icons.edit),
                  ),
                  IconButton(
                    onPressed: viewModel.deleteMyList,
                    icon: const Icon(Icons.delete),
                  ),
                ]
              : null,
          bottom: viewModel.dictionaryList.getVocab().isNotEmpty &&
                  viewModel.dictionaryList.getKanji().isNotEmpty
              ? const TabBar(tabs: [Tab(text: 'Vocab'), Tab(text: 'Kanji')])
              : null,
        ),
        body: viewModel.isBusy
            ? const Center(child: CircularProgressIndicator())
            : viewModel.vocab.isNotEmpty
                ? viewModel.kanji.isNotEmpty
                    ? const TabBarView(
                        children: [
                          _VocabList(),
                          _KanjiList(),
                        ],
                      )
                    : const _VocabList()
                : viewModel.kanji.isNotEmpty
                    ? const _KanjiList()
                    : const _Empty(),
      ),
    );
  }
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
      itemCount: viewModel.vocab.length,
      itemBuilder: (context, index) {
        final current = viewModel.vocab[index];

        return VocabListItem(
          vocab: current,
          onPressed: () => viewModel.navigateToVocab(current),
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
      itemCount: viewModel.kanji.length,
      itemBuilder: (context, index) {
        final current = viewModel.kanji[index];

        return KanjiListItem(
          kanji: current,
          onPressed: () => viewModel.navigateToKanji(current),
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
                text: 'from any vocab or kanji page.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
