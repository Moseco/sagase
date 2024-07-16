import 'package:isar/isar.dart';

part 'search_history_item.g.dart';

@Collection()
class SearchHistoryItem {
  Id id = Isar.autoIncrement;

  late String searchQuery;
  late DateTime timestamp;
}
