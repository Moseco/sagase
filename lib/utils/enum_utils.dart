import 'package:sagase_dictionary/sagase_dictionary.dart';

extension PartOfSpeechExtension on PartOfSpeech {
  String get displayTitle {
    switch (this) {
      case PartOfSpeech.adjectiveF:
        return 'noun or verb acting prenominally';
      case PartOfSpeech.adjectiveI:
        return 'い adjective';
      case PartOfSpeech.adjectiveIx:
        return 'い adjective - よい/いい class';
      case PartOfSpeech.adjectiveKari:
        return 'かり adjective (archaic)';
      case PartOfSpeech.adjectiveKu:
        return 'く adjective (archaic)';
      case PartOfSpeech.adjectiveNa:
        return 'な adjective';
      case PartOfSpeech.adjectiveNari:
        return 'なり adjective (archaic/formal form of な adjective)';
      case PartOfSpeech.adjectiveNo:
        return 'noun which may take the genitive case particle の';
      case PartOfSpeech.adjectivePn:
        return 'pre-noun adjectival';
      case PartOfSpeech.adjectiveShiku:
        return 'しく adjective (archaic)';
      case PartOfSpeech.adjectiveT:
        return 'たる adjective';
      case PartOfSpeech.adverb:
        return 'adverb';
      case PartOfSpeech.adverbTo:
        return 'adverb taking the と particle';
      case PartOfSpeech.auxiliary:
        return 'auxiliary';
      case PartOfSpeech.auxiliaryAdj:
        return 'auxiliary adjective';
      case PartOfSpeech.auxiliaryV:
        return 'auxiliary verb';
      case PartOfSpeech.conjunction:
        return 'conjunction';
      case PartOfSpeech.copula:
        return 'copula';
      case PartOfSpeech.counter:
        return 'counter';
      case PartOfSpeech.expressions:
        return 'expression';
      case PartOfSpeech.interjection:
        return 'interjection';
      case PartOfSpeech.noun:
        return 'noun';
      case PartOfSpeech.nounAdverbial:
        return 'adverbial noun';
      case PartOfSpeech.nounProper:
        return 'proper noun';
      case PartOfSpeech.nounPrefix:
        return 'noun used as a prefix';
      case PartOfSpeech.nounSuffix:
        return 'noun used as a suffix';
      case PartOfSpeech.nounTemporal:
        return 'temporal noun';
      case PartOfSpeech.numeric:
        return 'numeric';
      case PartOfSpeech.pronoun:
        return 'pronoun';
      case PartOfSpeech.prefix:
        return 'prefix';
      case PartOfSpeech.particle:
        return 'particle';
      case PartOfSpeech.suffix:
        return 'suffix';
      case PartOfSpeech.unclassified:
        return 'unclassified';
      case PartOfSpeech.verb:
        return 'verb';
      case PartOfSpeech.verbIchidan:
        return 'ichidan verb';
      case PartOfSpeech.verbIchidanS:
        return 'ichidan verb - くれる special class';
      case PartOfSpeech.verbNidanAS:
        return 'nidan verb with う ending (archaic)';
      case PartOfSpeech.verbNidanBK:
        return 'nidan verb (upper class) with ぶ ending (archaic)';
      case PartOfSpeech.verbNidanBS:
        return 'nidan verb (lower class) with ぶ ending (archaic)';
      case PartOfSpeech.verbNidanDK:
        return 'nidan verb (upper class) with ず/づ ending (archaic)';
      case PartOfSpeech.verbNidanDS:
        return 'nidan verb (lower class) with ず/づ ending (archaic)';
      case PartOfSpeech.verbNidanGK:
        return 'nidan verb (upper class) with ぐ ending (archaic)';
      case PartOfSpeech.verbNidanGS:
        return 'nidan verb (lower class) with ぐ ending (archaic)';
      case PartOfSpeech.verbNidanHK:
        return 'nidan verb (upper class) with ふ ending (archaic)';
      case PartOfSpeech.verbNidanHS:
        return 'nidan verb (lower class) with ふ ending (archaic)';
      case PartOfSpeech.verbNidanKK:
        return 'nidan verb (upper class) with く ending (archaic)';
      case PartOfSpeech.verbNidanKS:
        return 'nidan verb (lower class) with く ending (archaic)';
      case PartOfSpeech.verbNidanMK:
        return 'nidan verb (upper class) with む ending (archaic)';
      case PartOfSpeech.verbNidanMS:
        return 'nidan verb (lower class) with む ending (archaic)';
      case PartOfSpeech.verbNidanNS:
        return 'nidan verb (lower class) with ぬ ending (archaic)';
      case PartOfSpeech.verbNidanRK:
        return 'nidan verb (upper class) with る ending (archaic)';
      case PartOfSpeech.verbNidanRS:
        return 'nidan verb (lower class) with る ending (archaic)';
      case PartOfSpeech.verbNidanSS:
        return 'nidan verb (lower class) with す ending (archaic)';
      case PartOfSpeech.verbNidanTK:
        return 'nidan verb (upper class) with つ ending (archaic)';
      case PartOfSpeech.verbNidanTS:
        return 'nidan verb (lower class) with つ ending (archaic)';
      case PartOfSpeech.verbNidanWS:
        return 'nidan verb (lower class) with う ending and ゑ conjugation (archaic)';
      case PartOfSpeech.verbNidanYK:
        return 'nidan verb (upper class) with ゆ ending (archaic)';
      case PartOfSpeech.verbNidanYS:
        return 'nidan verb (lower class) with ゆ ending (archaic)';
      case PartOfSpeech.verbNidanZS:
        return 'nidan verb (lower class) with ず ending (archaic)';
      case PartOfSpeech.verbYodanB:
        return 'yodan verb with ぶ ending (archaic)';
      case PartOfSpeech.verbYodanG:
        return 'yodan verb with ぐ ending (archaic)';
      case PartOfSpeech.verbYodanH:
        return 'yodan verb with ふ ending (archaic)';
      case PartOfSpeech.verbYodanK:
        return 'yodan verb with く ending (archaic)';
      case PartOfSpeech.verbYodanM:
        return 'yodan verb with む ending (archaic)';
      case PartOfSpeech.verbYodanN:
        return 'yodan verb with ぬ ending (archaic)';
      case PartOfSpeech.verbYodanR:
        return 'yodan verb with る ending (archaic)';
      case PartOfSpeech.verbYodanS:
        return 'yodan verb with す ending (archaic)';
      case PartOfSpeech.verbYodanT:
        return 'yodan verb with つ ending (archaic)';
      case PartOfSpeech.verbGodanAru:
        return 'godan verb - ある special class';
      case PartOfSpeech.verbGodanB:
        return 'godan verb with ぶ ending';
      case PartOfSpeech.verbGodanG:
        return 'godan verb with ぐ ending';
      case PartOfSpeech.verbGodanK:
        return 'godan verb with く ending';
      case PartOfSpeech.verbGodanKS:
        return 'godan verb - いく/ゆく special class';
      case PartOfSpeech.verbGodanM:
        return 'godan verb with む ending';
      case PartOfSpeech.verbGodanN:
        return 'godan verb with ぬ ending';
      case PartOfSpeech.verbGodanR:
        return 'godan verb with る ending';
      case PartOfSpeech.verbGodanRI:
        return 'godan verb with る ending (irregular verb)';
      case PartOfSpeech.verbGodanS:
        return 'godan verb with す ending';
      case PartOfSpeech.verbGodanT:
        return 'godan verb with つ ending';
      case PartOfSpeech.verbGodanU:
        return 'godan verb with う ending';
      case PartOfSpeech.verbGodanUS:
        return 'godan verb with う ending (special class)';
      case PartOfSpeech.verbGodanUru:
        return 'godan verb - うる old class (old form of える)';
      case PartOfSpeech.verbIntransitive:
        return 'intransitive verb';
      case PartOfSpeech.verbKuru:
        return 'くる verb - special class';
      case PartOfSpeech.verbIrregularN:
        return 'irregular ぬ verb';
      case PartOfSpeech.verbIrregularR:
        return 'irregular る verb (plain form ends with り)';
      case PartOfSpeech.verbSuru:
        return 'する verb';
      case PartOfSpeech.verbSu:
        return 'す verb (precursor to modern する verb';
      case PartOfSpeech.verbSuruIncluded:
        return 'する verb';
      case PartOfSpeech.verbSuruSpecial:
        return 'する verb';
      case PartOfSpeech.verbTransitive:
        return 'transitive verb';
      case PartOfSpeech.verbIchidanZuru:
        return 'ichidan verb - ずる verb (alternative form of じる verbs)';
      case PartOfSpeech.unknown:
        return 'UNKNOWN';
    }
  }
}

