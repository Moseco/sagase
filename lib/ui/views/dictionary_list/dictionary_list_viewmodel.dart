import 'dart:async';

import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

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

  Future<void> renameMyList() async {
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

  Future<void> deleteMyList() async {
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

  @override
  void dispose() {
    _myListWatcher?.cancel();
    super.dispose();
  }
}
