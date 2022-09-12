import 'package:isar/isar.dart';
import 'package:sagase/datamodels/dictionary_item.dart';

part 'vocab.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class Vocab extends DictionaryItem {
  late Id id;

  List<KanjiReadingPair> kanjiReadingPairs = [];

  List<VocabDefinition> definitions = [];

  @Index(type: IndexType.value)
  List<String> japaneseTextIndex = [];

  @Index(type: IndexType.value)
  List<String> romajiTextIndex = [];

  @Index(type: IndexType.value)
  List<String> definitionIndex = [];

  bool commonWord = false;

  List<VocabExample>? examples;
}

@embedded
class KanjiReadingPair {
  List<VocabKanji>? kanjiWritings;
  List<VocabReading> readings = [];
}

@embedded
class VocabKanji {
  late String kanji;
  @enumerated
  List<KanjiInfo>? info;
}

@embedded
class VocabReading {
  late String reading;
  @enumerated
  List<ReadingInfo>? info;
}

@embedded
class VocabDefinition {
  late String definition;
  String? additionalInfo;
  @enumerated
  List<PartOfSpeech>? pos;
}

@embedded
class VocabExample {
  late int index;
  late String japanese;
  late String english;
}

enum KanjiInfo {
  ateji,
  irregularKana,
  irregularKanji,
  irregularOkurigana,
  outdatedKanji,
  rareKanjiForm,
}

enum ReadingInfo {
  gikun,
  irregularKana,
  outdatedKana,
  onlyKanji,
}

enum PartOfSpeech {
  adjective,
  adverb,
  auxiliary,
  conjunction,
  copula,
  counter,
  expressions,
  interjection,
  noun,
  nounAdverbial,
  nounProper,
  nounPrefix,
  nounSuffix,
  nounTemporal,
  numeric,
  pronoun,
  prefix,
  particle,
  suffix,
  unclassified,
  verb,
  verbIchidan,
  verbNidan,
  verbYodan,
  verbGodan,
  verbIntransitive,
  verbKuru,
  verbIrregular,
  verbSuru,
  verbTransitive,
  verbIchidanZuru,
  unknown,
}