extension FieldExtension on Field {
  String get displayTitle {
    switch (this) {
      case Field.agriculture:
        return 'agriculture';
      case Field.anatomy:
        return 'anatomy';
      case Field.archeology:
        return 'archeology';
      case Field.architecture:
        return 'architecture';
      case Field.artAesthetics:
        return 'art/aesthetics';
      case Field.astronomy:
        return 'astronomy';
      case Field.audiovisual:
        return 'audiovisual';
      case Field.aviation:
        return 'aviation';
      case Field.baseball:
        return 'baseball';
      case Field.biochemistry:
        return 'biochemistry';
      case Field.biology:
        return 'biology';
      case Field.botany:
        return 'botany';
      case Field.buddhism:
        return 'Buddhism';
      case Field.business:
        return 'business';
      case Field.cardGames:
        return 'card games';
      case Field.chemistry:
        return 'chemistry';
      case Field.christianity:
        return 'Christianity';
      case Field.clothing:
        return 'clothing';
      case Field.computing:
        return 'computing';
      case Field.crystallography:
        return 'crystallography';
      case Field.dentistry:
        return 'dentistry';
      case Field.ecology:
        return 'ecology';
      case Field.economics:
        return 'economics';
      case Field.electricityElecEng:
        return 'electricity/electrical engineering';
      case Field.electronics:
        return 'electronics';
      case Field.embryology:
        return 'embryology';
      case Field.engineering:
        return 'engineering';
      case Field.entomology:
        return 'entomology';
      case Field.film:
        return 'film';
      case Field.finance:
        return 'finance';
      case Field.fishing:
        return 'fishing';
      case Field.foodCooking:
        return 'food/cooking';
      case Field.gardening:
        return 'gardening';
      case Field.genetics:
        return 'genetics';
      case Field.geography:
        return 'geography';
      case Field.geology:
        return 'geology';
      case Field.geometry:
        return 'geometry';
      case Field.go:
        return 'go';
      case Field.golf:
        return 'golf';
      case Field.grammar:
        return 'grammar';
      case Field.greekMythology:
        return 'Greek mythology';
      case Field.hanafuda:
        return 'hanafuda';
      case Field.horseRacing:
        return 'horse racing';
      case Field.kabuki:
        return 'kabuki';
      case Field.law:
        return 'law';
      case Field.linguistics:
        return 'linguistics';
      case Field.logic:
        return 'logic';
      case Field.martialArts:
        return 'martial arts';
      case Field.mahjong:
        return 'mahjong';
      case Field.manga:
        return 'manga';
      case Field.mathematics:
        return 'mathematics';
      case Field.mechanicalEngineering:
        return 'mechanical engineering';
      case Field.medicine:
        return 'medicine';
      case Field.meteorology:
        return 'meteorology';
      case Field.military:
        return 'military';
      case Field.mining:
        return 'mining';
      case Field.music:
        return 'music';
      case Field.noh:
        return 'noh';
      case Field.ornithology:
        return 'ornithology';
      case Field.paleontology:
        return 'paleontology';
      case Field.pathology:
        return 'pathology';
      case Field.pharmacology:
        return 'pharmacology';
      case Field.philosophy:
        return 'philosophy';
      case Field.photography:
        return 'photography';
      case Field.physics:
        return 'physics';
      case Field.physiology:
        return 'physiology';
      case Field.politics:
        return 'politics';
      case Field.printing:
        return 'printing';
      case Field.psychiatry:
        return 'psychiatry';
      case Field.psychoanalysis:
        return 'psychoanalysis';
      case Field.psychology:
        return 'psychology';
      case Field.railway:
        return 'railway';
      case Field.romanMythology:
        return 'Roman mythology';
      case Field.shinto:
        return 'Shinto';
      case Field.shogi:
        return 'shogi';
      case Field.skiing:
        return 'skiing';
      case Field.sports:
        return 'sports';
      case Field.statistics:
        return 'statistics';
      case Field.stockMarket:
        return 'stock market';
      case Field.sumo:
        return 'sumo';
      case Field.telecommunications:
        return 'telecommunications';
      case Field.trademark:
        return 'trademark';
      case Field.television:
        return 'television';
      case Field.videoGames:
        return 'video games';
      case Field.zoology:
        return 'zoology';
    }
  }
}

