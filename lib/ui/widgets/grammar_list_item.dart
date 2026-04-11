import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class GrammarListItem extends StatelessWidget {
  final Grammar grammar;
  final void Function()? onPressed;

  const GrammarListItem({
    required this.grammar,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grammar.form,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              grammar.meaning,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
