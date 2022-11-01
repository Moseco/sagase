import 'package:flutter/material.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'dictionary_list_viewmodel.dart';

class DictionaryListView extends StatelessWidget {
  final DictionaryList list;

  const DictionaryListView(this.list, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DictionaryListViewModel>.reactive(
      viewModelBuilder: () => DictionaryListViewModel(list),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: Text(list.name)),
        body: viewModel.loading
            ? const Center(child: CircularProgressIndicator())
            : list.vocab.isNotEmpty
                ? ListView.separated(
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Colors.grey,
                      indent: 8,
                      endIndent: 8,
                    ),
                    itemCount: list.vocab.length,
                    itemBuilder: (context, index) {
                      final current = list.vocab.elementAt(index);

                      return VocabListItem(
                        vocab: current,
                        onPressed: () => viewModel.navigateToVocab(current),
                      );
                    },
                  )
                : ListView.separated(
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Colors.grey,
                      indent: 8,
                      endIndent: 8,
                    ),
                    itemCount: list.kanji.length,
                    itemBuilder: (context, index) {
                      final current = list.kanji.elementAt(index);

                      return KanjiListItem(
                        kanji: current,
                        onPressed: () => viewModel.navigateToKanji(current),
                      );
                    },
                  ),
      ),
    );
  }
}
