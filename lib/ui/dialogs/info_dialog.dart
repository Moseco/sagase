import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';

class InfoDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const InfoDialog({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
            Text(
              request.title!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              request.description!,
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => completer(DialogResponse()),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
