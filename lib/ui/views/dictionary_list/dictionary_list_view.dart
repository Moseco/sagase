import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'dictionary_list_viewmodel.dart';

class DictionaryListView extends StatelessWidget {
  final DictionaryList dictionaryList;

  const DictionaryListView(this.dictionaryList, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DictionaryListViewModel>.reactive(
      viewModelBuilder: () => DictionaryListViewModel(dictionaryList),
      builder: (context, viewModel, child) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(dictionaryList.name),
            actions: dictionaryList is MyDictionaryList
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
            bottom: dictionaryList.vocabLinks.isNotEmpty &&
                    dictionaryList.kanjiLinks.isNotEmpty
                ? const TabBar(tabs: [Tab(text: 'Vocab'), Tab(text: 'Kanji')])
                : null,
          ),
          body: viewModel.loading
              ? const Center(child: CircularProgressIndicator())
              : dictionaryList.vocabLinks.isNotEmpty
                  ? dictionaryList.kanjiLinks.isNotEmpty
                      ? const TabBarView(
                          children: [
                            _VocabList(),
                            _KanjiList(),
                          ],
                        )
                      : const _VocabList()
                  : dictionaryList.kanjiLinks.isNotEmpty
                      ? const _KanjiList()
                      : const _Empty(),
        ),
      ),
    );
  }
}

class _VocabList extends ViewModelWidget<DictionaryListViewModel> {
  const _VocabList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, DictionaryListViewModel viewModel) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemCount: viewModel.dictionaryList.vocabLinks.length,
      itemBuilder: (context, index) {
        final current = viewModel.dictionaryList.vocabLinks.elementAt(index);

        return VocabListItem(
          vocab: current,
          onPressed: () => viewModel.navigateToVocab(current),
        );
      },
    );
  }
}

class _KanjiList extends ViewModelWidget<DictionaryListViewModel> {
  const _KanjiList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, DictionaryListViewModel viewModel) {
    return ListView.separated(
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        indent: 8,
        endIndent: 8,
      ),
      itemCount: viewModel.dictionaryList.kanjiLinks.length,
      itemBuilder: (context, index) {
        final current = viewModel.dictionaryList.kanjiLinks.elementAt(index);

        return KanjiListItem(
          kanji: current,
          onPressed: () => viewModel.navigateToKanji(current),
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({Key? key}) : super(key: key);

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
