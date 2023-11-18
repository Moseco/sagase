import 'package:flutter/material.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

class AssignListsBottomSheet extends StatefulWidget {
  final SheetRequest request;
  final Function(SheetResponse) completer;

  const AssignListsBottomSheet({
    required this.request,
    required this.completer,
    super.key,
  });

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
                    onPressed: () => widget.completer(SheetResponse()),
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
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptVocabN5]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptVocabN5,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N4'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptVocabN4]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptVocabN4,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N3'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptVocabN3]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptVocabN3,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N2'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptVocabN2]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptVocabN2,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N1'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptVocabN1]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptVocabN1,
                            value),
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      CheckboxListTile(
                        title: const Text('Jouyou'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJouyou]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants.dictionaryListIdJouyou,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Jinmeiyou'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJinmeiyou]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants.dictionaryListIdJinmeiyou,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N5'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptKanjiN5]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptKanjiN5,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N4'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptKanjiN4]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptKanjiN4,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N3'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptKanjiN3]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptKanjiN3,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N2'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptKanjiN2]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptKanjiN2,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('JLPT N1'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdJlptKanjiN1]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdJlptKanjiN1,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('1st Grade'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdGradeLevel1]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdGradeLevel1,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('2nd Grade'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdGradeLevel2]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdGradeLevel2,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('3rd Grade'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdGradeLevel3]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdGradeLevel3,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('4th Grade'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdGradeLevel4]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdGradeLevel4,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('5th Grade'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdGradeLevel5]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdGradeLevel5,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('6th Grade'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdGradeLevel6]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdGradeLevel6,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 10'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel10]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel10,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 9'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel9]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel9,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 8'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel8]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel8,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 7'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel7]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel7,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 6'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel6]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel6,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 5'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel5]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel5,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 4'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel4]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel4,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 3'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel3]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel3,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level Pre-2'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevelPre2]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevelPre2,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 2'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel2]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel2,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level Pre-1'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevelPre1]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevelPre1,
                            value),
                      ),
                      CheckboxListTile(
                        title: const Text('Kanji Kentei level 1'),
                        value: widget
                                .request
                                .data
                                .predefinedLists[SagaseDictionaryConstants
                                    .dictionaryListIdKenteiLevel1]
                                ?.enabled ??
                            false,
                        onChanged: (bool? value) => _setPredefinedList(
                            SagaseDictionaryConstants
                                .dictionaryListIdKenteiLevel1,
                            value),
                      ),
                    ],
                  ),
                  ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: widget.request.data.myLists.length,
                    itemBuilder: (context, index) => CheckboxListTile(
                      title: Text(widget.request.data.myLists[index].list.name),
                      value: widget.request.data.myLists[index].enabled,
                      onChanged: (bool? value) {
                        if (value == null) return;
                        setState(() {
                          widget.request.data.myLists[index].changed =
                              !widget.request.data.myLists[index].changed;
                          widget.request.data.myLists[index].enabled = value;
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
      if (widget.request.data.predefinedLists.containsKey(id)) {
        widget.request.data.predefinedLists[id] = (
          enabled: value,
          changed: !widget.request.data.predefinedLists[id].changed,
        );
      } else {
        widget.request.data.predefinedLists[id] =
            (enabled: value, changed: true);
      }
    });
  }
}
