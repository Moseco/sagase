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
    late final String title;
    if (vocab.writings != null &&
        (vocab.writings![0].info == null ||
            !vocab.writings![0].info!.contains(WritingInfo.searchOnlyForm))) {
      title = '${vocab.writings![0].writing}【${vocab.readings[0].reading}】';
    } else {
      title = vocab.readings[0].reading;
    }

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
                    title,
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
            if (vocab.common && showCommonWord) const CommonVocab(fontSize: 10),
          ],
        ),
      ),
    );
  }
}
