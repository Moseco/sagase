import 'package:flutter/material.dart';
import 'package:sagase/ui/bottom_sheets/base_bottom_sheet.dart';
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
  final List<int> _path = [];

  @override
  Widget build(BuildContext context) {
    final root = _buildRoot();
    _Folder current = root;
    for (final index in _path) {
      current = current.children[index] as _Folder;
    }

    return BaseBottomSheet(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _path.isEmpty
                      ? null
                      : () => setState(() => _path.removeLast()),
                  icon: Icon(
                    Icons.arrow_back,
                    color: _path.isEmpty ? Colors.transparent : null,
                  ),
                ),
                Expanded(
                  child: Text(
                    _path.isEmpty ? 'Flashcard Lists' : current.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
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
              itemCount: current.children.length,
              itemBuilder: (context, index) {
                final node = current.children[index];
                return switch (node) {
                  _Folder() => ListTile(
                      key: node.key,
                      leading: const Icon(Icons.folder),
                      title: Text(node.title),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setState(() => _path.add(index)),
                    ),
                  _DictionaryList() => CheckboxListTile(
                      key: node.key,
                      secondary: const Icon(Icons.format_list_bulleted),
                      title: Text(node.title),
                      value: node.value,
                      onChanged: node.onChanged,
                    ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  _Folder _buildRoot() {
    return _Folder('Flashcard Lists', [
      _Folder('My lists', [
        for (int i = 0; i < widget.request.data.myLists.length; i++)
          _DictionaryList(
            key: ValueKey('my-list:${widget.request.data.myLists[i].list.id}'),
            title: widget.request.data.myLists[i].list.name,
            value: widget.request.data.myLists[i].enabled,
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                widget.request.data.myLists[i].changed =
                    !widget.request.data.myLists[i].changed;
                widget.request.data.myLists[i].enabled = value;
              });
            },
          ),
      ]),
      _Folder('Vocabulary', [
        _Folder('Core Vocab', [
          _predefined('2k', SagaseDictionaryConstants.dictionaryListId2k),
          _predefined('6k', SagaseDictionaryConstants.dictionaryListId6k),
          _predefined('10k', SagaseDictionaryConstants.dictionaryListId10k),
        ]),
        _Folder('JLPT Vocab', [
          _predefined(
            'JLPT N5',
            SagaseDictionaryConstants.dictionaryListIdJlptVocabN5,
          ),
          _predefined(
            'JLPT N4',
            SagaseDictionaryConstants.dictionaryListIdJlptVocabN4,
          ),
          _predefined(
            'JLPT N3',
            SagaseDictionaryConstants.dictionaryListIdJlptVocabN3,
          ),
          _predefined(
            'JLPT N2',
            SagaseDictionaryConstants.dictionaryListIdJlptVocabN2,
          ),
          _predefined(
            'JLPT N1',
            SagaseDictionaryConstants.dictionaryListIdJlptVocabN1,
          ),
        ]),
        _predefined(
          'Kaishi 1.5k',
          SagaseDictionaryConstants.dictionaryListIdKaishi,
        ),
      ]),
      _Folder('Kanji', [
        _Folder('JLPT Kanji', [
          _predefined(
            'JLPT N5',
            SagaseDictionaryConstants.dictionaryListIdJlptKanjiN5,
          ),
          _predefined(
            'JLPT N4',
            SagaseDictionaryConstants.dictionaryListIdJlptKanjiN4,
          ),
          _predefined(
            'JLPT N3',
            SagaseDictionaryConstants.dictionaryListIdJlptKanjiN3,
          ),
          _predefined(
            'JLPT N2',
            SagaseDictionaryConstants.dictionaryListIdJlptKanjiN2,
          ),
          _predefined(
            'JLPT N1',
            SagaseDictionaryConstants.dictionaryListIdJlptKanjiN1,
          ),
        ]),
        _Folder('Kanji by Grade Level', [
          _predefined(
            '1st Grade',
            SagaseDictionaryConstants.dictionaryListIdGradeLevel1,
          ),
          _predefined(
            '2nd Grade',
            SagaseDictionaryConstants.dictionaryListIdGradeLevel2,
          ),
          _predefined(
            '3rd Grade',
            SagaseDictionaryConstants.dictionaryListIdGradeLevel3,
          ),
          _predefined(
            '4th Grade',
            SagaseDictionaryConstants.dictionaryListIdGradeLevel4,
          ),
          _predefined(
            '5th Grade',
            SagaseDictionaryConstants.dictionaryListIdGradeLevel5,
          ),
          _predefined(
            '6th Grade',
            SagaseDictionaryConstants.dictionaryListIdGradeLevel6,
          ),
        ]),
        _Folder('Kanji Kentei', [
          _predefined(
            'Level 10',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel10,
          ),
          _predefined(
            'Level 9',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel9,
          ),
          _predefined(
            'Level 8',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel8,
          ),
          _predefined(
            'Level 7',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel7,
          ),
          _predefined(
            'Level 6',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel6,
          ),
          _predefined(
            'Level 5',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel5,
          ),
          _predefined(
            'Level 4',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel4,
          ),
          _predefined(
            'Level 3',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel3,
          ),
          _predefined(
            'Level Pre-2',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevelPre2,
          ),
          _predefined(
            'Level 2',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel2,
          ),
          _predefined(
            'Level Pre-1',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevelPre1,
          ),
          _predefined(
            'Level 1',
            SagaseDictionaryConstants.dictionaryListIdKenteiLevel1,
          ),
        ]),
        _predefined(
          'Jouyou',
          SagaseDictionaryConstants.dictionaryListIdJouyou,
        ),
        _predefined(
          'Jinmeiyou',
          SagaseDictionaryConstants.dictionaryListIdJinmeiyou,
        ),
      ]),
      _Folder('Grammar', [
        _predefined(
          'JLPT N5',
          SagaseDictionaryConstants.dictionaryListIdJlptGrammarN5,
        ),
        _predefined(
          'JLPT N4',
          SagaseDictionaryConstants.dictionaryListIdJlptGrammarN4,
        ),
        _predefined(
          'JLPT N3',
          SagaseDictionaryConstants.dictionaryListIdJlptGrammarN3,
        ),
        _predefined(
          'JLPT N2',
          SagaseDictionaryConstants.dictionaryListIdJlptGrammarN2,
        ),
        _predefined(
          'JLPT N1',
          SagaseDictionaryConstants.dictionaryListIdJlptGrammarN1,
        ),
      ]),
    ]);
  }

  _DictionaryList _predefined(String title, int id) {
    return _DictionaryList(
      key: ValueKey('predefined:$id'),
      title: title,
      value: widget.request.data.predefinedLists[id]?.enabled ?? false,
      onChanged: (value) => _setPredefinedList(id, value),
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

sealed class _Node {
  final Key? key;
  final String title;
  const _Node(this.title, {this.key});
}

class _Folder extends _Node {
  final List<_Node> children;
  const _Folder(super.title, this.children);
}

class _DictionaryList extends _Node {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _DictionaryList({
    required String title,
    required this.value,
    required this.onChanged,
    super.key,
  }) : super(title);
}
