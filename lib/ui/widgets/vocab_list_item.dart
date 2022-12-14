import 'package:flutter/material.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/common_vocab.dart';

class VocabListItem extends StatelessWidget {
  final Vocab vocab;
  final void Function() onPressed;

  const VocabListItem({
    required this.vocab,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
                    vocab.definitions[0].definition,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            if (vocab.commonWord) const CommonVocab(fontSize: 10),
          ],
        ),
      ),
    );
  }
}
