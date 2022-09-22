import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

import 'search_viewmodel.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SearchViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<SearchViewModel>(),
      builder: (context, viewModel, child) => Scaffold(
        body: HomeHeader(
          title: const _SearchTextField(),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      ),
    );
  }
}

class _SearchTextField extends HookViewModelWidget<SearchViewModel> {
  const _SearchTextField({Key? key}) : super(key: key);
  @override
  Widget buildViewModelWidget(BuildContext context, SearchViewModel viewModel) {
    var searchController =
        useTextEditingController(text: viewModel.searchString);
    var searchFocusNode = useFocusNode();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        autocorrect: false,
        enableSuggestions: false,
        enableIMEPersonalizedLearning: false,
        maxLines: 1,
        textInputAction: TextInputAction.done,
        focusNode: searchFocusNode,
        controller: searchController,
        onChanged: viewModel.searchOnChange,
        decoration: InputDecoration(
          hintText: 'Search',
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: IconButton(
            onPressed: () {
              viewModel.searchOnChange('');
              searchController.clear();
              searchFocusNode.requestFocus();
            },
            icon: const Icon(Icons.clear),
          ),
        ),
      ),
    );
  }
}

class _VocabSearchItem extends ViewModelWidget<SearchViewModel> {
  final Vocab vocab;

  const _VocabSearchItem(this.vocab, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
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

class _KanjiSearchItem extends ViewModelWidget<SearchViewModel> {
  final Kanji kanji;

  const _KanjiSearchItem(this.kanji, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
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
