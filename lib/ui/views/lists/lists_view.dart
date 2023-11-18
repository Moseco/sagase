import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import 'lists_viewmodel.dart';

class ListsView extends StatelessWidget {
  final ListSelection? selection;

  const ListsView({this.selection, super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ListsViewModel>.reactive(
      viewModelBuilder: () => ListsViewModel(selection),
      builder: (context, viewModel, child) => Scaffold(
        body: HomeHeader(
          title: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: BackButton(
                  onPressed: () => viewModel.back(),
                  color: viewModel.listSelection == null
                      ? Colors.transparent
                      : Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  _getTitle(viewModel.listSelection),
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: viewModel.createMyDictionaryList,
                  color: viewModel.listSelection == ListSelection.myLists
                      ? Colors.white
                      : Colors.transparent,
                  icon: const Icon(Icons.add),
                ),
              ),
            ],
          ),
          child: _Body(),
        ),
      ),
    );
  }

  String _getTitle(ListSelection? selection) {
    switch (selection) {
      case ListSelection.vocab:
        return 'Vocab Lists';
      case ListSelection.kanji:
        return 'Kanji Lists';
      case ListSelection.myLists:
        return 'My Lists';
      case ListSelection.jlptKanji:
        return 'JLPT Kanji';
      case ListSelection.schoolKanji:
        return 'School Kanji';
      case ListSelection.kanjiKentei:
        return 'Kanji Kentei';
      default:
        return 'Lists';
    }
  }
}

class _Body extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    switch (viewModel.listSelection) {
      case ListSelection.vocab:
        return _VocabList();
      case ListSelection.kanji:
        return _KanjiList();
      case ListSelection.myLists:
        return _MyLists();
      case ListSelection.jlptKanji:
        return _JlptKanjiList();
      case ListSelection.schoolKanji:
        return _SchoolKanjiList();
      case ListSelection.kanjiKentei:
        return _KanjiKenteiList();
      default:
        return _MainList();
    }
  }
}

class _MainList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MainListItem(
          leadingText: '語',
          titleText: 'Vocabulary',
          onTap: () => viewModel.setListSelection(ListSelection.vocab),
        ),
        _MainListItem(
          leadingText: '字',
          titleText: 'Kanji',
          onTap: () => viewModel.setListSelection(ListSelection.kanji),
        ),
        _MainListItem(
          leadingIcon: Icons.star,
          titleText: 'My lists',
          onTap: () => viewModel.setListSelection(ListSelection.myLists),
        ),
        _MainListItem(
          leadingText: 'あ',
          titleText: 'Kana',
          onTap: viewModel.navigateToKana,
        ),
        _MainListItem(
          leadingText: '廴',
          titleText: 'Radicals',
          onTap: viewModel.navigateToRadicals,
        ),
      ],
    );
  }
}

class _VocabList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: 'JLPT N5',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptVocabN5),
        ),
        _DictionaryListItem(
          text: 'JLPT N4',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptVocabN4),
        ),
        _DictionaryListItem(
          text: 'JLPT N3',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptVocabN3),
        ),
        _DictionaryListItem(
          text: 'JLPT N2',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptVocabN2),
        ),
        _DictionaryListItem(
          text: 'JLPT N1',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptVocabN1),
        ),
        const Text(
          'These are not official lists. They are a best guess of the required vocabulary.',
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

class _KanjiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: 'Jouyou',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJouyou),
        ),
        _DictionaryListItem(
          text: 'Jinmeiyou',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJinmeiyou),
        ),
        _DictionaryListItem(
          text: 'JLPT Kanji',
          onTap: () => viewModel.setListSelection(ListSelection.jlptKanji),
          isFolder: true,
        ),
        _DictionaryListItem(
          text: 'Kanji by Grade Level',
          onTap: () => viewModel.setListSelection(ListSelection.schoolKanji),
          isFolder: true,
        ),
        _DictionaryListItem(
          text: 'Kanji Kentei',
          onTap: () => viewModel.setListSelection(ListSelection.kanjiKentei),
          isFolder: true,
        ),
      ],
    );
  }
}

