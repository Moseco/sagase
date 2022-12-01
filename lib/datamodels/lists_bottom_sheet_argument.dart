import 'package:sagase/datamodels/my_lists_bottom_sheet_item.dart';

class ListsBottomSheetArgument {
  final Map<int, bool> predefinedLists;
  List<MyListsBottomSheetItem> myLists;

  ListsBottomSheetArgument(this.predefinedLists, this.myLists);
}
