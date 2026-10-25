import 'package:flutter/material.dart';

class PracticeProgressBar extends StatelessWidget {
  final int completed;
  final int remaining;
  final String remainingLabel;

  const PracticeProgressBar({
    required this.completed,
    required this.remaining,
    this.remainingLabel = 'cards left',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    int emptyBar = remaining;
    int completedBar = completed;
    final bottomLeftString = '$completedBar completed';
    final bottomRightString = '$emptyBar $remainingLabel';

    // If completedBar or emptyBar would be too small, set minimum size
    if (completedBar != 0 && completedBar / emptyBar < 0.04) {
      completedBar = 1;
      emptyBar = 25;
    } else if (emptyBar != 0 && emptyBar / completedBar < 0.04) {
      completedBar = 25;
      emptyBar = 1;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.all(Radius.circular(5)),
            ),
            child: completedBar == 0
                ? null
                : Row(
                    children: [
                      Flexible(
                        flex: completedBar,
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.all(
                              Radius.circular(5),
                            ),
                          ),
                        ),
                      ),
                      Flexible(
                        flex: emptyBar,
                        child: Container(),
                      ),
                    ],
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(bottomLeftString, textAlign: TextAlign.start),
                ),
                Expanded(
                  child: Text(bottomRightString, textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
