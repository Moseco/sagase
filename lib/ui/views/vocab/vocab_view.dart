import 'package:flutter/material.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:sagase/ui/widgets/common_vocab.dart';
import 'package:sagase/ui/widgets/card_with_title_section.dart';
import 'package:sagase/ui/widgets/kanji_list_item_large.dart';
import 'package:stacked/stacked.dart';
import 'package:ruby_text/ruby_text.dart';

import 'vocab_viewmodel.dart';

class VocabView extends StatelessWidget {
  final Vocab vocab;

  const VocabView(this.vocab, {super.key});

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder<VocabViewModel>.reactive(
      viewModelBuilder: () => VocabViewModel(vocab),
      fireOnModelReadyOnce: true,
      onModelReady: (viewModel) => viewModel.initialize(),
      builder: (context, viewModel, child) => Scaffold(
        appBar: AppBar(
          title: Text(
            vocab.kanjiReadingPairs[0].kanjiWritings?[0].kanji ??
                vocab.kanjiReadingPairs[0].readings[0].reading,
          ),
          actions: [
            IconButton(
              onPressed: viewModel.openMyDictionaryListsSheet,
              icon: Icon(
                vocab.myDictionaryListLinks.isEmpty
                    ? Icons.star_border
                    : Icons.star,
              ),
            ),
          ],
        ),
        // Can throw exception "'!_selectionStartsInScrollable': is not true."
        // when long press then try to scroll on disabled areas.
        // But seems to work okay in release builds.
        body: SelectionArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PrimaryKanjiReadingPair(vocab.kanjiReadingPairs[0]),
                  ),
                  if (vocab.commonWord) const CommonVocab(),
                ],
              ),
              _KanjiReadingPairs(vocab.kanjiReadingPairs),
              const _Definitions(),
              if (viewModel.kanjiList.isNotEmpty) const _KanjiList(),
              if (vocab.examples != null) const _Examples(),
              if (viewModel.conjugations != null) const _Conjugations(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryKanjiReadingPair extends ViewModelWidget<VocabViewModel> {
  final KanjiReadingPair pair;

  const _PrimaryKanjiReadingPair(
    this.pair, {
    Key? key,
  }) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    if (pair.kanjiWritings != null) {
      return Text(
        '${pair.kanjiWritings![0].kanji}【${pair.readings[0].reading}】',
        style: const TextStyle(fontSize: 24),
      );
    } else {
      return Text(
        pair.readings[0].reading,
        style: const TextStyle(fontSize: 24),
      );
    }
  }
}

class _KanjiReadingPairs extends ViewModelWidget<VocabViewModel> {
  final List<KanjiReadingPair> pairs;

  const _KanjiReadingPairs(
    this.pairs, {
    Key? key,
  }) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    if (pairs.length == 1 &&
        (pairs[0].kanjiWritings == null ||
            pairs[0].kanjiWritings!.length == 1) &&
        pairs[0].readings.length == 1) {
      // Only 1 kanji and 1 reading, which is already shown, show nothing
      return Container();
    } else {
      // Show additional kanji-reading pairs
      // Only show first pair if contains more than 1 kanji or reading
      int startIndex = 0;
      if ((pairs[0].kanjiWritings == null ||
              pairs[0].kanjiWritings!.length == 1) &&
          pairs[0].readings.length == 1) {
        startIndex = 1;
      }

      List<Text> textList = [];
      for (int i = startIndex; i < pairs.length; i++) {
        final buffer = StringBuffer();
        if (pairs[i].kanjiWritings != null) {
          buffer.write(pairs[i].kanjiWritings![0].kanji);
          for (int j = 1; j < pairs[i].kanjiWritings!.length; j++) {
            buffer.write(', ');
            buffer.write(pairs[i].kanjiWritings![j].kanji);
          }
        }
        if (pairs[i].kanjiWritings != null) buffer.write('【');
        buffer.write(pairs[i].readings[0].reading);
        for (int j = 1; j < pairs[i].readings.length; j++) {
          buffer.write(', ');
          buffer.write(pairs[i].readings[j].reading);
        }
        if (pairs[i].kanjiWritings != null) buffer.write('】');
        textList.add(Text(buffer.toString()));
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: textList,
      );
    }
  }
}

