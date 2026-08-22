import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/furigana_text.dart';
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
      // Can throw exception "'!_selectionStartsInScrollable': is not true."
      // when long press then try to scroll on disabled areas.
      // But seems to work okay in release builds.
      body: SafeArea(
        bottom: false,
        child: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _Form(viewModel.grammar),
              _Meaning(viewModel.grammar),
              const _Example(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _Form extends StatelessWidget {
  final Grammar grammar;

  const _Form(this.grammar);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FuriganaText(
        grammar.form,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32),
      ),
    );
  }
}

class _Meaning extends StatelessWidget {
  final Grammar grammar;

  const _Meaning(this.grammar);

  @override
  Widget build(BuildContext context) {
    return CardWithTitleSection(
      title: 'Meaning',
      titleTrailing: _JlptLevel(grammar.jlptLevel),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Text(grammar.meaning),
      ),
    );
  }
}

class _JlptLevel extends StatelessWidget {
  final int level;

  const _JlptLevel(this.level);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: const BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: SelectionContainer.disabled(
        child: Text(
          'JLPT N$level',
          style: const TextStyle(
            color: Colors.white,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _Example extends ViewModelWidget<GrammarViewModel> {
  const _Example() : super(reactive: false);

  @override
  Widget build(BuildContext context, GrammarViewModel viewModel) {
    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Example',
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: viewModel.openExampleInAnalysis,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FuriganaText(viewModel.grammar.exampleJapanese),
                Text(viewModel.grammar.exampleEnglish),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
