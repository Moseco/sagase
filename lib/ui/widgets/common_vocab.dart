import 'package:flutter/material.dart';

class CommonVocab extends StatelessWidget {
  final double fontSize;

  const CommonVocab({this.fontSize = 14, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF3AB767),
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      child: SelectionContainer.disabled(
        child: Text(
          'Common',
          style: TextStyle(
            color: Colors.black,
            fontSize: fontSize,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}
