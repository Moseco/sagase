import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:stacked_themes/stacked_themes.dart' show ThemeManagerMode;

class ThemeSelectionDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const ThemeSelectionDialog({
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
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10, left: 20, right: 20),
              child: Text(
                'App theme',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            RadioListTile<ThemeManagerMode>(
              toggleable: true,
              title: const Text('System'),
              groupValue: ThemeManagerMode.system,
              value: request.data,
              onChanged: (_) => completer(
                DialogResponse(data: ThemeManagerMode.system),
              ),
            ),
            RadioListTile<ThemeManagerMode>(
              toggleable: true,
              title: const Text('Light'),
              groupValue: ThemeManagerMode.light,
              value: request.data,
              onChanged: (_) => completer(
                DialogResponse(data: ThemeManagerMode.light),
              ),
            ),
            RadioListTile<ThemeManagerMode>(
              toggleable: true,
              title: const Text('Dark'),
              groupValue: ThemeManagerMode.dark,
              value: request.data,
              onChanged: (_) => completer(
                DialogResponse(data: ThemeManagerMode.dark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
