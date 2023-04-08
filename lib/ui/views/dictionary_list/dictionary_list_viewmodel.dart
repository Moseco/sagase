import 'package:sagase/app/app.dialog.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/app/app.router.dart';
import 'package:sagase/datamodels/dictionary_list.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class DictionaryListViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _isarService = locator<IsarService>();
  final _dialogService = locator<DialogService>();

  final DictionaryList dictionaryList;

  bool _loading = true;
  bool get loading => _loading;

  DictionaryListViewModel(this.dictionaryList) {
    _loadList();
  }

  Future<void> _loadList() async {
    if (!dictionaryList.vocabLinks.isLoaded) {
      await dictionaryList.vocabLinks.load();
    }
    if (!dictionaryList.kanjiLinks.isLoaded) {
      await dictionaryList.kanjiLinks.load();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> navigateToVocab(Vocab vocab) async {
    await _navigationService.navigateTo(
      Routes.vocabView,
      arguments: VocabViewArguments(vocab: vocab),
    );
    notifyListeners();
  }

  Future<void> navigateToKanji(Kanji kanji) async {
    await _navigationService.navigateTo(
      Routes.kanjiView,
      arguments: KanjiViewArguments(kanji: kanji),
    );
    notifyListeners();
  }

  Future<void> renameMyList() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.textFieldDialog,
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
    notifyListeners();
  }

  Future<void> deleteMyList() async {
    final response = await _dialogService.showCustomDialog(
      variant: DialogType.confirmationDialog,
      title: 'Delete list?',
      mainButtonTitle: 'Delete',
      secondaryButtonTitle: 'Cancel',
      barrierDismissible: true,
    );

    if (response != null && response.confirmed) {
      _isarService.deleteMyDictionaryList(dictionaryList as MyDictionaryList);
      _navigationService.back();
    }
  }
}
