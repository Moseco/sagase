import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/hand_writing_canvas.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

import 'search_viewmodel.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SearchViewModel>.nonReactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<SearchViewModel>(),
      builder: (context, viewModel, child) => Scaffold(body: _Body()),
    );
  }
}

class _Body extends StackedHookView<SearchViewModel> {
  @override
  Widget builder(BuildContext context, SearchViewModel viewModel) {
    final searchController =
        useTextEditingController(text: viewModel.searchString);
    final keyboardFocusNode = useFocusNode();
    final handWritingFocusNode = useFocusNode();
    final handWritingController = use(const HandWritingControllerHook());

    return HomeHeader(
      title: _SearchTextField(
        searchController: searchController,
        keyboardFocusNode: keyboardFocusNode,
        handWritingFocusNode: handWritingFocusNode,
      ),
      child: Column(
        children: [
          viewModel.searchResult == null
              ? _SearchHistory(searchController)
              : const _SearchResults(),
          if (viewModel.showHandWriting)
            Expanded(
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: viewModel.handWritingResult.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  int cursorPosition =
                                      searchController.selection.base.offset;
                                  if (cursorPosition == 0) {
                                    searchController.text =
                                        viewModel.handWritingResult[index] +
                                            searchController.text;
                                  } else {
                                    searchController.text = searchController
                                            .text
                                            .substring(0, cursorPosition) +
                                        viewModel.handWritingResult[index] +
                                        searchController.text
                                            .substring(cursorPosition);
                                  }

                                  searchController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                    offset: cursorPosition +
                                        viewModel
                                            .handWritingResult[index].length,
                                  ));
                                  handWritingController.clear();
                                  viewModel
                                      .searchOnChange(searchController.text);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 13,
                                  ),
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      right: BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      viewModel.handWritingResult[index],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        IconButton(
                          onPressed: () {
                            viewModel.toggleHandWriting();
                            keyboardFocusNode.requestFocus();
                          },
                          icon: const Icon(Icons.text_fields),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        IconButton(
                          onPressed: viewModel.toggleHandWriting,
                          icon: const Icon(Icons.keyboard_hide),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1),
                  Expanded(
                    child: HandWritingCanvas(
                      onHandWritingChanged: viewModel.recognizeWriting,
                      controller: handWritingController,
                    ),
                  ),
                  const Divider(indent: 16, endIndent: 16, height: 1),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () => handWritingController.undo(),
                          icon: const Icon(Icons.undo),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        IconButton(
                          onPressed: () => handWritingController.clear(),
                          icon: const Icon(Icons.delete),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        IconButton(
                          onPressed: () {
                            int cursorPosition =
                                searchController.selection.base.offset;
                            if (cursorPosition != 0) {
                              searchController.text = searchController.text
                                      .substring(0, cursorPosition - 1) +
                                  searchController.text
                                      .substring(cursorPosition);

                              searchController.selection =
                                  TextSelection.fromPosition(
                                      TextPosition(offset: cursorPosition - 1));
                              viewModel.searchOnChange(searchController.text);
                            }
                          },
                          icon: const Icon(Icons.backspace),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SearchTextField extends ViewModelWidget<SearchViewModel> {
  final TextEditingController searchController;
  final FocusNode keyboardFocusNode;
  final FocusNode handWritingFocusNode;

  const _SearchTextField({
    required this.searchController,
    required this.keyboardFocusNode,
    required this.handWritingFocusNode,
  });

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
        keyboardBarColor:
            MediaQuery.of(context).platformBrightness == Brightness.light
                ? const Color(0xFFD1D4D9)
                : const Color(0xFF2B2B2B),
        actions: [
          KeyboardActionsItem(
            focusNode: keyboardFocusNode,
            displayArrows: false,
            toolbarButtons: [
              // Open hand writing and dismiss keyboard
              (node) {
                return IconButton(
                  onPressed: () {
                    node.unfocus();
                    viewModel.toggleHandWriting();
                    handWritingFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.draw),
                );
              },
              // Dismiss keyboard
              (node) {
                return IconButton(
                  onPressed: node.unfocus,
                  icon: const Icon(Icons.keyboard_hide),
                );
              },
            ],
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 4),
        child: Center(
          child: Row(
            children: [
              Expanded(
                child: viewModel.showHandWriting
                    ? TextField(
                        autofocus: true,
                        readOnly: true,
                        showCursor: true,
                        autocorrect: false,
                        enableIMEPersonalizedLearning: false,
                        maxLines: 1,
                        focusNode: handWritingFocusNode,
                        controller: searchController,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1000),
                          FilteringTextInputFormatter.deny(
                            RegExp(r'‘|’'),
                            replacementString: '\'',
                          ),
                          FilteringTextInputFormatter.deny(
                            RegExp(r'“|”'),
                            replacementString: '"',
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Search',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          suffixIcon: IconButton(
                            onPressed: () {
                              viewModel.searchOnChange('');
                              searchController.clear();
                              handWritingFocusNode.requestFocus();
                            },
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                        ),
                      )
                    : TextField(
                        autocorrect: false,
                        enableIMEPersonalizedLearning: false,
                        maxLines: 1,
                        textInputAction: TextInputAction.done,
                        focusNode: keyboardFocusNode,
                        controller: searchController,
                        onChanged: viewModel.searchOnChange,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(1000),
                          FilteringTextInputFormatter.deny(
                            RegExp(r'‘|’'),
                            replacementString: '\'',
                          ),
                          FilteringTextInputFormatter.deny(
                            RegExp(r'“|”'),
                            replacementString: '"',
                          ),
                        ],
                        decoration: InputDecoration(
                          hintText: 'Search',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                            ),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).scaffoldBackgroundColor,
                          suffixIcon: IconButton(
                            onPressed: () {
                              viewModel.searchOnChange('');
                              searchController.clear();
                              keyboardFocusNode.requestFocus();
                            },
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).iconTheme.color,
                            ),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                          ),
                        ),
                      ),
              ),
              IconButton(
                onPressed: viewModel.setSearchFilter,
                icon: const Icon(Icons.tune, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends ViewModelWidget<SearchViewModel> {
  const _SearchResults();

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    // If no results, show message
    if (viewModel.searchResult!.isEmpty) {
      if (viewModel.promptAnalysis) {
        return Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'No results found.\nLooks like your query may be a sentence or phrase.',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => viewModel.navigateToTextAnalysis(
                      text: viewModel.searchString,
                    ),
                    child: const Text('Analyze text instead'),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        return const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No results found',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }
    }

    // Show results
    return Expanded(
      child: ListView.separated(
        key: UniqueKey(),
        separatorBuilder: (_, __) => const Divider(
          height: 1,
          indent: 8,
          endIndent: 8,
        ),
        padding: EdgeInsets.zero,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        itemCount: viewModel.searchResult!.length,
        itemBuilder: (context, index) {
          final current = viewModel.searchResult![index];
          if (current is Vocab) {
            return VocabListItem(
              vocab: current,
              onPressed: () => viewModel.navigateToVocab(current),
            );
          } else {
            return KanjiListItemLarge(
              kanji: current as Kanji,
              onPressed: () => viewModel.navigateToKanji(current),
            );
          }
        },
      ),
    );
  }
}

class _SearchHistory extends ViewModelWidget<SearchViewModel> {
  final TextEditingController searchController;

  const _SearchHistory(this.searchController);

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    return Expanded(
      child: Column(
        children: [
          ListTile(
            title: const Text(
              'Recent searches',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('Analyze'),
                  onPressed: viewModel.navigateToTextAnalysis,
                ),
                TextButton.icon(
                  icon: const Icon(Icons.paste),
                  label: const Text('Paste'),
                  onPressed: () async {
                    final cdata = await Clipboard.getData(Clipboard.kTextPlain);
                    if (cdata?.text != null) {
                      searchController.text = cdata!.text!;
                      searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: cdata.text!.length));
                      viewModel.searchOnChange(cdata.text!);
                    }
                  },
                ),
              ],
            ),
          ),
          viewModel.searchHistory.isEmpty
              ? const Expanded(
                  child: Column(
                    children: [
                      Spacer(),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Try searching for vocab and kanji using romaji, kana, kanji, and hand writing recognition. You can also analyze whole Japanese sentences.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Spacer(),
                    ],
                  ),
                )
              : Expanded(
                  child: ListView.separated(
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 8,
                      endIndent: 8,
                    ),
                    padding: EdgeInsets.zero,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: viewModel.searchHistory.length,
                    itemBuilder: (context, index) {
                      final current = viewModel.searchHistory[index];
                      return Dismissible(
                        key: ObjectKey(current),
                        background: Container(color: Colors.red),
                        onDismissed: (DismissDirection direction) {
                          viewModel.searchHistoryItemDeleted(current);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.search),
                          title: Text(current.searchText),
                          onTap: () {
                            searchController.text = current.searchText;
                            searchController.selection =
                                TextSelection.fromPosition(TextPosition(
                                    offset: current.searchText.length));
                            viewModel.searchHistoryItemSelected(current);
                          },
                        ),
                      );
                    },
                  ),
                )
        ],
      ),
    );
  }
}
