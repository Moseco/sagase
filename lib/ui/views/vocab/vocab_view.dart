import 'package:flutter/material.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:stacked/stacked.dart';

import 'vocab_viewmodel.dart';

class VocabView extends StatelessWidget {
  final Vocab vocab;

  const VocabView({required this.vocab, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<VocabViewModel>.reactive(
      viewModelBuilder: () => VocabViewModel(vocab),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: const Text('Vocab Item')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (vocab.commonWord) const Text('Is common'),
              const Text(
                'Kanji and reading',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                primary: false,
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
              const Text(
                'Examples',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (vocab.examples != null)
                ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: vocab.examples!.length,
                  itemBuilder: (context, index) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Example for definition ${index + 1}'),
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
