import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_compounds_viewmodel.dart';

class KanjiCompoundsView extends StatelessWidget {
  final Kanji kanji;

  const KanjiCompoundsView(this.kanji, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiCompoundsViewModel>.reactive(
      viewModelBuilder: () => KanjiCompoundsViewModel(kanji),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: Text('${kanji.kanji} Compounds')),
        body: viewModel.vocabList == null
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 8,
                  endIndent: 8,
                ),
                itemCount: viewModel.vocabList!.length,
                itemBuilder: (context, index) => VocabListItem(
                  vocab: viewModel.vocabList![index],
                  onPressed: () =>
                      viewModel.navigateToVocab(viewModel.vocabList![index]),
                ),
              ),
      ),
    );
  }
}
