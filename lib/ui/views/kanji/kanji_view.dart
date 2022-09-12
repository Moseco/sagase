import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:stacked/stacked.dart';

import 'kanji_viewmodel.dart';

class KanjiView extends StatelessWidget {
  final Kanji kanji;

  const KanjiView(this.kanji, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<KanjiViewModel>.reactive(
      viewModelBuilder: () => KanjiViewModel(kanji),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(title: const Text('Kanji Item')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kanji.kanji,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Meaning',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(kanji.meanings ?? 'No meaning'),
              Text(
                'Radical: ${kanji.radical}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (kanji.grade != 255)
                Text(
                  'Grade: ${kanji.grade}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              Text(
                'Stroke count: ${kanji.strokeCount}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (kanji.variants.isNotEmpty)
                const Text(
                  'Variants',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (kanji.variants.isNotEmpty && viewModel.linksLoaded)
                ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: kanji.variants.length,
                  itemBuilder: (context, index) {
                    return Text(kanji.variants.elementAt(index).kanji);
                  },
                ),
              if (kanji.frequency != null)
                Text(
                  'Frequency: ${kanji.frequency}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              if (kanji.jlpt != 255)
                Text(
                  'JLPT: N${kanji.jlpt}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              const Text(
                'On Readings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(kanji.onReadings?.toString() ?? 'No readings'),
              const Text(
                'Kun Readings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(kanji.kunReadings?.toString() ?? 'No readings'),
              const Text(
                'Nanori',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(kanji.nanori?.toString() ?? 'No readings'),
              if (kanji.compounds.isNotEmpty)
                const Text(
                  'Compounds',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              if (kanji.compounds.isNotEmpty && viewModel.linksLoaded)
                ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: kanji.compounds.length,
                  itemBuilder: (context, index) {
                    return Text(
                      kanji.compounds
                              .elementAt(index)
                              .kanjiReadingPairs[0]
                              .kanjiWritings?[0]
                              .kanji ??
                          kanji.compounds
                              .elementAt(index)
                              .kanjiReadingPairs[0]
                              .readings[0]
                              .reading,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
