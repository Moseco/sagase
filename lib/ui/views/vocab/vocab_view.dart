import 'package:flutter/material.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:stacked/stacked.dart';

import 'vocab_viewmodel.dart';

class VocabView extends StatelessWidget {
  final Vocab vocab;

  const VocabView(this.vocab, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<VocabViewModel>.reactive(
      viewModelBuilder: () => VocabViewModel(vocab),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            vocab.kanjiReadingPairs[0].kanjiWritings?[0].kanji ??
                vocab.kanjiReadingPairs[0].readings[0].reading,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PrimaryKanjiReadingPair(vocab.kanjiReadingPairs[0]),
              if (vocab.commonWord) const Text('Common word'),
              const Text(
                'All kanji and reading',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                itemCount: vocab.kanjiReadingPairs.length,
                itemBuilder: (context, index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vocab.kanjiReadingPairs[index].kanjiWritings != null
                            ? vocab.kanjiReadingPairs[index].kanjiWritings!
                                .map((e) => e.kanji)
                                .toList()
                                .toString()
                            : 'No Kanji',
                      ),
                      Text(
                        vocab.kanjiReadingPairs[index].readings
                            .map((e) => e.reading)
                            .toList()
                            .toString(),
                      ),
                    ],
                  );
                },
              ),
              const Text(
                'Definition',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                primary: false,
                padding: EdgeInsets.zero,
                itemCount: vocab.definitions.length,
                itemBuilder: (context, index) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}: ${vocab.definitions[index].definition}',
                    ),
                    if (vocab.definitions[index].additionalInfo != null)
                      Text(
                        vocab.definitions[index].additionalInfo!,
                        style: const TextStyle(color: Colors.black45),
                      ),
                    if (vocab.definitions[index].pos != null)
                      Text(
                        vocab.definitions[index].pos.toString(),
                        style: const TextStyle(color: Colors.black45),
                      ),
                  ],
                ),
              ),
              if (viewModel.kanjiList.isNotEmpty) const _KanjiList(),
              const Text(
                'Examples',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (vocab.examples != null)
                ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: vocab.examples!.length,
                  itemBuilder: (context, index) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Example for definition ${vocab.examples![index].index + 1}',
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      Text(vocab.examples![index].japanese),
                      Text(vocab.examples![index].english),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryKanjiReadingPair extends StatelessWidget {
  final KanjiReadingPair pair;

  const _PrimaryKanjiReadingPair(this.pair, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pair.kanjiWritings != null) {
      return Text(
        '${pair.kanjiWritings![0].kanji}【${pair.readings[0].reading}】',
        style: const TextStyle(fontSize: 32),
      );
    } else {
      return Text(
        pair.readings[0].reading,
        style: const TextStyle(fontSize: 32),
      );
    }
  }
}

class _KanjiList extends ViewModelWidget<VocabViewModel> {
  const _KanjiList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kanji in vocab',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ListView.builder(
          shrinkWrap: true,
          primary: false,
          padding: EdgeInsets.zero,
          itemCount: viewModel.kanjiList.length,
          itemBuilder: (context, index) {
            final current = viewModel.kanjiList[index];
            if (viewModel.kanjiLoaded) {
              return ListTile(
                title: Text(current.kanji),
                subtitle: Text(
                  current.meanings ?? 'NO MEANING',
                  maxLines: 1,
                ),
                onTap: () => viewModel.navigateToKanji(current),
              );
            } else {
              return ListTile(title: Text(current.kanji));
            }
          },
        ),
      ],
    );
  }
}
