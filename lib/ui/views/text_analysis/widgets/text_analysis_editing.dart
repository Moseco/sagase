import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stacked/stacked.dart';

import '../text_analysis_viewmodel.dart';

class TextAnalysisEditing extends ViewModelWidget<TextAnalysisViewModel> {
  final TextEditingController controller;

  const TextAnalysisEditing(this.controller, {super.key});

  @override
  Widget build(BuildContext context, TextAnalysisViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: controller,
                autofocus: true,
                maxLines: null,
                style: const TextStyle(fontSize: 24),
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter Japanese text to analyze...',
                ),
                maxLength: 1000,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
                onChanged: viewModel.textChanged,
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          crossFadeState: controller.text.isEmpty
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
          firstChild: _MenuBar(controller),
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
    );
  }
}

class _MenuBar extends ViewModelWidget<TextAnalysisViewModel> {
  final TextEditingController controller;

  const _MenuBar(this.controller, {super.key});

  @override
  Widget build(BuildContext context, TextAnalysisViewModel viewModel) {
    final padding = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        left: padding.left,
        right: padding.right,
        bottom: padding.bottom * 1.5,
      ),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Spacer(),
            _IconWithText(
              icon: Icons.history,
              text: 'History',
              onPressed: () async {
                await viewModel.openHistory();
                controller.text = viewModel.text;
              },
            ),
            _IconWithText(
              icon: Icons.camera,
              text: 'Camera',
              onPressed: () async {
                await viewModel.navigateToOcr(true);
                controller.text = viewModel.text;
              },
            ),
            _IconWithText(
              icon: Icons.photo,
              text: 'Photos',
              onPressed: () async {
                await viewModel.navigateToOcr(false);
                controller.text = viewModel.text;
              },
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _IconWithText extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _IconWithText({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Icon(icon),
              const SizedBox(height: 2),
              Text(text),
            ],
          ),
        ),
      ),
    );
  }
}
