import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_compounds_viewmodel.dart';

class KanjiCompoundsView extends StackedView<KanjiCompoundsViewModel> {
  final Kanji kanji;

  const KanjiCompoundsView(this.kanji, {super.key});

  @override
  KanjiCompoundsViewModel viewModelBuilder(BuildContext context) =>
      KanjiCompoundsViewModel(kanji);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(title: Text('${kanji.kanji} Compounds')),
      body: SafeArea(
        bottom: false,
        child: viewModel.isBusy
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                itemCount: viewModel.vocabList.length,
                itemBuilder: (context, index) => VocabListItem(
                  vocab: viewModel.vocabList[index],
                  onPressed: () =>
                      viewModel.navigateToVocab(viewModel.vocabList[index]),
                ),
              ),
      ),
    );
  }
}