extension MiscellaneousInfoExtension on MiscellaneousInfo {
  String get displayTitle {
    switch (this) {
      case MiscellaneousInfo.abbreviation:
        return 'abbreviation';
      case MiscellaneousInfo.archaism:
        return 'archaism';
      case MiscellaneousInfo.character:
        return 'character';
      case MiscellaneousInfo.childrensLanguage:
        return 'children\'s language';
      case MiscellaneousInfo.colloquialism:
        return 'colloquialism';
      case MiscellaneousInfo.companyName:
        return 'company name';
      case MiscellaneousInfo.creature:
        return 'creature';
      case MiscellaneousInfo.datedTerm:
        return 'dated term';
      case MiscellaneousInfo.deity:
        return 'deity';
      case MiscellaneousInfo.derogatory:
        return 'derogatory';
      case MiscellaneousInfo.document:
        return 'document';
      case MiscellaneousInfo.euphemistic:
        return 'euphemistic';
      case MiscellaneousInfo.event:
        return 'event';
      case MiscellaneousInfo.familiarLanguage:
        return 'familiar language';
      case MiscellaneousInfo.femaleLanguage:
        return 'female language';
      case MiscellaneousInfo.fiction:
        return 'fiction';
      case MiscellaneousInfo.formalOrLiteraryTerm:
        return 'formal or literary term';
      case MiscellaneousInfo.givenName:
        return 'given name';
      case MiscellaneousInfo.group:
        return 'group';
      case MiscellaneousInfo.historicalTerm:
        return 'historical term';
      case MiscellaneousInfo.honorificOrRespectful:
        return 'honorific or respectful (sonkeigo) language';
      case MiscellaneousInfo.humbleLanguage:
        return 'humble  (kenjougo) language';
      case MiscellaneousInfo.idiomaticExpression:
        return 'idiomatic expression';
      case MiscellaneousInfo.humorousTerm:
        return 'humorous term';
      case MiscellaneousInfo.legend:
        return 'legend';
      case MiscellaneousInfo.mangaSlang:
        return 'manga slang';
      case MiscellaneousInfo.maleLanguage:
        return 'male language';
      case MiscellaneousInfo.mythology:
        return 'mythology';
      case MiscellaneousInfo.internetSlang:
        return 'internet slang';
      case MiscellaneousInfo.object:
        return 'object';
      case MiscellaneousInfo.obsoleteTerm:
        return 'obsolete term';
      case MiscellaneousInfo.onomatopoeicOrMimeticWord:
        return 'onomatopoeic or mimetic word';
      case MiscellaneousInfo.organizationName:
        return 'organization name';
      case MiscellaneousInfo.other:
        return 'other';
      case MiscellaneousInfo.particularPerson:
        return 'particular person';
      case MiscellaneousInfo.placeName:
        return 'place name';
      case MiscellaneousInfo.poeticalTerm:
        return 'poetical term';
      case MiscellaneousInfo.politeLanguage:
        return 'polite (teineigo) language';
      case MiscellaneousInfo.productName:
        return 'product name';
      case MiscellaneousInfo.proverb:
        return 'proverb';
      case MiscellaneousInfo.quotation:
        return 'quotation';
      case MiscellaneousInfo.rare:
        return 'rare';
      case MiscellaneousInfo.religion:
        return 'religion';
      case MiscellaneousInfo.sensitive:
        return 'sensitive';
      case MiscellaneousInfo.service:
        return 'service';
      case MiscellaneousInfo.shipName:
        return 'ship name';
      case MiscellaneousInfo.slang:
        return 'slang';
      case MiscellaneousInfo.railwayStation:
        return 'railway station';
      case MiscellaneousInfo.surname:
        return 'surname';
      case MiscellaneousInfo.usuallyKanaAlone:
        return 'usually written using kana alone';
      case MiscellaneousInfo.unclassifiedName:
        return 'unclassified name';
      case MiscellaneousInfo.vulgar:
        return 'vulgar';
      case MiscellaneousInfo.workOfArt:
        return 'work of art';
      case MiscellaneousInfo.rudeOrXRatedTerm:
        return 'rude or X-rated term';
      case MiscellaneousInfo.yojijukugo:
        return 'yojijukugo';
    }
  }
}

