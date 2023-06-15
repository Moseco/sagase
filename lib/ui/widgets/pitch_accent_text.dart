import 'package:flutter/material.dart';

class PitchAccentText extends StatelessWidget {
  final String text;
  final List<int> pitchAccents;
  final double? fontSize;

  const PitchAccentText({
    required this.text,
    required this.pitchAccents,
    this.fontSize,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Just return text if have no pitch accent
    if (pitchAccents.isEmpty) {
      return Text(
        text,
        style: TextStyle(fontSize: fontSize),
      );
    }

    // Group characters as mora (mainly joins characters for kana like しょ)
    List<String> moras = [];
    for (int i = 0; i < text.length; i++) {
      String currentMora = text[i];
      // Check if next character should join current character as a mora
      if (i + 1 < text.length &&
          (text[i + 1] == 'ゃ' ||
              text[i + 1] == 'ゅ' ||
              text[i + 1] == 'ょ' ||
              text[i + 1] == 'ャ' ||
              text[i + 1] == 'ュ' ||
              text[i + 1] == 'ョ')) {
        currentMora = currentMora + text[i + 1];
        i++;
      }
      moras.add(currentMora);
    }

    List<Widget> children = [];

    for (int i = 0; i < pitchAccents.length; i++) {
      List<WidgetSpan> characters = [];
      for (int j = 0; j < moras.length; j++) {
        characters.add(
          WidgetSpan(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: (pitchAccents[i] == 0 && j > 0) ||
                          (pitchAccents[i] == 1 && j == 0) ||
                          (pitchAccents[i] > 1 && j > 0 && j < pitchAccents[i])
                      ? const BorderSide(color: Colors.grey, width: 2)
                      : const BorderSide(color: Colors.transparent, width: 2),
                  bottom: (pitchAccents[i] != 1 && j == 0) ||
                          (pitchAccents[i] == 1 && j > 0) ||
                          (pitchAccents[i] > 1 && j >= pitchAccents[i])
                      ? const BorderSide(color: Colors.grey, width: 2)
                      : const BorderSide(color: Colors.transparent, width: 2),
                  right: j == 0 ||
                          (pitchAccents[i] > 1 &&
                              moras.length == pitchAccents[i] &&
                              j == moras.length - 1) ||
                          (pitchAccents[i] > 1 &&
                              moras.length != pitchAccents[i] &&
                              j == pitchAccents[i] - 1)
                      ? const BorderSide(color: Colors.grey, width: 2)
                      : BorderSide.none,
                ),
              ),
              child: Text(
                moras[j],
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
      if (i + 1 < pitchAccents.length) children.add(const SizedBox(height: 4));
    }

    return Column(children: children);
  }
}
