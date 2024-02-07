import 'dart:async';
import 'dart:io';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;

class DictionaryListViewModel extends FutureViewModel {
  final _navigationService = locator<NavigationService>();
  final _isarService = locator<IsarService>();
  final _dialogService = locator<DialogService>();

  DictionaryList dictionaryList;

  late List<Vocab> vocab;
  late List<Kanji> kanji;

  StreamSubscription<void>? _myListWatcher;
  bool _myListChanged = false;

  DictionaryListViewModel(this.dictionaryList);

  @override
  Future<void> futureToRun() async {
    vocab = await _isarService.getVocabList(dictionaryList.getVocab());
    kanji = await _isarService.getKanjiList(dictionaryList.getKanji());
    rebuildUi();
  }

  void _startWatcher() {
    // If MyDictionaryList start watching for changes
    if (dictionaryList is MyDictionaryList) {
      _myListWatcher ??=
          _isarService.watchMyDictionaryList(dictionaryList.id).listen((event) {
        _myListChanged = true;
      });
    }
  }

  Future<void> _refreshMyList() async {
    if (!_myListChanged) return;

    final newList = await _isarService.getMyDictionaryList(dictionaryList.id);
    if (newList == null) return;
    dictionaryList = newList;
    // Reload vocab and kanji
    vocab = await _isarService.getVocabList(dictionaryList.getVocab());
    kanji = await _isarService.getKanjiList(dictionaryList.getKanji());

    _myListChanged = false;

    rebuildUi();
  }

  Future<void> navigateToVocab(Vocab vocab) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
    await _refreshMyList();
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    _startWatcher();
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
    await _refreshMyList();
  }

  void handlePopupMenuButton(PopupMenuItemType type) {
    switch (type) {
      case PopupMenuItemType.rename:
        _renameMyList();
        break;
      case PopupMenuItemType.delete:
        _deleteMyList();
        break;
      case PopupMenuItemType.share:
        _shareMyList();
        break;
    }
  }

  Future<void> _renameMyList() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textField,
      title: 'Rename list',
      description: 'Name',
      mainButtonTitle: 'Update',
      data: dictionaryList.name,
      barrierDismissible: true,
    );

    String? name = response?.data?.trim();
    if (name == null || name.isEmpty || dictionaryList.name == name) return;

    dictionaryList.name = name;
    _isarService.updateMyDictionaryList(dictionaryList as MyDictionaryList);
    rebuildUi();
  }

  Future<void> _deleteMyList() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Delete list?',
      mainButtonTitle: 'Delete',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      await _isarService
          .deleteMyDictionaryList(dictionaryList as MyDictionaryList);
      _navigationService.back();
    }
  }

  Future<void> _shareMyList() async {
    // Show confirmation dialog
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Share list?',
      description:
          'Sharing this list will create a file that you can send to others. All they have to do is import the list from the my lists screen. No flashcard progress is included.',
      mainButtonTitle: 'Share',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      // Write export to file
      final file = File(
        path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          '${dictionaryList.name} list.sagase',
        ),
      );

      await file.writeAsString(
        (dictionaryList as MyDictionaryList).toExportJson(),
      );

      // Share the file
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  @override
  void dispose() {
    _myListWatcher?.cancel();
    super.dispose();
  }
}

enum PopupMenuItemType {
  rename,
  delete,
  share,
}
