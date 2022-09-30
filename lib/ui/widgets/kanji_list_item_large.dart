import 'package:flutter/material.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';

class KanjiListItemLarge extends StatelessWidget {
  final Kanji kanji;
  final void Function() onPressed;

  const KanjiListItemLarge({
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
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: Text(
                kanji.kanji,
                style: const TextStyle(fontSize: 24),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (kanji.meanings != null)
                    Text(
                      kanji.meanings!,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (kanji.kunReadings != null)
                    KanjiKunReadings(kanji.kunReadings!),
                  if (kanji.onReadings != null)
                    Text(
                      kanji.onReadings!.join(', '),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
