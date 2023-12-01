import 'package:flutter/material.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';

import 'lists_viewmodel.dart';

class ListsView extends StackedView<ListsViewModel> {
  final ListSelection listSelection;

  const ListsView({this.listSelection = ListSelection.main, super.key});

  @override
  ListsViewModel viewModelBuilder(context) => ListsViewModel(listSelection);

  @override
  Widget builder(context, viewModel, child) {
    return Scaffold(
      body: switch (viewModel.listSelection) {
        ListSelection.main => _MainList(),
        ListSelection.vocab => _VocabList(),
        ListSelection.kanji => _KanjiList(),
        ListSelection.myLists => _MyLists(),
        ListSelection.jlptKanji => _JlptKanjiList(),
        ListSelection.schoolKanji => _SchoolKanjiList(),
        ListSelection.kanjiKentei => _KanjiKenteiList(),
      },
    );
  }
}

class _MainList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: const Text(
        'Lists',
        maxLines: 1,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
        ),
      ),
      child: ListView(
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
      ),
    );
  }
}

class _VocabList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: viewModel.back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Vocab Lists',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: () => viewModel.showDescriptionDialog(
                'JLPT Vocab',
                'JLPT (Japanese-Language Proficiency Test) is a test that gauges Japanese ability, recognized by the Japanese government and many companies. N5 is the easiest and N1 is the hardest. These are not official lists. They are a best guess of the required vocabulary.',
              ),
              color: Colors.white,
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      child: ListView(
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
        ],
      ),
    );
  }
}

class _KanjiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: viewModel.back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Kanji Lists',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: () {},
              color: Colors.transparent,
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      child: ListView(
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
      ),
    );
  }
}

class _JlptKanjiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: viewModel.back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'JLPT Kanji',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: () => viewModel.showDescriptionDialog(
                'JLPT Kanji',
                'JLPT (Japanese-Language Proficiency Test) is a test that gauges Japanese ability, recognized by the Japanese government and many companies. N5 is the easiest and N1 is the hardest. These are not official lists. They are a best guess of the required kanji.',
              ),
              color: Colors.white,
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      child: ListView(
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
        ],
      ),
    );
  }
}

class _SchoolKanjiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: viewModel.back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'School Kanji',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: () => viewModel.showDescriptionDialog(
                'School Kanji',
                'These lists represent the 1,026 kanji that are to be learned at each grade level as defined by the Japanese Ministry of Education. The remainder of the jouyou set is expected to be learned during middle school, but there is no official order and it can vary by textbook and school.',
              ),
              color: Colors.white,
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      child: ListView(
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
        ],
      ),
    );
  }
}

class _KanjiKenteiList extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: viewModel.back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'Kanji Kentei',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: () => viewModel.showDescriptionDialog(
                'Kanji Kentei',
                'Kanji Kentei, formally The Japan Kanji Aptitude Test (日本漢字能力検定), also known as Kanken, is a kanji exam which tests various aspects of kanji knowledge. The easiest test is level 10 (consisting of 80 kanji) and the hardest is level 1 (consisting of about 6300 kanji). Levels 10 through 5 correspond to the grade school kanji lists.',
              ),
              color: Colors.white,
              icon: const Icon(Icons.help),
            ),
          ),
        ],
      ),
      child: ListView(
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
        ],
      ),
    );
  }
}

class _MyLists extends ViewModelWidget<ListsViewModel> {
  @override
  Widget build(BuildContext context, ListsViewModel viewModel) {
    return HomeHeader(
      title: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BackButton(
              onPressed: viewModel.back,
              color: Colors.white,
            ),
          ),
          const Expanded(
            child: Text(
              'My Lists',
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: IconButton(
              onPressed: viewModel.createMyDictionaryList,
              color: Colors.white,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      child: viewModel.myDictionaryLists == null
          ? const Center(child: CircularProgressIndicator())
          : viewModel.myDictionaryLists!.isEmpty
              ? const _NoMyLists()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: viewModel.myDictionaryLists!.length,
                  itemBuilder: (context, index) {
                    final current = viewModel.myDictionaryLists![index];
                    return _DictionaryListItem(
                      text: current.name,
                      onTap: () =>
                          viewModel.navigateToMyDictionaryList(current),
                    );
                  },
                ),
    );
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
  }) : assert(leadingText != null || leadingIcon != null);

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
                            height: 1.2,
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
