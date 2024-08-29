import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ruby_text/ruby_text.dart';
import 'package:sagase/ui/views/text_analysis/text_analysis_viewmodel.dart';
import 'package:sagase/ui/widgets/proper_noun_list_item.dart';
import 'package:sagase/ui/widgets/vocab_list_item.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_hooks/stacked_hooks.dart';

class TextAnalysisView extends StackedView<TextAnalysisViewModel> {
  final String? initialText;

  const TextAnalysisView({this.initialText, super.key});

  @override
  TextAnalysisViewModel viewModelBuilder(BuildContext context) =>
      TextAnalysisViewModel(initialText);

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
                onPressed: () async {
                  final cdata = await Clipboard.getData(Clipboard.kTextPlain);
                  if (cdata?.text != null) {
                    controller.text = cdata!.text!;
                    controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: cdata.text!.length));
                  }
                },
                icon: const Icon(Icons.paste),
              ),
            ],
          TextAnalysisState.loading => null,
          TextAnalysisState.viewing => [
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
        TextAnalysisState.editing => _Editing(controller),
        TextAnalysisState.loading =>
          const Center(child: CircularProgressIndicator()),
        TextAnalysisState.viewing => const _Analysis(),
      },
    );
  }
}

class _Editing extends ViewModelWidget<TextAnalysisViewModel> {
  final TextEditingController controller;

  const _Editing(this.controller);

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
                decoration: const InputDecoration.collapsed(
                  hintText: 'Enter Japanese text to analyze...',
                ),
                maxLength: 1000,
                inputFormatters: [LengthLimitingTextInputFormatter(1000)],
              ),
            ),
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
              'Analyze',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => viewModel.analyzeText(controller.text),
          ),
        ),
      ],
    );
  }
}

class _Analysis extends ViewModelWidget<TextAnalysisViewModel> {
  const _Analysis();

  @override
  Widget build(BuildContext context, TextAnalysisViewModel viewModel) {
    if (viewModel.tokens == null || viewModel.tokens!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No recognizable Japanese text found.'),
            TextButton(
              onPressed: viewModel.editText,
              child: const Text('Edit text'),
            )
          ],
        ),
      );
    }

    List<Widget> textChildren = [];
    List<Widget> associatedVocabChildren = [];
    for (var token in viewModel.tokens!) {
      List<RubyTextData> data = [];

      // Create writing buffer to be used in case of multiple associated vocab
      final writing = StringBuffer();
      // Add main pairs
      for (var rubyPair in token.rubyTextPairs) {
        writing.write(rubyPair.writing);
        data.add(
          RubyTextData(
            rubyPair.writing,
            ruby: rubyPair.reading,
          ),
        );
      }
      // Add any trailing pairs
      if (token.trailing != null) {
        for (var trailing in token.trailing!) {
          for (var rubyPair in trailing.rubyTextPairs) {
            writing.write(rubyPair.writing);
            data.add(
              RubyTextData(
                rubyPair.writing,
                ruby: rubyPair.reading,
              ),
            );
          }
        }
      }

      textChildren.add(
        GestureDetector(
          onTap: () => viewModel.openAssociatedDictionaryItem(token),
          onLongPress: () => viewModel.copyToken(token),
          child: Container(
            decoration: BoxDecoration(
              border: token.associatedDictionaryItems!.isNotEmpty
                  ? Border(
                      bottom: BorderSide(
                        color: Theme.of(context).textTheme.bodyMedium!.color!,
                      ),
                    )
                  : null,
            ),
            child: RubyText(
              data,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 0,
                height: 1.1,
              ),
              rubyStyle: const TextStyle(height: 1.2),
            ),
          ),
        ),
      );

      if (token.associatedDictionaryItems != null &&
          token.associatedDictionaryItems!.isNotEmpty) {
        if (token.associatedDictionaryItems!.length == 1) {
          if (token.associatedDictionaryItems![0] is Vocab) {
            associatedVocabChildren.add(
              VocabListItem(
                vocab: token.associatedDictionaryItems![0] as Vocab,
                onPressed: () => viewModel.openAssociatedDictionaryItem(token),
              ),
            );
          } else {
            associatedVocabChildren.add(
              ProperNounListItem(
                properNoun: token.associatedDictionaryItems![0] as ProperNoun,
                onPressed: () => viewModel.openAssociatedDictionaryItem(token),
              ),
            );
          }
        } else {
          // Multiple dictionary item
          associatedVocabChildren.add(
            InkWell(
              onTap: () => viewModel.openAssociatedDictionaryItem(token),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multiple options for $writing',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const Text(
                      'Tap to view',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    final padding = MediaQuery.of(context).padding;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(left: padding.left, right: padding.right),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height / 2,
            ),
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  children: textChildren,
                ),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 8 + padding.left,
            vertical: 4,
          ),
          color: Colors.deepPurple,
          child: const Text(
            'Vocab found in text',
            style: TextStyle(color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.separated(
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 8,
              endIndent: 8,
            ),
            primary: false,
            padding: EdgeInsets.only(
              left: padding.left,
              right: padding.right,
              bottom: padding.bottom,
            ),
            itemCount: associatedVocabChildren.length,
            itemBuilder: (context, index) => associatedVocabChildren[index],
          ),
        ),
      ],
    );
  }
}
