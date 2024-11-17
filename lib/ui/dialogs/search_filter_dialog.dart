import 'package:flutter/material.dart';
import 'package:sagase/services/dictionary_service.dart' show SearchFilter;
import 'package:stacked_services/stacked_services.dart';

class SearchFilterDialog extends StatelessWidget {
  final DialogRequest request;
  final Function(DialogResponse) completer;

  final SearchFilter searchFilter;
  final bool properNounsEnabled;

  SearchFilterDialog({
    required this.request,
    required this.completer,
    super.key,
  })  : searchFilter = request.data.$1,
        properNounsEnabled = request.data.$2;

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
                textAlign: TextAlign.center,
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
              value: searchFilter,
              onChanged: (_) => completer(
                DialogResponse(data: SearchFilter.vocab),
              ),
            ),
            RadioListTile<SearchFilter>(
              toggleable: true,
              title: const Text('Kanji'),
              groupValue: SearchFilter.kanji,
              value: searchFilter,
              onChanged: (_) => completer(
                DialogResponse(data: SearchFilter.kanji),
              ),
            ),
            RadioListTile<SearchFilter>(
              toggleable: true,
              title: const Text('Proper nouns'),
              subtitle:
                  properNounsEnabled ? null : const Text('Enable in settings'),
              groupValue: SearchFilter.properNouns,
              value: searchFilter,
              onChanged: properNounsEnabled
                  ? (_) =>
                      completer(DialogResponse(data: SearchFilter.properNouns))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
