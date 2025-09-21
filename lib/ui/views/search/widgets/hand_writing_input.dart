import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/hand_writing_canvas.dart';
import 'package:stacked/stacked.dart';

import '../search_viewmodel.dart';

class HandWritingInput extends ViewModelWidget<SearchViewModel> {
  final TextEditingController searchController;
  final HandWritingController handWritingController;
  final FocusNode keyboardFocusNode;

  const HandWritingInput({
    super.key,
    required this.searchController,
    required this.handWritingController,
    required this.keyboardFocusNode,
  });

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    return Expanded(
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
                            searchController.text = searchController.text
                                    .substring(0, cursorPosition) +
                                viewModel.handWritingResult[index] +
                                searchController.text.substring(cursorPosition);
                          }

                          searchController.selection =
                              TextSelection.fromPosition(TextPosition(
                            offset: cursorPosition +
                                viewModel.handWritingResult[index].length,
                          ));
                          handWritingController.clear();
                          viewModel.searchOnChange(searchController.text);
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
                  onPressed: () => viewModel.setInputMode(InputMode.ocr),
                  icon: const Icon(Icons.camera_alt),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                IconButton(
                  onPressed: () {
                    viewModel.setInputMode(InputMode.text);
                    keyboardFocusNode.requestFocus();
                  },
                  icon: const Icon(Icons.keyboard),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                IconButton(
                  onPressed: () => viewModel.setInputMode(InputMode.text),
                  icon: const Icon(Icons.close),
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
                    int cursorPosition = searchController.selection.base.offset;
                    if (cursorPosition != 0) {
                      searchController.text = searchController.text
                              .substring(0, cursorPosition - 1) +
                          searchController.text.substring(cursorPosition);

                      searchController.selection = TextSelection.fromPosition(
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
    );
  }
}
