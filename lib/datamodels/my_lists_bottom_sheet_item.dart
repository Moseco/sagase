import 'package:sagase_dictionary/sagase_dictionary.dart';

class MyListsBottomSheetItem {
  final MyDictionaryList list;
  bool enabled;
  bool changed;

  MyListsBottomSheetItem(this.list, this.enabled, {this.changed = false});
}
