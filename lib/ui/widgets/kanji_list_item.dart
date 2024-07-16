import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/ui/widgets/kanji_kun_readings.dart';

class KanjiListItem extends StatelessWidget {
  final Kanji kanji;
  final void Function()? onPressed;

  const KanjiListItem({
    required this.kanji,
    this.onPressed,
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
                    kanji.meaning ?? '(no meaning)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  kanji.kunReadings != null
                      ? KanjiKunReadings(
                          kanji.kunReadings!.map((e) => e.reading).toList(),
                        )
                      : Text(
                          _getReadingString(),
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

  String _getReadingString() {
    if (kanji.onReadings != null) return kanji.onReadings!.join(', ');
    if (kanji.nanori != null) return kanji.nanori!.join(', ');
    return '';
  }
}
