import 'package:flutter/material.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:stacked_services/stacked_services.dart';

class AssignMyListsBottomSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  final List<MyListsBottomSheetItem> changes = [];

  AssignMyListsBottomSheet({
    required this.request,
    required this.completer,
    Key? key,
  }) : super(key: key);

  @override
  State<AssignMyListsBottomSheet> createState() =>
      AssignMyListsBottomSheetState();
}

class AssignMyListsBottomSheetState extends State<AssignMyListsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => widget.completer(SheetResponse()),
                  icon: const Icon(Icons.close),
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
                  onPressed: () =>
                      widget.completer(SheetResponse(data: widget.changes)),
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(8),
              itemCount: widget.request.data.length,
              itemBuilder: (context, index) => CheckboxListTile(
                title: Text(widget.request.data[index].list.name),
                value: widget.request.data[index].enabled,
                onChanged: (bool? value) {
                  if (value == null) return;
                  setState(() {
                    widget.request.data[index].enabled = value;
                    if (!widget.changes.contains(widget.request.data[index])) {
                      widget.changes.add(widget.request.data[index]);
                    } else {
                      widget.changes.remove(widget.request.data[index]);
                    }
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
