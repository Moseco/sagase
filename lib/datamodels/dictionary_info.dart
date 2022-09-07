import 'package:isar/isar.dart';

part 'dictionary_info.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class DictionaryInfo {
  final Id id = 0;

  int version = 0;
}
