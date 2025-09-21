import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/ui/widgets/list_item_loading.dart';
import 'package:sagase/ui/widgets/ocr_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

import 'ocr_viewmodel.dart';

class OcrView extends StackedView<OcrViewModel> {
  final bool cameraStart;

  const OcrView(this.cameraStart, {super.key});

  @override
  OcrViewModel viewModelBuilder(context) => OcrViewModel(cameraStart);

  @override
  Widget builder(context, viewModel, child) => const _Body();
}

class _Body extends StackedHookView<OcrViewModel> {
  const _Body();

  @override
  Widget builder(BuildContext context, OcrViewModel viewModel) {
    final controller = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Character Detection'),
        actions: viewModel.state == OcrState.waiting ||
                viewModel.state == OcrState.loading
            ? null
            : [
                IconButton(
                  onPressed: () {
                    viewModel.openCamera();
                    controller.clear();
                  },
                  icon: Icon(Icons.camera),
                ),
                IconButton(
                  onPressed: () {
                    viewModel.selectImage();
                    controller.clear();
                  },
                  icon: Icon(Icons.photo),
                ),
              ],
      ),
      body: viewModel.state == OcrState.error
          ? _Error(controller)
          : Column(
              children: [
                Expanded(
                  child: viewModel.image == null
                      ? _OcrImageLoading()
                      : OcrImage(
                          key: ValueKey(viewModel.image!.path.hashCode),
                          image: viewModel.image!,
                          onImageProcessed: viewModel.handleImageProcessed,
                          onImageError: viewModel.handleImageError,
                          onTextSelected: (text) {
                            controller.text = controller.text + text;
                            viewModel.handleTextSelected();
                          },
                          locked: false,
                          singleSelection: false,
                        ),
                ),
                const Divider(indent: 8, endIndent: 8),
                Expanded(
                  child: switch (viewModel.state) {
                    OcrState.viewEmpty => const Center(
                        child: Text(
                          'No text found in the image',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    OcrState.viewing => _SelectedText(controller),
                    _ => Column(
                        children: [
                          ListItemLoading(),
                          const SizedBox(height: 8),
                          ListItemLoading(),
                        ],
                      )
                  },
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
  final TextEditingController controller;

  const _SelectedText(this.controller);

  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    return GestureDetector(
      onVerticalDragStart: (_) => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  style: const TextStyle(fontSize: 24),
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Select text from the image...',
                  ),
                  maxLength: 1000,
                  inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            crossFadeState: controller.text.isEmpty
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
            firstChild: SizedBox.shrink(),
            secondChild: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              width: double.infinity,
              color: Colors.deepPurple,
              child: TextButton.icon(
                icon: const Icon(Icons.text_snippet, color: Colors.white),
                label: const Text(
                  'Analyze',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () => viewModel.analyzeText(controller.text),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Error extends ViewModelWidget<OcrViewModel> {
  final TextEditingController controller;

  const _Error(this.controller);

  @override
  Widget build(BuildContext context, OcrViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Failed to analyze image',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Please try again'),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              viewModel.openCamera();
              controller.clear();
            },
            icon: const Icon(Icons.camera),
            label: const Text('Open camera'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              viewModel.selectImage();
              controller.clear();
            },
            icon: const Icon(Icons.photo),
            label: const Text('Pick from photos'),
          ),
        ],
      ),
    );
  }
}
