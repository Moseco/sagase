import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_list_viewmodel.dart';

class KanjiListView extends StackedView<KanjiListViewModel> {
  final String title;
  final List<Kanji> kanjiList;

  const KanjiListView({
    required this.title,
    required this.kanjiList,
    super.key,
  });

  @override
  KanjiListViewModel viewModelBuilder(context) => KanjiListViewModel(kanjiList);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView.separated(
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 8,
          endIndent: 8,
        ),
        itemCount: kanjiList.length,
        itemBuilder: (context, index) {
          final current = kanjiList[index];
          return KanjiListItem(
            kanji: current,
            onPressed: () => viewModel.navigateToKanji(current),
          );
        },
      ),
    );
  }
}
