import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';

class KanjiListItem extends StatelessWidget {
  final Kanji kanji;
  final void Function() onPressed;

  const KanjiListItem({
    required this.kanji,
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
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                kanji.kanji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kanji.meanings!,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  KanjiKunReadings(kanji.kunReadings!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
