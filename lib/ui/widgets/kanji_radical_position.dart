import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class KanjiRadicalPositionImage extends StatelessWidget {
  final KanjiRadicalPosition position;

  const KanjiRadicalPositionImage(this.position, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (position) {
      case KanjiRadicalPosition.top:
        return Image.asset('assets/images/kanji_radical_positions/top.png');
      case KanjiRadicalPosition.left:
        return Image.asset('assets/images/kanji_radical_positions/left.png');
      case KanjiRadicalPosition.right:
        return Image.asset('assets/images/kanji_radical_positions/right.png');
      case KanjiRadicalPosition.bottom:
        return Image.asset('assets/images/kanji_radical_positions/bottom.png');
      case KanjiRadicalPosition.enclose:
        return Image.asset('assets/images/kanji_radical_positions/enclose.png');
      case KanjiRadicalPosition.topLeft:
        return Image.asset(
            'assets/images/kanji_radical_positions/top_left.png');
      case KanjiRadicalPosition.bottomLeft:
        return Image.asset(
            'assets/images/kanji_radical_positions/bottom_left.png');
      case KanjiRadicalPosition.none:
        return Container();
    }
  }
}
