import 'package:flutter/material.dart';
import 'package:sagase/ui/bottom_sheets/base_bottom_sheet.dart';
import 'package:stacked_services/stacked_services.dart';

class AddToMyListBottomSheet extends StatelessWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const AddToMyListBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: Text(
              'Add vocab to list',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: const Text(
              'Identified vocab will be added to the selected list.\nWords with multiple options will be skipped.',
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: request.data.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(request.data[index].name),
                onTap: () =>
                    completer(SheetResponse(data: request.data[index])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
