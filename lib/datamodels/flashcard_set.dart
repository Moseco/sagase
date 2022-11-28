import 'package:isar/isar.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/predefined_dictionary_list.dart';

part 'flashcard_set.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class FlashcardSet {
  Id id = Isar.autoIncrement;

  late String name;
  bool usingSpacedRepetition = true;
  bool vocabShowReading = false;
  bool vocabShowReadingIfRareKanji = true;
  bool kanjiShowReading = false;
  late DateTime timestamp;

  final predefinedDictionaryListLinks = IsarLinks<PredefinedDictionaryList>();
  final myDictionaryListLinks = IsarLinks<MyDictionaryList>();
}
