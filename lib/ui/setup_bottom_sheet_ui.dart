import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:stacked_services/stacked_services.dart';

void setupBottomSheetUi() {
  final bottomSheetService = locator<BottomSheetService>();

  final builders = {
    BottomSheetType.myDictionaryLists: (context, sheetRequest, completer) =>
        _MyDictionaryListsSheet(sheetRequest, completer)
  };

  bottomSheetService.setCustomSheetBuilders(builders);
}

// ignore: must_be_immutable
class _MyDictionaryListsSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  List<MyDictionaryListsSheetItem> changes = [];

  _MyDictionaryListsSheet(
    this.request,
    this.completer, {
    Key? key,
  }) : super(key: key);

  @override
  State<_MyDictionaryListsSheet> createState() =>
      _MyDictionaryListsSheetState();
}

class _MyDictionaryListsSheetState extends State<_MyDictionaryListsSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
                  onPressed: () =>
                      widget.completer(SheetResponse(data: widget.changes)),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(
            color: Colors.black,
            height: 1,
            indent: 16,
            endIndent: 16,
          ),
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

enum BottomSheetType {
  myDictionaryLists,
}

class MyDictionaryListsSheetItem {
  final MyDictionaryList list;
  bool enabled;

  MyDictionaryListsSheetItem(this.list, this.enabled);
}
