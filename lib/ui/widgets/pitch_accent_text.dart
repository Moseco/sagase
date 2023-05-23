import 'package:flutter/material.dart';

class PitchAccentText extends StatelessWidget {
  final String text;
  final List<int> pitchAccent;
  final double? fontSize;

  const PitchAccentText({
    required this.text,
    required this.pitchAccent,
    this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Just return text if have no pitch accent
    if (pitchAccent.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: fontSize),
      );
    }

    List<Widget> children = [];

    for (int a = 0; a < pitchAccent.length; a++) {
      List<WidgetSpan> characters = [];
      for (int i = 0; i < text.length; i++) {
        characters.add(
          WidgetSpan(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: (pitchAccent[a] == 0 && i > 0) ||
                          (pitchAccent[a] == 1 && i == 0) ||
                          (pitchAccent[a] > 1 && i > 0 && i < pitchAccent[a])
                      ? const BorderSide(color: Colors.grey, width: 2)
                      : const BorderSide(color: Colors.transparent, width: 2),
                  bottom: (pitchAccent[a] != 1 && i == 0) ||
                          (pitchAccent[a] == 1 && i > 0) ||
                          (pitchAccent[a] > 1 && i >= pitchAccent[a])
                      ? const BorderSide(color: Colors.grey, width: 2)
                      : const BorderSide(color: Colors.transparent, width: 2),
                  right: i == 0 ||
                          (pitchAccent[a] > 1 &&
                              text.length == pitchAccent[a] &&
                              i == text.length - 1) ||
                          (pitchAccent[a] > 1 &&
                              text.length != pitchAccent[a] &&
                              i == pitchAccent[a] - 1)
                      ? const BorderSide(color: Colors.grey, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                text[i],
                style: TextStyle(fontSize: fontSize),
              ),
            ),
          ),
        );
      }

      children.add(
        Text.rich(
          TextSpan(children: characters),
        ),
      );

      // If not last pitch accent, add spacing
      if (a + 1 < pitchAccent.length) children.add(const SizedBox(height: 4));
    }

    return Column(children: children);
  }
}
