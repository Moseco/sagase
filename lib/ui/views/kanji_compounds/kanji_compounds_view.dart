import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';

import 'kanji_compounds_viewmodel.dart';

class KanjiCompoundsView extends StatelessWidget {
  final Kanji kanji;

  const KanjiCompoundsView(this.kanji, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiCompoundsViewModel>.nonReactive(
      viewModelBuilder: () => KanjiCompoundsViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: Text('${kanji.kanji} Compounds')),
        body: ListView.separated(
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 8,
            endIndent: 8,
          ),
          itemCount: kanji.compounds.length,
          itemBuilder: (context, index) => VocabListItem(
            vocab: kanji.compounds.elementAt(index),
            onPressed: () =>
                viewModel.navigateToVocab(kanji.compounds.elementAt(index)),
          ),
        ),
      ),
    );
  }
}
