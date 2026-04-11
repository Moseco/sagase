import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/datamodels/grammar_content.dart';

import 'grammar_viewmodel.dart';

class GrammarView extends StackedView<GrammarViewModel> {
  final Grammar grammar;

  const GrammarView(this.grammar, {super.key});

  @override
  GrammarViewModel viewModelBuilder(_) => GrammarViewModel(grammar);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      appBar: AppBar(
        title: Text(viewModel.grammar.form),
        actions: [
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grammar.form,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              grammar.meaning,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
            // const SizedBox(height: 24),
            // // Content blocks
            // ...lesson.content
            //     .map((block) => _buildContentBlock(context, block)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBlock(BuildContext context, ContentBlock block) {
    if (block is HeaderBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(
          block.content,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      );
    } else if (block is SubheaderBlock) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          block.content,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
        ),
      );
    } else if (block is ParagraphBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: RichText(
          text: TextSpan(
            children: block.textSpans,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    } else if (block is ExampleBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(
              left: BorderSide(color: Colors.blue[400]!, width: 4),
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Japanese text
              Text(
                block.japanese.text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
              const SizedBox(height: 4),
              // Romaji
              Text(
                block.japanese.romaji,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 8),
              // English translation
              Text(
                block.english,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
              ),
            ],
          ),
        ),
      );
    } else if (block is BulletedListBlock) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: block.items
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Expanded(
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
