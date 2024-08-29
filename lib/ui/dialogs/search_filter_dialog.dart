import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/dictionary_service.dart' show SearchFilter;
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked_services/stacked_services.dart';

class SearchFilterDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  const SearchFilterDialog({
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
                'Search for',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            RadioListTile<SearchFilter>(
              toggleable: true,
              title: const Text('Vocab'),
              groupValue: SearchFilter.vocab,
              value: request.data,
              onChanged: (_) => completer(
                DialogResponse(data: SearchFilter.vocab),
              ),
            ),
            RadioListTile<SearchFilter>(
              toggleable: true,
              title: const Text('Kanji'),
              groupValue: SearchFilter.kanji,
              value: request.data,
              onChanged: (_) => completer(
                DialogResponse(data: SearchFilter.kanji),
              ),
            ),
            RadioListTile<SearchFilter>(
              toggleable: true,
              title: const Text('Proper nouns'),
              groupValue: SearchFilter.properNouns,
              value: request.data,
              onChanged: (_) {
                if (locator<SharedPreferencesService>()
                    .getProperNounsEnabled()) {
                  completer(DialogResponse(data: SearchFilter.properNouns));
                } else {
                  locator<SnackbarService>().showSnackbar(
                    message: 'Enable proper noun dictionary in settings',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
