import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardSetReportDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  late final FlashcardSetReport flashcardSetReport;
  late final int streak;

  FlashcardSetReportDialog({
    required this.request,
    required this.completer,
    super.key,
  }) {
    flashcardSetReport = request.data.$1;
    streak = request.data.$2;
  }

  @override
  Widget build(BuildContext context) {
    double percent = (flashcardSetReport.dueFlashcardsCompleted -
            flashcardSetReport.dueFlashcardsGotWrong) /
        flashcardSetReport.dueFlashcardsCompleted;
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'お疲れ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const Text('Performance Summary'),
            const SizedBox(height: 16),
            Center(
              child: CircularPercentIndicator(
                radius: 54,
                lineWidth: 12,
                animation: true,
                percent: percent,
                animationDuration: 750,
                center: Text(
                  "${(percent * 100).toInt()}%",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: Colors.green,
                arcBackgroundColor: Colors.red,
                arcType: ArcType.FULL,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        flashcardSetReport.dueFlashcardsCompleted.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Due Flashcards\nCompleted',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        flashcardSetReport.dueFlashcardsGotWrong.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        textAlign: TextAlign.center,
                        'Due Flashcards\nGot Wrong',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        flashcardSetReport.newFlashcardsCompleted.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        textAlign: TextAlign.center,
                        'New Flashcards\nCompleted',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        streak.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        textAlign: TextAlign.center,
                        'Study\nStreak',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => completer(DialogResponse()),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