extension DialectExtension on Dialect {
  String get displayTitle {
    switch (this) {
      case Dialect.brazilian:
        return 'Brazilian';
      case Dialect.hokkaidoBen:
        return 'Hokkaido-ben';
      case Dialect.kansaiBen:
        return 'Kansai-ben';
      case Dialect.kantouBen:
        return 'Kanto-ben';
      case Dialect.kyotoBen:
        return 'Kyoto-ben';
      case Dialect.kyuushuuBen:
        return 'Kyushu-ben';
      case Dialect.naganoBen:
        return 'Nagano-Ben';
      case Dialect.osakaBen:
        return 'Osaka-ben';
      case Dialect.ryuukyuuBen:
        return 'Ryukyu-ben';
      case Dialect.touhokuBen:
        return 'Tohoku-ben';
      case Dialect.tosaBen:
        return 'Tosa-ben';
      case Dialect.tsugaruBen:
        return 'Tsugaru-ben';
    }
  }
}

extension LanguageSourceExtension on LanguageSource {
  String get displayTitle {
    switch (this) {
      case LanguageSource.afr:
        return 'Afrikaans';
      case LanguageSource.ain:
        return 'Ainu';
      case LanguageSource.alg:
        return 'Algonquian';
      case LanguageSource.amh:
        return 'Amharic';
      case LanguageSource.ara:
        return 'Arabic';
      case LanguageSource.arn:
        return 'Mapuche';
      case LanguageSource.bnt:
        return 'Bantu';
      case LanguageSource.bre:
        return 'Breton';
      case LanguageSource.bul:
        return 'Bulgarian';
      case LanguageSource.bur:
        return 'Burmese';
      case LanguageSource.chi:
        return 'Chinese';
      case LanguageSource.chn:
        return 'Chinook';
      case LanguageSource.cze:
        return 'Czech';
      case LanguageSource.dan:
        return 'Danish';
      case LanguageSource.dut:
        return 'Dutch';
      case LanguageSource.eng:
        return 'English';
      case LanguageSource.epo:
        return 'Esperanto';
      case LanguageSource.est:
        return 'Estonian';
      case LanguageSource.fil:
        return 'Filipino';
      case LanguageSource.fin:
        return 'Finnish';
      case LanguageSource.fre:
        return 'French';
      case LanguageSource.geo:
        return 'Georgian';
      case LanguageSource.ger:
        return 'German';
      case LanguageSource.glg:
        return 'Galician';
      case LanguageSource.grc:
        return 'Ancient Greek';
      case LanguageSource.gre:
        return 'Modern Greek';
      case LanguageSource.haw:
        return 'Hawaiian';
      case LanguageSource.heb:
        return 'Hebrew';
      case LanguageSource.hin:
        return 'Hindi';
      case LanguageSource.hun:
        return 'Hungarian';
      case LanguageSource.ice:
        return 'Icelandic';
      case LanguageSource.ind:
        return 'Indonesian';
      case LanguageSource.ita:
        return 'Italian';
      case LanguageSource.khm:
        return 'Mon-Khmer';
      case LanguageSource.kor:
        return 'Korean';
      case LanguageSource.kur:
        return 'Kurdish';
      case LanguageSource.lat:
        return 'Latin';
      case LanguageSource.mal:
        return 'Malayalam';
      case LanguageSource.mao:
        return 'Maori';
      case LanguageSource.may:
        return 'Malay';
      case LanguageSource.mnc:
        return 'Manchu';
      case LanguageSource.mol:
        return 'Moldovan';
      case LanguageSource.mon:
        return 'Mongolian';
      case LanguageSource.nor:
        return 'Norwegian';
      case LanguageSource.per:
        return 'Persian';
      case LanguageSource.pol:
        return 'Polish';
      case LanguageSource.por:
        return 'Portuguese';
      case LanguageSource.rum:
        return 'Romanian';
      case LanguageSource.rus:
        return 'Russian';
      case LanguageSource.san:
        return 'Sanskrit';
      case LanguageSource.scr:
        return 'Croatian';
      case LanguageSource.slo:
        return 'Slovak';
      case LanguageSource.slv:
        return 'Slovenian';
      case LanguageSource.som:
        return 'Somali';
      case LanguageSource.spa:
        return 'Spanish';
      case LanguageSource.swa:
        return 'Swahili';
      case LanguageSource.swe:
        return 'Swedish';
      case LanguageSource.tah:
        return 'Tahitian';
      case LanguageSource.tam:
        return 'Tamil';
      case LanguageSource.tgl:
        return 'Tagalog';
      case LanguageSource.tha:
        return 'Thai';
      case LanguageSource.tib:
        return 'Tibetan';
      case LanguageSource.tur:
        return 'Turkish';
      case LanguageSource.ukr:
        return 'Ukrainian';
      case LanguageSource.urd:
        return 'Urdu';
      case LanguageSource.vie:
        return 'Vietnamese';
      case LanguageSource.yid:
        return 'Yiddish';
    }
  }
}
