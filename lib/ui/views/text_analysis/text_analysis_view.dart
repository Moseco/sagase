import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

import 'text_analysis_viewmodel.dart';
import 'widgets/text_analysis_editing.dart';
import 'widgets/text_analysis_viewing.dart';

class TextAnalysisView extends StackedView<TextAnalysisViewModel> {
  final String? initialText;
  final bool addToHistory;

  const TextAnalysisView({
    this.initialText,
    this.addToHistory = true,
    super.key,
  });

  @override
  TextAnalysisViewModel viewModelBuilder(BuildContext context) =>
      TextAnalysisViewModel(initialText, addToHistory);

  @override
  Widget builder(context, viewModel, child) => const _Body();
}

class _Body extends StackedHookView<TextAnalysisViewModel> {
  const _Body();

  @override
  Widget builder(BuildContext context, TextAnalysisViewModel viewModel) {
    final controller = useTextEditingController(text: viewModel.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Text Analysis'),
        actions: switch (viewModel.state) {
          TextAnalysisState.editing => [
              IconButton(
                onPressed: () {
                  controller.clear();
                  viewModel.textChanged('');
                },
                icon: const Icon(Icons.clear),
              ),
              IconButton(
                onPressed: () async {
                  final cdata = await Clipboard.getData(Clipboard.kTextPlain);
                  if (cdata?.text != null) {
                    controller.text = cdata!.text!;
                    viewModel.analyzeText(cdata.text!);
                  }
                },
                icon: const Icon(Icons.content_paste_go),
              ),
            ],
          TextAnalysisState.loading => null,
          TextAnalysisState.viewing => [
              IconButton(
                onPressed: () {
                  controller.clear();
                  viewModel.textChanged('');
                  viewModel.editText();
                },
                icon: const Icon(Icons.note_add_outlined),
              ),
              IconButton(
                onPressed: viewModel.editText,
                icon: const Icon(Icons.edit),
              ),
              IconButton(
                onPressed: viewModel.copyText,
                icon: const Icon(Icons.copy),
              ),
            ],
        },
      ),
      body: switch (viewModel.state) {
        TextAnalysisState.editing => TextAnalysisEditing(controller),
        TextAnalysisState.loading =>
          const Center(child: CircularProgressIndicator()),
        TextAnalysisState.viewing => const TextAnalysisViewing(),
      },
    );
  }
}
