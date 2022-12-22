import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/hand_writing_canvas.dart';
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
    return ViewModelBuilder<SearchViewModel>.nonReactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<SearchViewModel>(),
      builder: (context, viewModel, child) => Scaffold(body: _Body()),
    );
  }
}

class _Body extends HookViewModelWidget<SearchViewModel> {
  @override
  Widget buildViewModelWidget(BuildContext context, SearchViewModel viewModel) {
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
          Expanded(
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
          if (viewModel.showHandWriting)
            Expanded(
              child: Column(
                children: [
                  const Divider(
                    color: Colors.black,
                    height: 1,
                    thickness: 1,
                  ),
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
                                          offset: cursorPosition + 1));
                                  handWritingController.clear();
                                  viewModel
                                      .searchOnChange(searchController.text);
                                },
                                child: Container(
                                  width: 40,
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
                        const VerticalDivider(
                          color: Colors.black,
                          width: 1,
                          thickness: 1,
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
                        IconButton(
                          onPressed: () {
                            viewModel.toggleHandWriting();
                            keyboardFocusNode.requestFocus();
                          },
                          icon: const Icon(Icons.keyboard),
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                    height: 1,
                    thickness: 1,
                  ),
                  Expanded(
                    child: HandWritingCanvas(
                      onHandWritingChanged: viewModel.recognizeWriting,
                      controller: handWritingController,
                    ),
                  ),
                  const Divider(
                    color: Colors.black,
                    indent: 16,
                    endIndent: 16,
                    height: 1,
                  ),
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
                          onPressed: viewModel.toggleHandWriting,
                          icon: const Icon(Icons.keyboard_hide),
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    return KeyboardActions(
      config: KeyboardActionsConfig(
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
                  icon: const Icon(Icons.gesture),
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: viewModel.showHandWriting
              ? TextField(
                  autofocus: true,
                  readOnly: true,
                  showCursor: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  maxLines: 1,
                  focusNode: handWritingFocusNode,
                  controller: searchController,
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
                        handWritingFocusNode.requestFocus();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                )
              : TextField(
                  autocorrect: false,
                  enableSuggestions: false,
                  enableIMEPersonalizedLearning: false,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  focusNode: keyboardFocusNode,
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
                        keyboardFocusNode.requestFocus();
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
