import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/common_vocab.dart';

class VocabListItem extends StatelessWidget {
  final Vocab vocab;
  final void Function()? onPressed;
  final bool showCommonWord;

  const VocabListItem({
    required this.vocab,
    this.onPressed,
    this.showCommonWord = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Merge definitions
    final definitionBuffer = StringBuffer();
    definitionBuffer.write(vocab.definitions[0].definition);
    for (int i = 1; i < vocab.definitions.length; i++) {
      definitionBuffer.write('; ');
      definitionBuffer.write(vocab.definitions[i].definition);
    }

    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocab.kanjiReadingPairs[0].kanjiWritings != null
                        ? '${vocab.kanjiReadingPairs[0].kanjiWritings![0].kanji}【${vocab.kanjiReadingPairs[0].readings[0].reading}】'
                        : vocab.kanjiReadingPairs[0].readings[0].reading,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    definitionBuffer.toString(),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (vocab.commonWord && showCommonWord)
              const CommonVocab(fontSize: 10),
          ],
        ),
      ),
    );
  }
}
