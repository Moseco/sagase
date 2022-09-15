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
  List<String>? appliesTo;
  @enumerated
  List<Field>? fields;
  @enumerated
  List<MiscellaneousInfo>? miscInfo;
  @enumerated
  List<Dialect>? dialects;
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

enum Field {
  agriculture,
  anatomy,
  archeology,
  architecture,
  artAesthetics,
  astronomy,
  audiovisual,
  aviation,
  baseball,
  biochemistry,
  biology,
  botany,
  buddhism,
  business,
  chemistry,
  christianity,
  clothing,
  computing,
  crystallography,
  ecology,
  economics,
  electricityElecEng,
  electronics,
  embryology,
  engineering,
  entomology,
  finance,
  fishing,
  foodCooking,
  gardening,
  genetics,
  geography,
  geology,
  geometry,
  go,
  golf,
  grammar,
  greekMythology,
  hanafuda,
  horseRacing,
  law,
  linguistics,
  logic,
  martialArts,
  mahjong,
  mathematics,
  mechanicalEngineering,
  medicine,
  meteorology,
  military,
  music,
  ornithology,
  paleontology,
  pathology,
  pharmacy,
  philosophy,
  photography,
  physics,
  physiology,
  printing,
  psychiatry,
  psychology,
  railway,
  shinto,
  shogi,
  sports,
  statistics,
  sumo,
  telecommunications,
  trademark,
  videoGames,
  zoology,
}

enum MiscellaneousInfo {
  abbreviation,
  archaism,
  character,
  childrensLanguage,
  colloquialism,
  companyName,
  creature,
  datedTerm,
  deity,
  derogatory,
  document,
  event,
  familiarLanguage,
  femaleLanguage,
  fiction,
  formalOrLiteraryTerm,
  givenName,
  group,
  historicalTerm,
  honorificOrRespectful,
  humbleLanguage,
  idiomaticExpression,
  humorousTerm,
  legend,
  mangaSlang,
  maleLanguage,
  mythology,
  internetSlang,
  object,
  obsoleteTerm,
  obscureTerm,
  onomatopoeicOrMimeticWord,
  organizationName,
  other,
  particularPerson,
  placeName,
  poeticalTerm,
  politeLanguage,
  productName,
  proverb,
  quotation,
  rare,
  religion,
  sensitive,
  service,
  slang,
  railwayStation,
  surname,
  usuallyKanaAlone,
  unclassifiedName,
  vulgar,
  workOfArt,
  rudeOrXRatedTerm,
  yojijukugo,
}

enum Dialect {
  brazilian,
  hokkaidoBen,
  kansaiBen,
  kantouBen,
  kyotoBen,
  kyuushuuBen,
  naganoBen,
  osakaBen,
  ryuukyuuBen,
  touhokuBen,
  tosaBen,
  tsugaruBen,
}
