import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:sagase/ui/widgets/proper_noun_list_item.dart';
import 'package:sagase/utils/enum_utils.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/hand_writing_canvas.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

import 'search_viewmodel.dart';
import 'widgets/analysis_prompt.dart';
import 'widgets/hand_writing_input.dart';
import 'widgets/ocr_widget.dart';

class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<SearchViewModel>.nonReactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<SearchViewModel>(),
      builder: (context, viewModel, child) => _SearchView(),
    );
  }
}

class _SearchView extends StackedHookView<SearchViewModel> {
  @override
  Widget builder(BuildContext context, SearchViewModel viewModel) {
    final searchController =
        useTextEditingController(text: viewModel.searchString);
    final keyboardFocusNode = useFocusNode();
    final handWritingFocusNode = useFocusNode();
    final handWritingController = use(const HandWritingControllerHook());

    return Scaffold(
      floatingActionButton:
          keyboardFocusNode.hasFocus || viewModel.inputMode != InputMode.text
              ? null
              : FloatingActionButton(
                  onPressed: () {
                    keyboardFocusNode.requestFocus();
                    viewModel.rebuildUi();
                  },
                  backgroundColor: Colors.deepPurple,
                  child: const Icon(Icons.search),
                ),
      body: HomeHeader(
        title: _SearchTextField(
          searchController: searchController,
          keyboardFocusNode: keyboardFocusNode,
          handWritingFocusNode: handWritingFocusNode,
        ),
        child: Column(
          children: [
            if (viewModel.promptAnalysis) AnalysisPrompt(),
            viewModel.searchResult == null
                ? _SearchHistory(searchController)
                : const _SearchResults(),
            if (viewModel.inputMode == InputMode.handWriting)
              HandWritingInput(
                searchController: searchController,
                handWritingController: handWritingController,
                keyboardFocusNode: keyboardFocusNode,
              ),
            if (viewModel.inputMode == InputMode.ocr)
              OcrWidget(
                searchController: searchController,
                handWritingController: handWritingController,
                keyboardFocusNode: keyboardFocusNode,
              ),
          ],
        ),
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
              // Open OCR and dismiss keyboard
              (node) {
                return IconButton(
                  onPressed: () {
                    node.unfocus();
                    viewModel.setInputMode(InputMode.ocr);
                    handWritingFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.camera_alt),
                );
              },
              // Open hand writing and dismiss keyboard
              (node) {
                return IconButton(
                  onPressed: () {
                    node.unfocus();
                    viewModel.setInputMode(InputMode.handWriting);
                    handWritingFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.draw),
                );
              },
              // Dismiss keyboard
              (node) {
                return IconButton(
                  onPressed: () {
                    node.unfocus();
                    viewModel.rebuildUi();
                  },
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
                child: TextField(
                  autofocus: viewModel.inputMode != InputMode.text,
                  readOnly: viewModel.inputMode != InputMode.text,
                  showCursor: true,
                  autocorrect: false,
                  enableIMEPersonalizedLearning: false,
                  maxLines: 1,
                  textInputAction: viewModel.inputMode != InputMode.text
                      ? null
                      : TextInputAction.search,
                  focusNode: viewModel.inputMode != InputMode.text
                      ? handWritingFocusNode
                      : keyboardFocusNode,
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
                    hintText: viewModel.searchFilter.displayTitle,
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
                        viewModel.inputMode != InputMode.text
                            ? handWritingFocusNode.requestFocus()
                            : keyboardFocusNode.requestFocus();
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
    if (viewModel.searchResult!.isEmpty) {
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
          } else if (current is Kanji) {
            return KanjiListItemLarge(
              kanji: current,
              onPressed: () => viewModel.navigateToKanji(current),
            );
          } else {
            return ProperNounListItem(
              properNoun: current as ProperNoun,
              onPressed: () => viewModel.navigateToProperNoun(current),
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
                      final text = cdata!.text!.replaceAll('\n', '');
                      searchController.text = text;
                      searchController.selection = TextSelection.fromPosition(
                          TextPosition(offset: text.length));
                      viewModel.searchOnChange(text);
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
                          title: Text(
                            current.searchText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
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
