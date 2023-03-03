import 'package:flutter/material.dart';
import 'package:sagase/ui/views/flashcards/flashcards_viewmodel.dart';
import 'package:stacked_services/stacked_services.dart';

class FlashcardStartDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const FlashcardStartDialog({
    required this.request,
    required this.completer,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Start Flashcard With',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Normal mode'),
              subtitle: const Text('Due flashcards followed by new flashcards'),
              onTap: () => completer(
                DialogResponse(data: FlashcardStartMode.normal),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.play_lesson),
              title: const Text('Learning mode'),
              subtitle: const Text(
                'Due flashcards mixed with a set amount of new flashcards',
              ),
              onTap: () => completer(
                DialogResponse(data: FlashcardStartMode.learning),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.redo),
              title: const Text('Skip mode'),
              subtitle: const Text('Skip directly to new flashcards'),
              onTap: () => completer(
                DialogResponse(data: FlashcardStartMode.skip),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
