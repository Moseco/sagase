import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart'
    show defaultInitialCorrectInterval, defaultInitialVeryCorrectInterval;

class InitialIntervalDialog extends HookWidget {
  final _snackbarService = locator<SnackbarService>();

  final DialogRequest request;
  final Function(DialogResponse) completer;

  InitialIntervalDialog({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final correctController = useTextEditingController(text: request.data[0]);
    final veryCorrectController =
        useTextEditingController(text: request.data[1]);
    return Dialog(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'Set initial spaced repetition interval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                'The interval is the duration in days before a flashcard will appear again when answering a flashcard for the first time or after a wrong answer. Default is $defaultInitialCorrectInterval and $defaultInitialVeryCorrectInterval.',
                textAlign: TextAlign.justify,
                style: TextStyle(),
              ),
            ),
            TextField(
              controller: correctController,
              maxLines: 1,
              decoration: const InputDecoration(
                icon: Icon(Icons.check),
                labelText: 'Correct answer',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextField(
                controller: veryCorrectController,
                maxLines: 1,
                decoration: const InputDecoration(
                  icon: Icon(Icons.done_all),
                  labelText: 'Very correct answer',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (correctController.text.isEmpty ||
                    veryCorrectController.text.isEmpty) {
                  _snackbarService.showSnackbar(
                    message: 'Both intervals must be provided',
                  );
                  return;
                }

                int correctInterval = int.parse(correctController.text);
                int veryCorrectInterval = int.parse(veryCorrectController.text);

                if (correctInterval == 0 ||
                    veryCorrectInterval == 0 ||
                    correctInterval > veryCorrectInterval) {
                  _snackbarService.showSnackbar(
                    message:
                        'Both intervals must be greater than 0 and the very correct answer interval must be larger',
                  );
                  return;
                }

                completer(
                  DialogResponse(data: [correctInterval, veryCorrectInterval]),
                );
              },
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
