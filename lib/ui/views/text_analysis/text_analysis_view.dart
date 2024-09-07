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
        if (controller.text.isEmpty)
          Expanded(
            flex: 2,
            child: _History(controller),
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

class _History extends ViewModelWidget<TextAnalysisViewModel> {
  final TextEditingController controller;

  const _History(this.controller);

  @override
  Widget build(BuildContext context, TextAnalysisViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(24),
          topLeft: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              'History',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(),
          viewModel.history == null || viewModel.history!.isEmpty
              ? const Text('No history')
              : Expanded(
                  child: ListView.separated(
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      indent: 8,
                      endIndent: 8,
                    ),
                    padding: EdgeInsets.zero,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: viewModel.history!.length,
                    itemBuilder: (context, index) {
                      final current = viewModel.history![index];
                      return Dismissible(
                        key: ObjectKey(current),
                        background: Container(color: Colors.red),
                        onDismissed: (DismissDirection direction) {
                          viewModel.textAnalysisHistoryItemDeleted(current);
                        },
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(
                            current.analysisText,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                          onTap: () {
                            controller.text = current.analysisText;
                            viewModel.textAnalysisHistoryItemSelected(current);
                          },
                        ),
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

class _Analysis extends ViewModelWidget<TextAnalysisViewModel> {
  const _Analysis();

  @override
  Widget build(BuildContext context, TextAnalysisViewModel viewModel) {
    if (viewModel.analysisFailed) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No Japanese text found.'),
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
