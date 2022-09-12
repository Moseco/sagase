import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:stacked/stacked.dart';

import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: kDebugMode
              ? [
                  IconButton(
                    onPressed: viewModel.navigateToDev,
                    icon: const Icon(Icons.bug_report),
                  ),
                ]
              : null,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search',
                    border: OutlineInputBorder(borderSide: BorderSide()),
                  ),
                  onChanged: viewModel.searchOnChange,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: viewModel.searchResult.length,
                  itemBuilder: (context, index) {
                    final current = viewModel.searchResult[index];
                    if (current is Vocab) {
                      return _VocabSearchItem(current);
                    } else {
                      return _KanjiSearchItem(current as Kanji);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VocabSearchItem extends ViewModelWidget<HomeViewModel> {
  final Vocab vocab;

  const _VocabSearchItem(this.vocab, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return ListTile(
      title: Text(
        vocab.kanjiReadingPairs.first.kanjiWritings?.first.kanji ??
            vocab.kanjiReadingPairs.first.readings.first.reading,
        maxLines: 1,
      ),
      subtitle: Text(
        vocab.definitions[0].definition,
        maxLines: 1,
      ),
      onTap: () => viewModel.navigateToVocab(vocab),
    );
  }
}

class _KanjiSearchItem extends ViewModelWidget<HomeViewModel> {
  final Kanji kanji;

  const _KanjiSearchItem(this.kanji, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, HomeViewModel viewModel) {
    return ListTile(
      title: Text(kanji.kanji),
      subtitle: Text(
        kanji.meanings ?? '',
        maxLines: 1,
      ),
      onTap: () => viewModel.navigateToKanji(kanji),
    );
  }
}
