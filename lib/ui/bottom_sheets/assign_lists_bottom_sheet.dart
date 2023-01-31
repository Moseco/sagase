import 'package:flutter/material.dart';
import 'package:sagase/datamodels/lists_bottom_sheet_argument.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' as constants;

class AssignListsBottomSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  final Map<int, bool> predefinedListsChanges = {};
  final List<MyListsBottomSheetItem> myListsChanges = [];

  AssignListsBottomSheet({
    required this.request,
    required this.completer,
    Key? key,
  }) : super(key: key);

  @override
  State<AssignListsBottomSheet> createState() => AssignListsBottomSheetState();
}

class AssignListsBottomSheetState extends State<AssignListsBottomSheet> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Container(
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
                        data: ListsBottomSheetArgument(
                          widget.predefinedListsChanges,
                          widget.myListsChanges,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            TabBar(
              labelColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : null,
              indicatorColor: Theme.of(context).brightness == Brightness.light
                  ? Colors.black
                  : null,
              tabs: const [
                Tab(text: 'Vocab'),
                Tab(text: 'Kanji'),
                Tab(text: 'My lists'),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    children: [
                      CheckboxListTile(
                        title: const Text('JLPT N5'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptVocabN5] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptVocabN5, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N4'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptVocabN4] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptVocabN4, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N3'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptVocabN3] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptVocabN3, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N2'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptVocabN2] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptVocabN2, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N1'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptVocabN1] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptVocabN1, value),
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
                      CheckboxListTile(
                        title: const Text('Jinmeiyou'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJinmeiyou] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJinmeiyou, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N5'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptKanjiN5] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptKanjiN5, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N4'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptKanjiN4] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptKanjiN4, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N3'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptKanjiN3] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptKanjiN3, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N2'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptKanjiN2] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptKanjiN2, value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N1'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdJlptKanjiN1] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdJlptKanjiN1, value),
                      ),
                      CheckboxListTile(
                        title: const Text('1st Grade'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdGradeLevel1] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdGradeLevel1, value),
                      ),
                      CheckboxListTile(
                        title: const Text('2nd Grade'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdGradeLevel2] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdGradeLevel2, value),
                      ),
                      CheckboxListTile(
                        title: const Text('3rd Grade'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdGradeLevel3] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdGradeLevel3, value),
                      ),
                      CheckboxListTile(
                        title: const Text('4th Grade'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdGradeLevel4] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdGradeLevel4, value),
                      ),
                      CheckboxListTile(
                        title: const Text('5th Grade'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdGradeLevel5] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdGradeLevel5, value),
                      ),
                      CheckboxListTile(
                        title: const Text('6th Grade'),
                        value: widget.request.data.predefinedLists[
                                constants.dictionaryListIdGradeLevel6] ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            constants.dictionaryListIdGradeLevel6, value),
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