class _Definitions extends ViewModelWidget<VocabViewModel> {
  const _Definitions({Key? key}) : super(key: key, reactive: false);

  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<String> partsOfSpeechStrings = [];
    List<String> otherInfo = [];
    for (var definition in viewModel.vocab.definitions) {
      // Parse parts of speech
      if (definition.pos == null) {
        partsOfSpeechStrings.add('');
      } else {
        final posBuffer = StringBuffer(
          _partOfSpeechToString(definition.pos![0]),
        );
        for (int i = 1; i < definition.pos!.length; i++) {
          posBuffer.write(', ');
          posBuffer.write(_partOfSpeechToString(definition.pos![i]));
        }
        posBuffer.write('\n');
        partsOfSpeechStrings.add(posBuffer.toString());
      }

      // Parse other info
      final otherInfoBuffer = StringBuffer();
      if (definition.additionalInfo != null) {
        otherInfoBuffer.write(' (');
        otherInfoBuffer.write(definition.additionalInfo);
      }
      if (definition.appliesTo != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write('only apples to: ');
        otherInfoBuffer.write(definition.appliesTo!.join(', '));
      }
      if (definition.fields != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write(_fieldToString(definition.fields![0]));
        for (int i = 1; i < definition.fields!.length; i++) {
          otherInfoBuffer.write(', ');
          otherInfoBuffer.write(_fieldToString(definition.fields![i]));
        }
      }
      if (definition.miscInfo != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write(_miscInfoToString(definition.miscInfo![0]));
        for (int i = 1; i < definition.miscInfo!.length; i++) {
          otherInfoBuffer.write(', ');
          otherInfoBuffer.write(_miscInfoToString(definition.miscInfo![i]));
        }
      }
      if (definition.dialects != null) {
        if (otherInfoBuffer.isEmpty) {
          otherInfoBuffer.write(' (');
        } else {
          otherInfoBuffer.write('; ');
        }
        otherInfoBuffer.write(_dialectToString(definition.dialects![0]));
        for (int i = 1; i < definition.dialects!.length; i++) {
          otherInfoBuffer.write(', ');
          otherInfoBuffer.write(_dialectToString(definition.dialects![i]));
        }
      }
      if (otherInfoBuffer.isNotEmpty) otherInfoBuffer.write(')');
      otherInfo.add(otherInfoBuffer.toString());
    }

