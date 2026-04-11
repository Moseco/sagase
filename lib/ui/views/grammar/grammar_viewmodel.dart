import 'package:sagase/app/app.bottomsheets.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class GrammarViewModel extends FutureViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _bottomSheetService = locator<BottomSheetService>();

  final Grammar grammar;

  List<int> _myDictionaryListsContainingGrammar = [];
  bool get inMyDictionaryList =>
      _myDictionaryListsContainingGrammar.isNotEmpty;

  GrammarViewModel(this.grammar);

  @override
  Future<void> futureToRun() async {
    _myDictionaryListsContainingGrammar = await _dictionaryService
        .getMyDictionaryListsContainingDictionaryItem(grammar);
    rebuildUi();
  }

  Future<void> openMyDictionaryListsSheet() async {
    // Make sure my dictionary lists containing grammar has been loaded
    if (isBusy) {
      _myDictionaryListsContainingGrammar = await _dictionaryService
          .getMyDictionaryListsContainingDictionaryItem(grammar);
    }

    final myDictionaryLists =
        await _dictionaryService.getAllMyDictionaryLists();

    // Create list for bottom sheet
    List<MyListsBottomSheetItem> bottomSheetItems = [];
    for (var myDictionaryList in myDictionaryLists) {
      bottomSheetItems.add(MyListsBottomSheetItem(myDictionaryList, false));
    }
    // Mark lists that the grammar is in and move them to the top
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (_myDictionaryListsContainingGrammar
          .contains(bottomSheetItems[i].list.id)) {
        bottomSheetItems[i].enabled = true;
        bottomSheetItems.insert(0, bottomSheetItems.removeAt(i));
      }
    }

    await _bottomSheetService.showCustomSheet(
      variant: BottomSheetType.assignMyListsBottom,
      data: bottomSheetItems,
    );

    _myDictionaryListsContainingGrammar.clear();
    for (int i = 0; i < bottomSheetItems.length; i++) {
      if (bottomSheetItems[i].enabled) {
        _myDictionaryListsContainingGrammar.add(bottomSheetItems[i].list.id);
      }
      if (!bottomSheetItems[i].changed) continue;
      if (bottomSheetItems[i].enabled) {
        await _dictionaryService.addToMyDictionaryList(
            bottomSheetItems[i].list, grammar);
      } else {
        await _dictionaryService.removeFromMyDictionaryList(
            bottomSheetItems[i].list, grammar);
      }
    }

    rebuildUi();
  }
}
