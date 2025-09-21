import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/camera_viewfinder.dart';
import 'package:sagase/ui/widgets/hand_writing_canvas.dart';
import 'package:sagase/ui/widgets/ocr_image.dart';
import 'package:stacked/stacked.dart';

import '../search_viewmodel.dart';

class OcrWidget extends ViewModelWidget<SearchViewModel> {
  final TextEditingController searchController;
  final HandWritingController handWritingController;
  final FocusNode keyboardFocusNode;

  const OcrWidget({
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: viewModel.resetImage,
                      child: const Text('Retake photo'),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      viewModel.setInputMode(InputMode.handWriting),
                  icon: const Icon(Icons.draw),
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
                  icon: const Icon(Icons.keyboard_arrow_down),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          Expanded(
            child: viewModel.ocrError
                ? Center(
                    child: Text(
                      'Failed to process image',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : viewModel.image == null
                    ? CameraViewfinder(
                        onPictureTaken: viewModel.handlePictureTaken)
                    : OcrImage(
                        key: ValueKey(viewModel.image!.path.hashCode),
                        image: viewModel.image!,
                        onImageError: viewModel.handleImageError,
                        onTextSelected: (text) {
                          text = text.replaceAll('\n', '');
                          searchController.text = text;
                          viewModel.handleTextSelected(text);
                        },
                        locked: true,
                        singleSelection: true,
                      ),
          ),
        ],
      ),
    );
  }
}
