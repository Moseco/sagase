import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import 'grammar_viewmodel.dart';

class GrammarView extends StackedView<GrammarViewModel> {
  const GrammarView({super.key});

  @override
  GrammarViewModel viewModelBuilder(_) => GrammarViewModel();

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        bottom: false,
        child: ElevatedButton(
          onPressed: viewModel.openLesson,
          child: const Text('Navigate to Lesson'),
        ),
      ),
    );
  }
}
