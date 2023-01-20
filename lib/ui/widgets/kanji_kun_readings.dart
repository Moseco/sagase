import 'package:flutter/material.dart';

class KanjiKunReadings extends StatelessWidget {
  final List<String> kunReadings;
  final TextSpan? leading;
  final int maxLines;
  final bool alignCenter;

  const KanjiKunReadings(
    this.kunReadings, {
    this.leading,
    this.maxLines = 1,
    this.alignCenter = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Compile readings into TextSpans
    List<String> split = kunReadings[0].split('.');
    List<TextSpan> kunReadingTextSpans = [
      if (leading != null) leading!,
      TextSpan(
        children: [
          TextSpan(text: split[0]),
          if (split.length == 2)
            TextSpan(
              text: split[1],
              style: const TextStyle(color: Colors.grey),
            ),
        ],
      ),
    ];

    for (int i = 1; i < kunReadings.length; i++) {
      final split = kunReadings[i].split('.');
      kunReadingTextSpans.add(
        TextSpan(
          children: [
            const TextSpan(text: ', '),
            TextSpan(text: split[0]),
            if (split.length == 2)
              TextSpan(
                text: split[1],
                style: const TextStyle(color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return Text.rich(
      TextSpan(children: kunReadingTextSpans),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      textAlign: alignCenter ? TextAlign.center : TextAlign.start,
    );
  }
}
