import 'dart:async';
import 'dart:io';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/ui/dialogs/flashcard_set_select_dialog.dart';
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
  List<Grammar>? grammarList;
  bool get loaded =>
      vocabList != null && kanjiList != null && grammarList != null;

  StreamSubscription<DictionaryItemIdsResult>? _myDictionaryListWatcher;

  DictionaryListViewModel(this.dictionaryList);

  @override
  Future<void> futureToRun() async {
    if (dictionaryList is PredefinedDictionaryList) {
      // Get vocab and kanji
      vocabList = await _dictionaryService.getVocabList(dictionaryList.vocab);
      kanjiList = await _dictionaryService.getKanjiList(dictionaryList.kanji);
      grammarList =
          await _dictionaryService.getGrammarList(dictionaryList.grammar);
    } else {
      // Start watching vocab and kanji
      final stream = _dictionaryService
          .watchMyDictionaryListItems(dictionaryList as MyDictionaryList);
      _myDictionaryListWatcher = stream.listen((event) async {
        if (vocabList == null) {
          // First load, get everything
          vocabList = await _dictionaryService.getVocabList(event.vocabIds);
          kanjiList = await _dictionaryService.getKanjiList(event.kanjiIds);
          grammarList =
              await _dictionaryService.getGrammarList(event.grammarIds);
        } else {
          // Compute diffs against current state
          final newVocabIds = event.vocabIds.toSet();
          final newKanjiIds = event.kanjiIds.toSet();
          final newGrammarIds = event.grammarIds.toSet();

          final addedVocabIds =
              newVocabIds.difference(vocabList!.map((e) => e.id).toSet());
          final addedKanjiIds =
              newKanjiIds.difference(kanjiList!.map((e) => e.id).toSet());
          final addedGrammarIds =
              newGrammarIds.difference(grammarList!.map((e) => e.id).toSet());

          // Remove deleted items
          vocabList!.removeWhere((e) => !newVocabIds.contains(e.id));
          kanjiList!.removeWhere((e) => !newKanjiIds.contains(e.id));
          grammarList!.removeWhere((e) => !newGrammarIds.contains(e.id));

          // Fetch and append added items
          vocabList!.insertAll(
            0,
            await _dictionaryService.getVocabList(addedVocabIds.toList()),
          );
          kanjiList!.insertAll(
            0,
            await _dictionaryService.getKanjiList(addedKanjiIds.toList()),
          );
          grammarList!.insertAll(
            0,
            await _dictionaryService.getGrammarList(addedGrammarIds.toList()),
          );
        }

        rebuildUi();
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

  Future<void> navigateToGrammar(Grammar grammar, int index) async {
    await _navigationService.navigateTo(
      Routes.grammarView,
      arguments: GrammarViewArguments(
        grammar: grammar,
        grammarListIndex: index,
        grammarList: grammarList,
      ),
    );
  }

  Future<void> studyFlashcards() async {
    final isPredefined = dictionaryList is PredefinedDictionaryList;
    final listId = dictionaryList.id;

    final flashcardSets = await _dictionaryService.getFlashcardSets();
    final matching = <FlashcardSet>[];
    final others = <FlashcardSet>[];
    for (final set in flashcardSets) {
      final containsList = isPredefined
          ? set.predefinedDictionaryLists.contains(listId)
          : set.myDictionaryLists.contains(listId);
      if (containsList) {
        matching.add(set);
      } else {
        others.add(set);
      }
    }

    FlashcardSet flashcardSet;
    if (flashcardSets.isEmpty) {
      final created = await _createFlashcardSetForList();
      if (created == null) return;
      flashcardSet = created;
    } else {
      final response = await _dialogService.showCustomDialog(
        variant: DialogType.flashcardSetSelect,
        data: (matching: matching, others: others),
        barrierDismissible: true,
      );
      if (response?.data is! FlashcardSetSelectResult) return;
      final result = response!.data as FlashcardSetSelectResult;

      switch (result) {
        case FlashcardSetSelectOpen(flashcardSet: final set):
          flashcardSet = set;
        case FlashcardSetSelectAddToExisting(flashcardSet: final set):
          if (isPredefined) {
            set.predefinedDictionaryLists.add(listId);
          } else {
            set.myDictionaryLists.add(listId);
          }
          await _dictionaryService.updateFlashcardSet(set);
          flashcardSet = set;
        case FlashcardSetSelectCreateNew():
          final created = await _createFlashcardSetForList();
          if (created == null) return;
          flashcardSet = created;
      }
    }

    await _navigationService.navigateTo(
      Routes.flashcardsView,
      arguments: FlashcardsViewArguments(flashcardSet: flashcardSet),
    );
  }

  Future<FlashcardSet?> _createFlashcardSetForList() async {
    final nameResponse = await _dialogService.showCustomDialog(
      variant: DialogType.textField,
      title: 'Create flashcard set',
      description: 'Name',
      mainButtonTitle: 'Create',
      data: dictionaryList.name,
      barrierDismissible: true,
    );

    if (nameResponse?.data == null) return null;
    final name = (nameResponse!.data as String).sanitizeName();
    if (name.isEmpty) return null;

    final flashcardSet = await _dictionaryService.createFlashcardSet(name);
    if (dictionaryList is PredefinedDictionaryList) {
      flashcardSet.predefinedDictionaryLists.add(dictionaryList.id);
    } else {
      flashcardSet.myDictionaryLists.add(dictionaryList.id);
    }
    await _dictionaryService.updateFlashcardSet(flashcardSet);
    return flashcardSet;
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
            grammar: grammarList?.map((e) => e.id).toList() ?? [],
          )
          .toShareJson());

      // Share the file
      SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)]),
      );
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
