import 'package:flutter/material.dart';
import 'package:sagase/ui/bottom_sheets/base_bottom_sheet.dart';
import 'package:stacked_services/stacked_services.dart';

class AssignMyListsBottomSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const AssignMyListsBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

  @override
  State<AssignMyListsBottomSheet> createState() =>
      AssignMyListsBottomSheetState();
}

class AssignMyListsBottomSheetState extends State<AssignMyListsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return BaseBottomSheet(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.close, color: Colors.transparent),
                ),
                const Expanded(
                  child: Text(
                    'My Lists',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => widget.completer(SheetResponse()),
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: widget.request.data.length,
              itemBuilder: (context, index) => CheckboxListTile(
                title: Text(widget.request.data[index].list.name),
                value: widget.request.data[index].enabled,
                onChanged: (bool? value) {
                  if (value == null) return;
                  setState(() {
                    widget.request.data[index].changed =
                        !widget.request.data[index].changed;
                    widget.request.data[index].enabled = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
