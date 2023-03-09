import 'package:isar/isar.dart';

part 'search_history_item.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class SearchHistoryItem {
  Id id = Isar.autoIncrement;

  late String searchQuery;
  late DateTime timestamp;
}
