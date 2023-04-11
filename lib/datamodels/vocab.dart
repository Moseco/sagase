import 'package:isar/isar.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/dictionary_item.dart';
import 'package:sagase/datamodels/spaced_repetition_data.dart';
import 'package:sagase/datamodels/japanese_text_token.dart';

part 'vocab.g.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@Collection()
class Vocab extends DictionaryItem {
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

  @Backlink(to: 'vocabLinks')
  final myDictionaryListLinks = IsarLinks<MyDictionaryList>();

  @ignore
  List<Kanji>? includedKanji;

  bool isUsuallyKanaAlone() {
    if (definitions[0].miscInfo == null) return false;
    return definitions[0]
        .miscInfo!
        .contains(MiscellaneousInfo.usuallyKanaAlone);
  }
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
  @ignore
  late List<JapaneseTextToken> tokens;
}

enum KanjiInfo {
  ateji,
  irregularKana,
  irregularKanji,
  irregularOkurigana,
  outdatedKanji,
  rareKanjiForm,
  searchOnlyForm,
}

enum ReadingInfo {
  gikun,
  irregularKana,
  outdatedKana,
  searchOnlyForm,
}

enum PartOfSpeech {
  adjectiveF, // noun or verb acting prenominally
  adjectiveI, // adjective (keiyoushi)
  adjectiveIx, // adjective (keiyoushi) - yoi/ii class
  adjectiveKari, // 'kari' adjective (archaic)
  adjectiveKu, // 'ku' adjective (archaic)
  adjectiveNa, // adjectival nouns or quasi-adjectives (keiyodoshi)
  adjectiveNari, // archaic/formal form of na-adjective
  adjectiveNo, // nouns which may take the genitive case particle 'no'
  adjectivePn, // pre-noun adjectival (rentaishi)
  adjectiveShiku, // 'shiku' adjective (archaic)
  adjectiveT, // 'taru' adjective
  adverb, // adverb (fukushi)
  adverbTo, // adverb taking the 'to' particle
  auxiliary, // auxiliary
  auxiliaryAdj, // auxiliary adjective
  auxiliaryV, // auxiliary verb
  conjunction, // conjunction
  copula, // copula
  counter, // counter
  expressions, // expressions (phrases, clauses, etc.)
  interjection, // interjection (kandoushi)
  noun, // noun (common) (futsuumeishi)
  nounAdverbial, // adverbial noun (fukushitekimeishi)
  nounProper, // proper noun
  nounPrefix, // noun, used as a prefix
  nounSuffix, // noun, used as a suffix
  nounTemporal, // noun (temporal) (jisoumeishi)
  numeric, // numeric
  pronoun, // pronoun
  prefix, // prefix
  particle, // particle
  suffix, // suffix
  unclassified, // unclassified
  verb, // verb unspecified
  verbIchidan, // Ichidan verb
  verbIchidanS, // Ichidan verb - kureru special class
  verbNidanAS, // Nidan verb with 'u' ending (archaic)
  verbNidanBK, // Nidan verb (upper class) with 'bu' ending (archaic)
  verbNidanBS, // Nidan verb (lower class) with 'bu' ending (archaic)
  verbNidanDK, // Nidan verb (upper class) with 'dzu' ending (archaic)
  verbNidanDS, // Nidan verb (lower class) with 'dzu' ending (archaic)
  verbNidanGK, // Nidan verb (upper class) with 'gu' ending (archaic)
  verbNidanGS, // Nidan verb (lower class) with 'gu' ending (archaic)
  verbNidanHK, // Nidan verb (upper class) with 'hu/fu' ending (archaic)
  verbNidanHS, // Nidan verb (lower class) with 'hu/fu' ending (archaic)
  verbNidanKK, // Nidan verb (upper class) with 'ku' ending (archaic)
  verbNidanKS, // Nidan verb (lower class) with 'ku' ending (archaic)
  verbNidanMK, // Nidan verb (upper class) with 'mu' ending (archaic)
  verbNidanMS, // Nidan verb (lower class) with 'mu' ending (archaic)
  verbNidanNS, // Nidan verb (lower class) with 'nu' ending (archaic)
  verbNidanRK, // Nidan verb (upper class) with 'ru' ending (archaic)
  verbNidanRS, // Nidan verb (lower class) with 'ru' ending (archaic)
  verbNidanSS, // Nidan verb (lower class) with 'su' ending (archaic)
  verbNidanTK, // Nidan verb (upper class) with 'tsu' ending (archaic)
  verbNidanTS, // Nidan verb (lower class) with 'tsu' ending (archaic)
  verbNidanWS, // Nidan verb (lower class) with 'u' ending and 'we' conjugation (archaic)
  verbNidanYK, // Nidan verb (upper class) with 'yu' ending (archaic)
  verbNidanYS, // Nidan verb (lower class) with 'yu' ending (archaic)
  verbNidanZS, // Nidan verb (lower class) with 'zu' ending (archaic)
  verbYodanB, // Yodan verb with 'bu' ending (archaic)
  verbYodanG, // Yodan verb with 'gu' ending (archaic)
  verbYodanH, // Yodan verb with 'hu/fu' ending (archaic)
  verbYodanK, // Yodan verb with 'ku' ending (archaic)
  verbYodanM, // Yodan verb with 'mu' ending (archaic)
  verbYodanN, // Yodan verb with 'nu' ending (archaic)
  verbYodanR, // Yodan verb with 'ru' ending (archaic)
  verbYodanS, // Yodan verb with 'su' ending (archaic)
  verbYodanT, // Yodan verb with 'tsu' ending (archaic)
  verbGodanAru, // Godan verb - -aru special class
  verbGodanB, // Godan verb with 'bu' ending
  verbGodanG, // Godan verb with 'gu' ending
  verbGodanK, // Godan verb with 'ku' ending
  verbGodanKS, // Godan verb - Iku/Yuku special class
  verbGodanM, // Godan verb with 'mu' ending
  verbGodanN, // Godan verb with 'nu' ending
  verbGodanR, // Godan verb with 'ru' ending
  verbGodanRI, // Godan verb with 'ru' ending (irregular verb)
  verbGodanS, // Godan verb with 'su' ending
  verbGodanT, // Godan verb with 'tsu' ending
  verbGodanU, // Godan verb with 'u' ending
  verbGodanUS, // Godan verb with 'u' ending (special class)
  verbGodanUru, // Godan verb - Uru old class verb (old form of Eru)
  verbIntransitive, // intransitive verb
  verbKuru, // Kuru verb - special class
  verbIrregularN, // irregular nu verb
  verbIrregularR, // irregular ru verb, plain form ends with -ri
  verbSuru, // noun or participle which takes the aux. verb suru
  verbSu, // su verb - precursor to the modern suru
  verbSuruIncluded, // suru verb - included
  verbSuruSpecial, // suru verb - special class
  verbTransitive, // transitive verb
  verbIchidanZuru, // Ichidan verb - zuru verb (alternative form of -jiru verbs)
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
  cardGames,
  chemistry,
  christianity,
  clothing,
  computing,
  crystallography,
  dentistry,
  ecology,
  economics,
  electricityElecEng,
  electronics,
  embryology,
  engineering,
  entomology,
  film,
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
  kabuki,
  law,
  linguistics,
  logic,
  martialArts,
  mahjong,
  manga,
  mathematics,
  mechanicalEngineering,
  medicine,
  meteorology,
  military,
  mining,
  music,
  noh,
  ornithology,
  paleontology,
  pathology,
  pharmacology,
  philosophy,
  photography,
  physics,
  physiology,
  politics,
  printing,
  psychiatry,
  psychoanalysis,
  psychology,
  railway,
  romanMythology,
  shinto,
  shogi,
  skiing,
  sports,
  statistics,
  stockMarket,
  sumo,
  telecommunications,
  trademark,
  television,
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
  euphemistic,
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
  shipName,
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
