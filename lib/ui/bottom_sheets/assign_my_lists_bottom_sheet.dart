import 'package:flutter/material.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/ui/bottom_sheets/base_bottom_sheet.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
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
  final _dialogService = locator<DialogService>();
  final _dictionaryService = locator<DictionaryService>();

  Future<void> _createNewList() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textField,
      title: 'Create new list',
      description: 'Name',
      mainButtonTitle: 'Create',
      barrierDismissible: true,
    );

    if (response?.data == null) return;
    final name = (response!.data as String).sanitizeName();
    if (name.isEmpty) return;

    final newList = await _dictionaryService.createMyDictionaryList(name);
    if (!mounted) return;
    setState(() {
      widget.request.data.insert(
        0,
        MyListsBottomSheetItem(newList, true, changed: true),
      );
    });
  }

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
                  onPressed: _createNewList,
                  icon: const Icon(Icons.add),
                  tooltip: 'Create new list',
                ),
                const Expanded(
                  child: Text(
                    'My lists',
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
