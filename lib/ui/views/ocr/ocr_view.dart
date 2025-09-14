import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/list_item_loading.dart';
import 'package:sagase/ui/widgets/ocr_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';

import 'ocr_viewmodel.dart';

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
        actions: viewModel.image == null
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
            child: viewModel.image == null
                ? _OcrImageLoading()
                : OcrImage(
                    key: ValueKey(viewModel.image!.path.hashCode),
                    image: viewModel.image!,
                    onImageProcessed: viewModel.handleImageProcessed,
                    onImageError: viewModel.handleImageError,
                    onTextSelected: viewModel.handleTextSelected,
                    locked: false,
                    singleSelection: false,
                  ),
          ),
          const Divider(indent: 8, endIndent: 8),
          Expanded(
            child: viewModel.selectedText == null
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

class _SelectedText extends ViewModelWidget<OcrViewModel> {
  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    if (viewModel.selectedText!.isEmpty) {
      return Center(child: Text('Select text from the image'));
    }

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            itemCount: viewModel.selectedText!.length,
            onReorder: viewModel.reorderList,
            itemBuilder: (context, index) {
              final current = viewModel.selectedText![index];
              return ListTile(
                key: ValueKey(current),
                title: Text(current),
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
            label: Text(
              'Analyze text',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: viewModel.analyzeSelectedText,
          ),
        ),
      ],
    );
  }
}