    return CardWithTitleSection(
      title: 'Definition',
      child: ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.all(8),
        itemCount: viewModel.vocab.definitions.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text.rich(
            TextSpan(
              children: [
                if (partsOfSpeechStrings[index].isNotEmpty)
                  WidgetSpan(
                    child: SelectionContainer.disabled(
                      child: Text(
                        '${index + 1}: ',
                        style: const TextStyle(color: Colors.transparent),
                      ),
                    ),
                  ),
                TextSpan(
                  text: partsOfSpeechStrings[index],
                  style: const TextStyle(color: Colors.grey),
                ),
                TextSpan(
                  text: '${index + 1}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(text: viewModel.vocab.definitions[index].definition),
                if (otherInfo[index].isNotEmpty)
                  TextSpan(
                    text: otherInfo[index],
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _partOfSpeechToString(PartOfSpeech pos) {
    switch (pos) {
      case PartOfSpeech.adjectiveF:
        return 'adjective';
      case PartOfSpeech.adjectiveI:
        return 'adjective';
      case PartOfSpeech.adjectiveIx:
        return 'adjective';
      case PartOfSpeech.adjectiveKari:
        return 'adjective';
      case PartOfSpeech.adjectiveKu:
        return 'adjective';
      case PartOfSpeech.adjectiveNa:
        return 'adjective';
      case PartOfSpeech.adjectiveNari:
        return 'adjective';
      case PartOfSpeech.adjectiveNo:
        return 'adjective';
      case PartOfSpeech.adjectivePn:
        return 'adjective';
      case PartOfSpeech.adjectiveShiku:
        return 'adjective';
      case PartOfSpeech.adjectiveT:
        return 'adjective';
      case PartOfSpeech.adverb:
        return 'adverb';
      case PartOfSpeech.adverbTo:
        return 'adverb';
      case PartOfSpeech.auxiliary:
        return 'auxiliary';
      case PartOfSpeech.auxiliaryAdj:
        return 'auxiliary';
      case PartOfSpeech.auxiliaryV:
        return 'auxiliary';
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
        return 'prefix (noun)';
      case PartOfSpeech.nounSuffix:
        return 'suffix (noun)';
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
        return 'ichidan verb';
      case PartOfSpeech.verbNidanAS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanBK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanBS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanDK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanDS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanGK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanGS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanHK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanHS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanKK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanKS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanMK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanMS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanNS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanRK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanRS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanSS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanTK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanTS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanWS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanYK:
        return 'nidan verb';
      case PartOfSpeech.verbNidanYS:
        return 'nidan verb';
      case PartOfSpeech.verbNidanZS:
        return 'nidan verb';
      case PartOfSpeech.verbYodanB:
        return 'yodan verb';
      case PartOfSpeech.verbYodanG:
        return 'yodan verb';
      case PartOfSpeech.verbYodanH:
        return 'yodan verb';
      case PartOfSpeech.verbYodanK:
        return 'yodan verb';
      case PartOfSpeech.verbYodanM:
        return 'yodan verb';
      case PartOfSpeech.verbYodanN:
        return 'yodan verb';
      case PartOfSpeech.verbYodanR:
        return 'yodan verb';
      case PartOfSpeech.verbYodanS:
        return 'yodan verb';
      case PartOfSpeech.verbYodanT:
        return 'yodan verb';
      case PartOfSpeech.verbGodanAru:
        return 'godan verb';
      case PartOfSpeech.verbGodanB:
        return 'godan verb';
      case PartOfSpeech.verbGodanG:
        return 'godan verb';
      case PartOfSpeech.verbGodanK:
        return 'godan verb';
      case PartOfSpeech.verbGodanKS:
        return 'godan verb';
      case PartOfSpeech.verbGodanM:
        return 'godan verb';
      case PartOfSpeech.verbGodanN:
        return 'godan verb';
      case PartOfSpeech.verbGodanR:
        return 'godan verb';
      case PartOfSpeech.verbGodanRI:
        return 'godan verb';
      case PartOfSpeech.verbGodanS:
        return 'godan verb';
      case PartOfSpeech.verbGodanT:
        return 'godan verb';
      case PartOfSpeech.verbGodanU:
        return 'godan verb';
      case PartOfSpeech.verbGodanUS:
        return 'godan verb';
      case PartOfSpeech.verbGodanUru:
        return 'godan verb';
      case PartOfSpeech.verbIntransitive:
        return 'intransitive verb';
      case PartOfSpeech.verbKuru:
        return 'kuru verb';
      case PartOfSpeech.verbIrregularN:
        return 'irregular verb';
      case PartOfSpeech.verbIrregularR:
        return 'irregular verb';
      case PartOfSpeech.verbSuru:
        return 'suru verb';
      case PartOfSpeech.verbSu:
        return 'su verb (precursor to modern suru verb';
      case PartOfSpeech.verbSuruIncluded:
        return 'suru verb';
      case PartOfSpeech.verbSuruSpecial:
        return 'suru verb';
      case PartOfSpeech.verbTransitive:
        return 'transitive verb';
      case PartOfSpeech.verbIchidanZuru:
        return 'ichidan zuru verb';
      case PartOfSpeech.unknown:
        return 'UNKNOWN';
    }
  }

  String _fieldToString(Field field) {
    switch (field) {
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

  String _miscInfoToString(MiscellaneousInfo miscellaneousInfo) {
    switch (miscellaneousInfo) {
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

  String _dialectToString(Dialect dialect) {
    switch (dialect) {
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

class _KanjiList extends ViewModelWidget<VocabViewModel> {
  const _KanjiList({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    return SelectionContainer.disabled(
      child: CardWithTitleSection(
        title: 'Kanji',
        child: ListView.builder(
          shrinkWrap: true,
          primary: false,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: viewModel.kanjiList.length,
          itemBuilder: (context, index) {
            final current = viewModel.kanjiList[index];
            if (viewModel.kanjiLoaded) {
              return KanjiListItemLarge(
                kanji: current,
                onPressed: () => viewModel.navigateToKanji(current),
              );
            } else {
              return ListTile(title: Text(current.kanji));
            }
          },
        ),
      ),
    );
  }
}

class _Examples extends ViewModelWidget<VocabViewModel> {
  const _Examples({Key? key}) : super(key: key, reactive: false);
  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    // Collect examples by which definition they are associated with
    List<_DefinitionExamples> examples = [];
    for (var example in viewModel.vocab.examples!) {
      if (examples.isEmpty || examples.last.index != example.index) {
        examples.add(_DefinitionExamples(example.index, []));
      }
      examples.last.list.add(example);
    }

    return CardWithTitleSection(
      title: 'Examples',
      child: ListView.builder(
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.all(8),
        itemCount: examples.length,
        itemBuilder: (context, index) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'For definition ${examples[index].index + 1}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              primary: false,
              padding: const EdgeInsets.only(left: 16),
              itemCount: examples[index].list.length,
              itemBuilder: (context, i) {
                List<RubyTextData> data = [];
                for (var token in examples[index].list[i].tokens) {
                  for (var rubyPair in token.rubyTextPairs) {
                    data.add(
                      RubyTextData(
                        rubyPair.writing,
                        ruby: rubyPair.reading,
                      ),
                    );
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RubyText(
                        data,
                        style: const TextStyle(letterSpacing: 0),
                      ),
                      Text(examples[index].list[i].english),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DefinitionExamples {
  final int index;
  final List<VocabExample> list;

  const _DefinitionExamples(this.index, this.list);
}

class _Conjugations extends ViewModelWidget<VocabViewModel> {
  const _Conjugations({Key? key}) : super(key: key, reactive: false);
  @override
  Widget build(BuildContext context, VocabViewModel viewModel) {
    List<TableRow> rows = [
      TableRow(
        children: [
          Container(),
          const Padding(
            padding: EdgeInsets.all(4),
            child: Center(child: Text('Positive')),
          ),
          const Padding(
            padding: EdgeInsets.all(4),
            child: Center(child: Text('Negative')),
          ),
        ],
      ),
    ];

    for (var conjugation in viewModel.conjugations!) {
      rows.add(
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(conjugation.title),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(conjugation.positive),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(conjugation.negative),
            ),
          ],
        ),
      );
    }

    return CardWithTitleSection(
      title: 'Conjugations',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: Table(
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Colors.grey),
          ),
          children: rows,
        ),
      ),
    );
  }
}
