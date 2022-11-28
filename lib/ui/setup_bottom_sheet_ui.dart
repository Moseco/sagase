import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' as constants;

void setupBottomSheetUi() {
  final bottomSheetService = locator<BottomSheetService>();

  final builders = {
    BottomSheetType.myDictionaryLists: (context, sheetRequest, completer) =>
        _MyDictionaryListsSheet(sheetRequest, completer),
    BottomSheetType.flashcardSet: (context, sheetRequest, completer) =>
        _FlashcardSetSheet(sheetRequest, completer),
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

// ignore: must_be_immutable
class _FlashcardSetSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  final Map<int, bool> predefinedListsChanges = {};
  final List<MyDictionaryListsSheetItem> myListsChanges = [];

  _FlashcardSetSheet(
    this.request,
    this.completer, {
    Key? key,
  }) : super(key: key);

  @override
  State<_FlashcardSetSheet> createState() => _FlashcardSetSheetState();
}

class _FlashcardSetSheetState extends State<_FlashcardSetSheet> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
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
                      'Flashcard Lists',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.completer(
                      SheetResponse(
                        data: FlashcardSetSheetArgument(
                          widget.predefinedListsChanges,
                          widget.myListsChanges,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black),
            const TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.black,
              tabs: [
                Tab(text: 'Vocab'),
                Tab(text: 'Kanji'),
                Tab(text: 'My lists'),
              ],
            ),
            const Divider(height: 1, color: Colors.black),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    children: [
                      CheckboxListTile(
                        title: const Text('JLPT N5'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptN5] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptN5, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N4'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptN4] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptN4, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N3'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptN3] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptN3, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N2'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptN2] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptN2, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N1'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptN1] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptN1, value),
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      CheckboxListTile(
                        title: const Text('Jouyou'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJouyou] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJouyou, value),
                      ),
                    ],
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.request.data.myLists.length,
                    itemBuilder: (context, index) => CheckboxListTile(
                      title: Text(widget.request.data.myLists[index].list.name),
                      value: widget.request.data.myLists[index].enabled,
                      onChanged: (bool? value) {
                        if (value == null) return;
                        setState(() {
                          widget.request.data.myLists[index].enabled = value;
                          if (widget.myListsChanges
                              .contains(widget.request.data.myLists[index])) {
                            widget.myListsChanges
                                .remove(widget.request.data.myLists[index]);
                          } else {
                            widget.myListsChanges
                                .add(widget.request.data.myLists[index]);
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setPredefinedList(int id, bool? value) {
    if (value == null) return;
    setState(() {
      widget.request.data.predefinedLists[id] = value;
      if (widget.predefinedListsChanges.containsKey(id)) {
        widget.predefinedListsChanges.remove(id);
      } else {
        widget.predefinedListsChanges[id] = value;
      }
    });
  }
}

enum BottomSheetType {
  myDictionaryLists,
  flashcardSet,
}

class MyDictionaryListsSheetItem {
  final MyDictionaryList list;
  bool enabled;

  MyDictionaryListsSheetItem(this.list, this.enabled);
}

class FlashcardSetSheetArgument {
  final Map<int, bool> predefinedLists;
  List<MyDictionaryListsSheetItem> myLists;

  FlashcardSetSheetArgument(this.predefinedLists, this.myLists);
}
