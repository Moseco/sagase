import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

import 'home_viewmodel.dart';

class HomeView extends StatelessWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<HomeViewModel>.reactive(
      viewModelBuilder: () => HomeViewModel(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: const Text('Sagase'),
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
              const _SearchTextField(),
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

class _SearchTextField extends HookViewModelWidget<HomeViewModel> {
  const _SearchTextField({Key? key}) : super(key: key);
  @override
  Widget buildViewModelWidget(BuildContext context, HomeViewModel viewModel) {
    var searchController = useTextEditingController();
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextField(
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: 'Search',
          border: const OutlineInputBorder(borderSide: BorderSide()),
          suffixIcon: IconButton(
            onPressed: () {
              viewModel.searchOnChange('');
              searchController.clear();
            },
            icon: const Icon(Icons.clear),
          ),
        ),
        controller: searchController,
        onChanged: viewModel.searchOnChange,
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
        vocab.kanjiReadingPairs[0].kanjiWritings != null
            ? '${vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji}【${vocab.kanjiReadingPairs[0].readings[0].reading}】'
            : vocab.kanjiReadingPairs[0].readings[0].reading,
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
