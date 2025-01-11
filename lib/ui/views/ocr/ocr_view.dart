import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/list_item_loading.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';

import 'ocr_viewmodel.dart';
import 'painters/text_detector_painter.dart';

class OcrView extends StackedView<OcrViewModel> {
  final bool cameraStart;

  const OcrView(this.cameraStart, {super.key});

  @override
  OcrViewModel viewModelBuilder(context) => OcrViewModel(cameraStart);

  @override
  Widget builder(BuildContext context, OcrViewModel viewModel, Widget? child) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Character Detection'),
        actions: viewModel.currentImageBytes == null
            ? null
            : [
                IconButton(
                  onPressed: viewModel.openCamera,
                  icon: Icon(Icons.camera),
                ),
                IconButton(
                  onPressed: viewModel.selectImage,
                  icon: Icon(Icons.photo),
                ),
              ],
      ),
      body: Column(
        children: [
          Expanded(
            child: viewModel.currentImageBytes == null
                ? _OcrImageLoading()
                : _OcrImage(),
          ),
          const Divider(indent: 8, endIndent: 8),
          Expanded(
            child: viewModel.recognizedTextBlocks == null
                ? Column(
                    children: [
                      ListItemLoading(),
                      const SizedBox(height: 8),
                      ListItemLoading(),
                    ],
                  )
                : _SelectedText(),
          ),
        ],
      ),
    );
  }
}

class _OcrImageLoading extends StatelessWidget {
  const _OcrImageLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF3a3a3a) : Colors.grey.shade300,
        highlightColor: isDark ? const Color(0xFF4a4a4a) : Colors.grey.shade100,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class _OcrImage extends ViewModelWidget<OcrViewModel> {
  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        child: GestureDetector(
          onTap: () => viewModel.rebuildUi(),
          child: CustomPaint(
            foregroundPainter: viewModel.recognizedTextBlocks == null
                ? null
                : TextRecognizerPainter(
                    viewModel.recognizedTextBlocks!,
                    viewModel.imageSize,
                  ),
            child: IgnorePointer(
              child: Image.memory(viewModel.currentImageBytes!),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedText extends ViewModelWidget<OcrViewModel> {
  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    if (viewModel.recognizedTextBlocks!.isEmpty) {
      return Center(child: Text('No Japanese text was found'));
    }

    late Widget textSection;

    if (viewModel.recognizedTextBlocks!.length == 1) {
      textSection = SelectionArea(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Text(
              viewModel.recognizedTextBlocks![0].text,
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    } else {
      textSection = ReorderableListView.builder(
        itemCount: viewModel.recognizedTextBlocks!.length,
        onReorder: viewModel.reorderList,
        itemBuilder: (context, index) {
          final current = viewModel.recognizedTextBlocks![index];
          return ListTile(
            key: ValueKey(current),
            leading: Checkbox(
              value: current.selected,
              onChanged: (value) {
                if (value == null) return;
                viewModel.toggleCheckBox(index, value);
              },
            ),
            title: Text(current.text),
            trailing: Icon(Icons.drag_indicator),
          );
        },
      );
    }

    return Column(
      children: [
        Expanded(child: textSection),
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          width: double.infinity,
          color: Colors.deepPurple,
          child: TextButton.icon(
            icon: const Icon(Icons.text_snippet, color: Colors.white),
            label: Text(
              viewModel.recognizedTextBlocks!.length == 1
                  ? 'Analyze text'
                  : 'Analyze selected text',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: viewModel.analyzeSelectedText,
          ),
        ),
      ],
    );
  }
}
