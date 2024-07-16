import 'package:flutter/material.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class RadicalPositionImage extends StatelessWidget {
  final RadicalPosition position;

  const RadicalPositionImage(this.position, {super.key});

  @override
  Widget build(BuildContext context) {
    switch (position) {
      case RadicalPosition.top:
        return Image.asset('assets/images/radical_positions/top.png');
      case RadicalPosition.left:
        return Image.asset('assets/images/radical_positions/left.png');
      case RadicalPosition.right:
        return Image.asset('assets/images/radical_positions/right.png');
      case RadicalPosition.bottom:
        return Image.asset('assets/images/radical_positions/bottom.png');
      case RadicalPosition.enclose:
        return Image.asset('assets/images/radical_positions/enclose.png');
      case RadicalPosition.topLeft:
        return Image.asset('assets/images/radical_positions/top_left.png');
      case RadicalPosition.bottomLeft:
        return Image.asset('assets/images/radical_positions/bottom_left.png');
    }
  }
}