class _JlptKanjiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: 'JLPT N5',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptKanjiN5),
        ),
        _DictionaryListItem(
          text: 'JLPT N4',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptKanjiN4),
        ),
        _DictionaryListItem(
          text: 'JLPT N3',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptKanjiN3),
        ),
        _DictionaryListItem(
          text: 'JLPT N2',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptKanjiN2),
        ),
        _DictionaryListItem(
          text: 'JLPT N1',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdJlptKanjiN1),
        ),
        const Text(
          'These are not official lists. They are a best guess of the required kanji.',
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

class _SchoolKanjiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: '1st Grade',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdGradeLevel1),
        ),
        _DictionaryListItem(
          text: '2nd Grade',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdGradeLevel2),
        ),
        _DictionaryListItem(
          text: '3rd Grade',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdGradeLevel3),
        ),
        _DictionaryListItem(
          text: '4th Grade',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdGradeLevel4),
        ),
        _DictionaryListItem(
          text: '5th Grade',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdGradeLevel5),
        ),
        _DictionaryListItem(
          text: '6th Grade',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdGradeLevel6),
        ),
        const Text(
          'These lists represent the 1,026 kanji that are to be learned at each grade level as defined by the Japanese Ministry of Education. The remainder of the jouyou set is expected to be learned during middle school and high school, but there is no official order and it can vary by textbook and school.',
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

class _KanjiKenteiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: 'Level 10',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel10),
        ),
        _DictionaryListItem(
          text: 'Level 9',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel9),
        ),
        _DictionaryListItem(
          text: 'Level 8',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel8),
        ),
        _DictionaryListItem(
          text: 'Level 7',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel7),
        ),
        _DictionaryListItem(
          text: 'Level 6',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel6),
        ),
        _DictionaryListItem(
          text: 'Level 5',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel5),
        ),
        _DictionaryListItem(
          text: 'Level 4',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel4),
        ),
        _DictionaryListItem(
          text: 'Level 3',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel3),
        ),
        _DictionaryListItem(
          text: 'Level Pre-2',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevelPre2),
        ),
        _DictionaryListItem(
          text: 'Level 2',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel2),
        ),
        _DictionaryListItem(
          text: 'Level Pre-1',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevelPre1),
        ),
        _DictionaryListItem(
          text: 'Level 1',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              SagaseDictionaryConstants.dictionaryListIdKenteiLevel1),
        ),
        const Text(
          'Kanji Kentei (formally The Japan Kanji Aptitude Test, 日本漢字能力検定, also known as Kanken) is a kanji exam which tests various aspects of kanji knowledge. The easiest test is level 10 (consisting of 80 kanji) and the hardest is level 1 (consisting of about 6300 kanji). Levels 10 through 5 correspond to the grade school kanji lists.',
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }
}

class _MyLists extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    if (viewModel.myDictionaryLists == null) {
      return const Center(child: CircularProgressIndicator());
    } else if (viewModel.myDictionaryLists!.isEmpty) {
      return const _NoMyLists();
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: viewModel.myDictionaryLists!.length,
        itemBuilder: (context, index) {
          final current = viewModel.myDictionaryLists![index];
          return _DictionaryListItem(
            text: current.name,
            onTap: () => viewModel.navigateToMyDictionaryList(current),
          );
        },
      );
    }
  }
}

class _NoMyLists extends ViewModelWidget<ListsViewModel> {
  const _NoMyLists();

  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'You have no my lists. Try creating one to save important vocab and kanji.',
              textAlign: TextAlign.center,
            ),
            TextButton.icon(
              onPressed: viewModel.createMyDictionaryList,
              icon: const Icon(Icons.add),
              label: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainListItem extends StatelessWidget {
  final String? leadingText;
  final IconData? leadingIcon;
  final String titleText;
  final void Function() onTap;

  const _MainListItem({
    this.leadingText,
    this.leadingIcon,
    required this.titleText,
    required this.onTap,
  })  : assert(leadingText != null || leadingIcon != null);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurple,
                ),
                child: Center(
                  child: leadingIcon != null
                      ? Icon(
                          leadingIcon,
                          color: Colors.white,
                        )
                      : Text(
                          leadingText!,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    titleText,
                    style: const TextStyle(fontSize: 24),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DictionaryListItem extends StatelessWidget {
  final String text;
  final void Function() onTap;
  final bool isFolder;

  const _DictionaryListItem({
    required this.text,
    required this.onTap,
    this.isFolder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(isFolder ? Icons.folder : Icons.format_list_bulleted),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 24),
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
