import 'package:flutter/material.dart';
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
      body: viewModel.selectingImage
          ? Center(child: CircularProgressIndicator())
          : viewModel.currentImageBytes == null
              ? _InputSelection()
              : _TextSelection(),
    );
  }
}

class _InputSelection extends ViewModelWidget<OcrViewModel> {
  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    final dividerIndent = MediaQuery.of(context).size.width / 2 - 150;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: viewModel.openCamera,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 200,
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera),
                    const SizedBox(height: 2),
                    Text('Open Camera'),
                  ],
                ),
              ),
            ),
          ),
          Divider(indent: dividerIndent, endIndent: dividerIndent),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: viewModel.selectImage,
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 200,
                height: 80,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo),
                    const SizedBox(height: 2),
                    Text('Select Photo'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSelection extends ViewModelWidget<OcrViewModel> {
  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    return Column(
      children: [
        Flexible(
          flex: 2,
          fit: FlexFit.loose,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  viewModel.refresh();
                  print('refresh');
                },
                child: CustomPaint(
                  foregroundPainter: viewModel.recognizedTextBlocks == null
                      ? null
                      : TextRecognizerPainter(
                          viewModel.recognizedTextBlocks!,
                          viewModel.imageSize!,
                        ),
                  child: IgnorePointer(
                    child: Image.memory(viewModel.currentImageBytes!),
                  ),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: viewModel.recognizedTextBlocks == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Analyzing text',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                )
              : _SelectedText(),
        ),
      ],
    );
  }
}

class _SelectedText extends ViewModelWidget<OcrViewModel> {
  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
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
          ),
        ),
        Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          width: double.infinity,
          color: Colors.deepPurple,
          child: TextButton.icon(
            icon: const Icon(Icons.text_snippet, color: Colors.white),
            label: const Text(
              'Analyze selected text',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: viewModel.analyzeSelectedText,
          ),
        ),
      ],
    );
  }
}
