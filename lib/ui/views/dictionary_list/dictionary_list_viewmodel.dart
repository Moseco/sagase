import 'dart:async';
import 'dart:io';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as path;
import 'package:sanitize_filename/sanitize_filename.dart' as sanitize_filename;

class DictionaryListViewModel extends FutureViewModel {
  final _navigationService = locator<NavigationService>();
  final _dictionaryService = locator<DictionaryService>();
  final _dialogService = locator<DialogService>();

  DictionaryList dictionaryList;

  List<Vocab>? vocabList;
  List<Kanji>? kanjiList;
  bool get loaded => vocabList != null && kanjiList != null;

  StreamSubscription<DictionaryItemIdsResult>? _myDictionaryListWatcher;

  DictionaryListViewModel(this.dictionaryList);

  @override
  Future<void> futureToRun() async {
    if (dictionaryList is PredefinedDictionaryList) {
      // Get vocab and kanji
      vocabList = await _dictionaryService.getVocabList(dictionaryList.vocab);
      kanjiList = await _dictionaryService.getKanjiList(dictionaryList.kanji);
    } else {
      // Start watching vocab and kanji
      final stream = _dictionaryService
          .watchMyDictionaryListItems(dictionaryList as MyDictionaryList);
      _myDictionaryListWatcher = stream.listen((event) async {
        // If first load, just get everything
        vocabList = await _dictionaryService.getVocabList(event.vocabIds);
        kanjiList = await _dictionaryService.getKanjiList(event.kanjiIds);

        rebuildUi();

        // TODO improve efficiency by loading differences after first load
      });
    }
  }

  Future<void> navigateToVocab(Vocab vocab, int index) async {
    await _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(
        vocab: vocab,
        vocabListIndex: index,
        vocabList: vocabList,
      ),
    );
  }

  Future<void> navigateToKanji(Kanji kanji, int index) async {
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(
        kanji: kanji,
        kanjiListIndex: index,
        kanjiList: kanjiList,
      ),
    );
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
    if (dictionaryList is! MyDictionaryList) return;

    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textField,
      title: 'Rename list',
      description: 'Name',
      mainButtonTitle: 'Update',
      data: dictionaryList.name,
      barrierDismissible: true,
    );

    if (response?.data == null) return;
    final name = (response!.data as String).sanitizeName();
    if (name.isEmpty || dictionaryList.name == name) return;

    dictionaryList = (dictionaryList as MyDictionaryList).copyWith(
      name: name,
      timestamp: DateTime.now(),
    );
    rebuildUi();
    await _dictionaryService.renameMyDictionaryList(
      dictionaryList as MyDictionaryList,
      name,
    );
  }

  Future<void> _deleteMyList() async {
    if (dictionaryList is! MyDictionaryList) return;

    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Delete list?',
      mainButtonTitle: 'Delete',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      // Stop watcher first to avoid unnecessary updates
      _myDictionaryListWatcher?.cancel();
      await _dictionaryService.deleteMyDictionaryList(
        dictionaryList as MyDictionaryList,
      );
      _navigationService.back();
    }
  }

  Future<void> _shareMyList() async {
    if (dictionaryList is! MyDictionaryList) return;

    // Show confirmation dialog
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmation,
      title: 'Share list?',
      description:
          'Sharing this list will create a file that you can send to others. All they have to do is open the file with Sagase or import the list from the my lists screen. No flashcard progress is included.',
      mainButtonTitle: 'Share',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      // Write export to file
      final file = File(
        path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          sanitize_filename
              .sanitizeFilename('${dictionaryList.name} list.sagase')
              .trim(),
        ),
      );

      await file.writeAsString((dictionaryList as MyDictionaryList)
          .copyWith(
            vocab: vocabList?.map((e) => e.id).toList() ?? [],
            kanji: kanjiList?.map((e) => e.id).toList() ?? [],
          )
          .toShareJson());

      // Share the file
      await Share.shareXFiles([XFile(file.path)]);
    }
  }

  @override
  void dispose() {
    _myDictionaryListWatcher?.cancel();
    super.dispose();
  }
}

enum PopupMenuItemType {
  rename,
  delete,
  share,
}
