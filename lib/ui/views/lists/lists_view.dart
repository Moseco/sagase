import 'package:flutter/material.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/ui/widgets/home_header.dart';
import 'package:stacked/stacked.dart';
import 'package:sagase/utils/constants.dart' as constants;

import 'lists_viewmodel.dart';

class ListsView extends StatelessWidget {
  const ListsView({super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<ListsViewModel>.reactive(
      disposeViewModel: false,
      initialiseSpecialViewModelsOnce: true,
      viewModelBuilder: () => locator<ListsViewModel>(),
      builder: (context, viewModel, child) => Scaffold(
        body: HomeHeader(
          title: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  onPressed: () => viewModel.setListSelection(null),
                  color: viewModel.listSelection == null
                      ? Colors.transparent
                      : Colors.white,
                  icon: const Icon(Icons.arrow_back),
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
          child: WillPopScope(
            onWillPop: () async {
              if (viewModel.listSelection != null) {
                viewModel.setListSelection(null);
                return false;
              }
              return true;
            },
            child: _Body(),
          ),
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
              constants.dictionaryListIdJlptN5),
        ),
        _DictionaryListItem(
          text: 'JLPT N4',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              constants.dictionaryListIdJlptN4),
        ),
        _DictionaryListItem(
          text: 'JLPT N3',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              constants.dictionaryListIdJlptN3),
        ),
        _DictionaryListItem(
          text: 'JLPT N2',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              constants.dictionaryListIdJlptN2),
        ),
        _DictionaryListItem(
          text: 'JLPT N1',
          onTap: () => viewModel.navigateToPredefinedDictionaryList(
              constants.dictionaryListIdJlptN1),
        ),
        const Text(
          'These are not official lists. They are a best guess of the required vocabulary.',
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
              constants.dictionaryListIdJouyou),
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
              const Icon(Icons.format_list_bulleted),
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
