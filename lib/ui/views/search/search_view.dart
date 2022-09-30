import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:sagase/ui/widgets/kanji_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
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
          child: ListView.separated(
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              color: Colors.grey,
              indent: 8,
              endIndent: 8,
            ),
            padding: EdgeInsets.zero,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: viewModel.searchResult.length,
            itemBuilder: (context, index) {
              final current = viewModel.searchResult[index];
              if (current is Vocab) {
                return VocabListItem(
                  vocab: current,
                  onPressed: () => viewModel.navigateToVocab(current),
                );
              } else {
                return KanjiListItem(
                  kanji: current as Kanji,
                  onPressed: () => viewModel.navigateToKanji(current),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _SearchTextField extends HookViewModelWidget<SearchViewModel> {
  const _SearchTextField({Key? key}) : super(key: key, reactive: false);
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
