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
          bottom: viewModel.loaded &&
                  viewModel.vocabList!.isNotEmpty &&
                  viewModel.kanjiList!.isNotEmpty
              ? const TabBar(tabs: [Tab(text: 'Vocab'), Tab(text: 'Kanji')])
              : null,
        ),
        body: SafeArea(
          bottom: false,
          child: !viewModel.loaded
              ? const Center(child: CircularProgressIndicator())
              : viewModel.vocabList!.isNotEmpty
                  ? viewModel.kanjiList!.isNotEmpty
                      ? const TabBarView(
                          children: [
                            _VocabList(),
                            _KanjiList(),
                          ],
                        )
                      : const _VocabList()
                  : viewModel.kanjiList!.isNotEmpty
                      ? const _KanjiList()
                      : const _Empty(),
        ),
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
      itemCount: viewModel.vocabList!.length,
      itemBuilder: (context, index) {
        final current = viewModel.vocabList![index];

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
      itemCount: viewModel.kanjiList!.length,
      itemBuilder: (context, index) {
        final current = viewModel.kanjiList![index];

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
