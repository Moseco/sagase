import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';

import 'grammar_viewmodel.dart';

class GrammarView extends StackedView<GrammarViewModel> {
  final Grammar grammar;
  final int? grammarListIndex;
  final List<Grammar>? grammarList;

  const GrammarView(
    this.grammar, {
    this.grammarListIndex,
    this.grammarList,
    super.key,
  });

  @override
  GrammarViewModel viewModelBuilder(_) =>
      GrammarViewModel(grammar, grammarListIndex, grammarList);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (grammarList != null)
            IconButton(
              onPressed: grammarListIndex == 0
                  ? null
                  : viewModel.navigateToPreviousGrammar,
              icon: const Icon(Icons.chevron_left),
            ),
          if (grammarList != null)
            IconButton(
              onPressed: grammarListIndex! == grammarList!.length - 1
                  ? null
                  : viewModel.navigateToNextGrammar,
              icon: const Icon(Icons.chevron_right),
            ),
          IconButton(
            onPressed: viewModel.openMyDictionaryListsSheet,
            icon: Icon(
              viewModel.inMyDictionaryList ? Icons.star : Icons.star_border,
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: _buildLessonContent(context, viewModel.grammar),
      ),
    );
  }

  Widget _buildLessonContent(BuildContext context, Grammar grammar) {
    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              grammar.form,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'JLPT N${grammar.jlptLevel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(grammar.meaning),
          ],
        ),
      ),
    );
  }
}
