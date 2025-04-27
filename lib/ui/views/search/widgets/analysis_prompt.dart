import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';

import '../search_viewmodel.dart';

class AnalysisPrompt extends ViewModelWidget<SearchViewModel> {
  const AnalysisPrompt({super.key});

  @override
  Widget build(BuildContext context, SearchViewModel viewModel) {
    return ListTile(
      title: Text('Multiple words found'),
      subtitle: Text('Tap to view details'),
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.primary,
      ),
      onTap: () => viewModel.navigateToTextAnalysis(
        text: viewModel.searchString,
      ),
    );
  }
}
