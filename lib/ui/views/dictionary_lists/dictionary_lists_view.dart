import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/constants.dart' as constants;

import 'dictionary_lists_viewmodel.dart';

class DictionaryListsView extends StatelessWidget {
  const DictionaryListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<DictionaryListsViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<DictionaryListsViewModel>(),
      builder: (context, viewModel, child) => Scaffold(
        body: HomeHeader(
          title: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => viewModel.setCurrentList(null),
                  color: viewModel.currentList == null
                      ? Colors.transparent
                      : Colors.white,
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Expanded(
                child: Text(
                  _getTitle(viewModel.currentList),
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
                  onPressed: () {},
                  color: viewModel.currentList == MainListSelection.myLists
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

  String _getTitle(MainListSelection? selection) {
    switch (selection) {
      case MainListSelection.vocab:
        return 'Vocab Lists';
      case MainListSelection.kanji:
        return 'Kanji Lists';
      case MainListSelection.myLists:
        return 'My Lists';
      default:
        return 'Lists';
    }
  }
}

class _Body extends ViewModelWidget<DictionaryListsViewModel> {
  @override
  Widget build(BuildContext context, DictionaryListsViewModel viewModel) {
    switch (viewModel.currentList) {
      case MainListSelection.vocab:
        return _VocabList();
      case MainListSelection.kanji:
        return _KanjiList();
      case MainListSelection.myLists:
        return _MyListsList();
      default:
        return _MainList();
    }
  }
}

class _MainList extends ViewModelWidget<DictionaryListsViewModel> {
  @override
  Widget build(BuildContext context, DictionaryListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _MainListItem(
          leadingText: '語',
          titleText: 'Vocabulary',
          onTap: () => viewModel.setCurrentList(MainListSelection.vocab),
        ),
        _MainListItem(
          leadingText: '字',
          titleText: 'Kanji',
          onTap: () => viewModel.setCurrentList(MainListSelection.kanji),
        ),
        _MainListItem(
          leadingIcon: Icons.star,
          titleText: 'My lists',
          onTap: () => viewModel.setCurrentList(MainListSelection.myLists),
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

class _VocabList extends ViewModelWidget<DictionaryListsViewModel> {
  @override
  Widget build(BuildContext context, DictionaryListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: 'JLPT N5',
          onTap: () =>
              viewModel.navigateToList(constants.dictionaryListIdJlptN5),
        ),
        _DictionaryListItem(
          text: 'JLPT N4',
          onTap: () =>
              viewModel.navigateToList(constants.dictionaryListIdJlptN4),
        ),
        _DictionaryListItem(
          text: 'JLPT N3',
          onTap: () =>
              viewModel.navigateToList(constants.dictionaryListIdJlptN3),
        ),
        _DictionaryListItem(
          text: 'JLPT N2',
          onTap: () =>
              viewModel.navigateToList(constants.dictionaryListIdJlptN2),
        ),
        _DictionaryListItem(
          text: 'JLPT N1',
          onTap: () =>
              viewModel.navigateToList(constants.dictionaryListIdJlptN1),
        ),
        const Text(
          'These are not official lists. They are a best guess of the required vocabulary.',
        ),
      ],
    );
  }
}

class _KanjiList extends ViewModelWidget<DictionaryListsViewModel> {
  @override
  Widget build(BuildContext context, DictionaryListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DictionaryListItem(
          text: 'Jouyou',
          onTap: () =>
              viewModel.navigateToList(constants.dictionaryListIdJouyou),
        ),
      ],
    );
  }
}

class _MyListsList extends ViewModelWidget<DictionaryListsViewModel> {
  @override
  Widget build(BuildContext context, DictionaryListsViewModel viewModel) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('TODO My lists'),
      ],
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
    Key? key,
  })  : assert(leadingText != null || leadingIcon != null),
        super(key: key);

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

  const _DictionaryListItem({
    required this.text,
    required this.onTap,
    Key? key,
  }) : super(key: key);

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
              const Icon(
                Icons.format_list_bulleted,
                color: Colors.black,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    text,
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
