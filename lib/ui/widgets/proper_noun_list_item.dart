import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class ProperNounListItem extends StatelessWidget {
  final ProperNoun properNoun;
  final void Function()? onPressed;

  const ProperNounListItem({
    required this.properNoun,
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
              properNoun.writing != null
                  ? '${properNoun.writing}【${properNoun.reading}】'
                  : properNoun.reading,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              properNoun.romaji,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
