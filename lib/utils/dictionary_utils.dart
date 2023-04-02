// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter/material.dart' show visibleForTesting;
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/kanji_radical.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/predefined_dictionary_list.dart';
import 'package:sagase/datamodels/search_history_item.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:xml/xml.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:sagase/utils/string_utils.dart';

// This class contains functions only to be used during development
class DictionaryUtils {
  // Creates the dictionary database from the raw dictionary file
  // Optional argument testingIsar exists for testing
  static Future<void> createDictionaryIsolate(
    DictionarySource source, {
    Isar? testingIsar,
  }) async {
    Isar isar = testingIsar ??
        await Isar.open([
          DictionaryInfoSchema,
          VocabSchema,
          KanjiSchema,
          PredefinedDictionaryListSchema,
          MyDictionaryListSchema,
          FlashcardSetSchema,
          KanjiRadicalSchema,
          SearchHistoryItemSchema,
        ]);

    await isar.writeTxn(() async {
      await isar.clear();
      return isar.dictionaryInfos.put(
        DictionaryInfo()..version = constants.dictionaryVersion,
      );
    });

    await createVocabDictionaryIsolate(source.vocabDict, isar);
    await createRadicalDictionaryIsolate(
      source.kanjiRadicals,
      source.kanjiStrokeData,
      isar,
    );
    await createKanjiDictionaryIsolate(
      source.kanjiDict,
      source.kanjiComponents,
      source.kanjiStrokeData,
      isar,
    );
    await _createDictionaryListsIsolate(
      source.vocabLists,
      source.kanjiLists,
      isar,
    );

    // If did not receive the isar instance, close it
    if (testingIsar == null) {
      isar.close();
    }
  }

  // Creates the vocab database from the raw dictionary file
  @visibleForTesting
  static Future<void> createVocabDictionaryIsolate(
    String jmdictString,
    Isar isar,
  ) async {
    final List<Vocab> vocabList = [];

    final jmdictDoc = XmlDocument.parse(jmdictString);

    final rawVocabList = jmdictDoc.childElements.first.childElements;
    // Top level of vocab items
    for (int i = 0; i < rawVocabList.length; i++) {
      // Write to database every 1000 iterations
      if (i % 1000 == 0 && i != 0) {
        print("At vocab $i");
        await isar.writeTxn(() async {
          for (var vocab in vocabList) {
            await isar.vocabs.put(vocab);
          }
          vocabList.clear();
        });
      }

      final vocab = Vocab();
      List<KanjiReadingPair> kanjiReadingPairs = [];
      vocab.kanjiReadingPairs = kanjiReadingPairs;
      List<String> rawDefinitions = [];

      // Elements within vocab
      final rawVocabItem = rawVocabList.elementAt(i);
      for (var vocabElement in rawVocabItem.childElements) {
        switch (vocabElement.name.local) {
          case 'ent_seq':
            vocab.id = int.parse(vocabElement.text);
            break;
          case 'k_ele':
            kanjiReadingPairs.add(
              KanjiReadingPair()
                ..kanjiWritings = [
                  _handleKanjiElements(vocabElement.childElements, vocab)
                ],
            );
            break;
          case 'r_ele':
            _handleReadingElements(
              vocabElement.childElements,
              kanjiReadingPairs,
              vocab,
            );
            break;
          case 'sense':
            rawDefinitions.addAll(_handleSenseElement(vocabElement, vocab));
            break;
        }
      }

      // Merge kanji reading pairs if they contain the same readings
      for (int j = 0; j < kanjiReadingPairs.length; j++) {
        for (int k = j + 1; k < kanjiReadingPairs.length; k++) {
          // If reading list length is not the same, can  skip
          if (kanjiReadingPairs[j].readings.length !=
              kanjiReadingPairs[k].readings.length) continue;

          // Go through readings and check if they are all the same
          bool readingMismatch = false;
          for (int x = 0; x < kanjiReadingPairs[j].readings.length; x++) {
            if (kanjiReadingPairs[j].readings[x] !=
                kanjiReadingPairs[k].readings[x]) {
              readingMismatch = true;
              break;
            }
          }
          // If any of the readings were different, can skip
          if (readingMismatch) continue;

          // If got here, then can merge pairs if both kanji writing lists exist
          if (kanjiReadingPairs[j].kanjiWritings != null &&
              kanjiReadingPairs[k].kanjiWritings != null) {
            kanjiReadingPairs[j]
                .kanjiWritings!
                .addAll(kanjiReadingPairs[k].kanjiWritings!);

            // Remove pair that was merged from
            kanjiReadingPairs.removeAt(k);
            k--;
          }
        }
      }

      // Finally, add vocab to list
      vocabList.add(vocab);

      // Create index strings
      final kanaKit = const KanaKit().copyWithConfig(passRomaji: true);
      final simplifyNonVerbRegex = RegExp(r'(?<=.{1})(う|っ|ー)');
      final simplifyVerbRegex = RegExp(r'(?<=.{1})(ー|っ|(う(?=.)))');
      for (var pair in vocab.kanjiReadingPairs) {
        // Add readings
        for (var reading in pair.readings) {
          // Japanese text
          vocab.japaneseTextIndex.add(kanaKit.toHiragana(reading.reading));
          // Romaji text
          vocab.romajiTextIndex
              .add(kanaKit.toRomaji(reading.reading).toLowerCase());
          // Simplified romaji text (remove based on if verb or not)
          String? simplifiedReading;
          for (var pos in vocab.definitions.first.pos ?? []) {
            // Range of verbs
            if (pos.index >= PartOfSpeech.verb.index &&
                pos.index <= PartOfSpeech.verbIchidanZuru.index) {
              simplifiedReading =
                  reading.reading.replaceAll(simplifyVerbRegex, '');
              break;
            }
          }
          // If not already set, use non-verb regex
          simplifiedReading ??=
              reading.reading.replaceAll(simplifyNonVerbRegex, '');

          if (simplifiedReading.isNotEmpty) {
            vocab.romajiTextIndex
                .add(kanaKit.toRomaji(simplifiedReading).toLowerCase());
          }
        }
        // Add kanji
        if (pair.kanjiWritings != null) {
          for (var kanjiWriting in pair.kanjiWritings!) {
            vocab.japaneseTextIndex.add(kanaKit.toHiragana(
              kanjiWriting.kanji.toLowerCase().romajiToHalfWidth(),
            ));
          }
        }
      }

      for (var definition in rawDefinitions) {
        // If definition starts with 'to ' (including space) index the whole string
        // This improves searching for verbs
        if (definition.startsWith('to ')) {
          vocab.definitionIndex.add(definition);
        }
        // Split words for improved searching
        vocab.definitionIndex.addAll(Isar.splitWords(definition.toLowerCase()));
      }

      // Remove duplicates from indexes
      vocab.japaneseTextIndex = vocab.japaneseTextIndex.toSet().toList();
      vocab.romajiTextIndex = vocab.romajiTextIndex.toSet().toList();
      vocab.definitionIndex = vocab.definitionIndex.toSet().toList();
    }

    // Write the remaining vocab
    await isar.writeTxn(() async {
      for (var vocab in vocabList) {
        await isar.vocabs.put(vocab);
      }
    });
  }

  static VocabKanji _handleKanjiElements(
    Iterable<XmlElement> elements,
    Vocab vocab,
  ) {
    final kanjiWriting = VocabKanji();

    for (var kanjiElement in elements) {
      switch (kanjiElement.name.local) {
        case 'keb':
          kanjiWriting.kanji = kanjiElement.text;
          break;
        case 'ke_inf':
          final kanjiInfo = _handleKanjiInfo(kanjiElement.text);
          kanjiWriting.info ??= [];
          kanjiWriting.info!.add(kanjiInfo!);
          break;
        case 'ke_pri':
          _handleVocabPriorityInfo(kanjiElement.text, vocab);
          break;
      }
    }

    return kanjiWriting;
  }

  static KanjiInfo? _handleKanjiInfo(String kanjiInfo) {
    switch (kanjiInfo) {
      case '&ateji;':
        return KanjiInfo.ateji;
      case '&ik;':
        return KanjiInfo.irregularKana;
      case '&iK;':
        return KanjiInfo.irregularKanji;
      case '&io;':
        return KanjiInfo.irregularOkurigana;
      case '&oK;':
        return KanjiInfo.outdatedKanji;
      case '&rK;':
        return KanjiInfo.rareKanjiForm;
      case '&sK;':
        return KanjiInfo.searchOnlyForm;
      default:
        return null;
    }
  }

  static void _handleVocabPriorityInfo(String text, Vocab vocab) {
    // Ignoring ichi2 and gai2
    if (text == 'news1' ||
        text == 'news2' ||
        text == 'ichi1' ||
        text == 'spec1' ||
        text == 'spec2' ||
        text == 'gai1') {
      vocab.commonWord = true;
    }
  }

  static void _handleReadingElements(
    Iterable<XmlElement> elements,
    List<KanjiReadingPair> kanjiReadingPairs,
    Vocab vocab,
  ) {
    final reading = VocabReading();
    List<String> associatedKanjiList = [];

    for (var readingElement in elements) {
      switch (readingElement.name.local) {
        case 'reb':
          reading.reading = readingElement.text;
          break;
        case 're_nokanji':
          // If present, represents that the reading isn't fully associated with the kanji
          break;
        case 're_restr':
          associatedKanjiList.add(readingElement.text);
          break;
        case 're_inf':
          final readingInfo = _handleReadingInfo(readingElement.text);
          reading.info ??= [];
          reading.info!.add(readingInfo!);
          break;
        case 're_pri':
          _handleVocabPriorityInfo(readingElement.text, vocab);
          break;
      }
    }

    if (associatedKanjiList.isEmpty) {
      // Not associated with specific kanji writing, add to all
      // If no pairs have been created so far, create an empty pair
      if (kanjiReadingPairs.isEmpty) kanjiReadingPairs.add(KanjiReadingPair());
      for (var pair in kanjiReadingPairs) {
        pair.readings.add(reading);
      }
    } else {
      // Associated with specific kanji writing, add to associated
      for (var pair in kanjiReadingPairs) {
        for (var associatedKanji in associatedKanjiList) {
          if (pair.kanjiWritings!.first.kanji == associatedKanji) {
            pair.readings.add(reading);
            break;
          }
        }
      }
    }
  }

  static ReadingInfo? _handleReadingInfo(String readingInfo) {
    switch (readingInfo) {
      case '&gikun;':
        return ReadingInfo.gikun;
      case '&ik;':
        return ReadingInfo.irregularKana;
      case '&ok;':
        return ReadingInfo.outdatedKana;
      case '&sk;':
        return ReadingInfo.searchOnlyForm;
      default:
        return null;
    }
  }

  static List<String> _handleSenseElement(XmlElement xmlElement, Vocab vocab) {
    List<String> definitions = [];
    List<PartOfSpeech>? partsOfSpeech;
    String? additionalInfo;
    List<String>? appliesTo;
    List<Field>? fields;
    List<MiscellaneousInfo>? miscInfo;
    List<Dialect>? dialects;

    for (var senseElement in xmlElement.childElements) {
      switch (senseElement.name.local) {
        case 'stagk':
          appliesTo ??= [];
          appliesTo.add(senseElement.text);
          break;
        case 'stagr':
          appliesTo ??= [];
          appliesTo.add(senseElement.text);
          break;
        case 'pos':
          partsOfSpeech ??= [];
          partsOfSpeech.add(_handlePartOfSpeechElement(senseElement.text));
          break;
        case 'xref':
          // Cross-reference to another entry with similar/related meaning
          break;
        case 'ant':
          // Reference to another entry that is an antonym of the current entry
          break;
        case 'field':
          final field = _handleFieldElement(senseElement.text);
          fields ??= [];
          fields.add(field!);
          break;
        case 'misc':
          final misc = _handleMiscElement(senseElement.text);
          miscInfo ??= [];
          miscInfo.add(misc!);
          break;
        case 's_inf':
          additionalInfo = senseElement.text;
          break;
        case 'lsource':
          // Indicates the source language of a loan-word/gairaigo
          break;
        case 'dial':
          final dialect = _handleDialectElement(senseElement.text);
          dialects ??= [];
          dialects.add(dialect!);
          break;
        case 'gloss':
          definitions.add(senseElement.text);
          break;
        case 'example':
          _handleExampleElement(
            senseElement,
            vocab,
            vocab.definitions.length,
          );
          break;
      }
    }

    // Construct definition
    final definitionBuffer = StringBuffer(definitions.first);
    for (int i = 1; i < definitions.length; i++) {
      definitionBuffer.write('; ${definitions[i]}');
    }

    // Set definition
    vocab.definitions.add(
      VocabDefinition()
        ..definition = definitionBuffer.toString()
        ..additionalInfo = additionalInfo
        ..pos = partsOfSpeech
        ..appliesTo = appliesTo
        ..fields = fields
        ..miscInfo = miscInfo
        ..dialects = dialects,
    );

    return definitions;
  }

  static void _handleExampleElement(
    XmlElement xmlElement,
    Vocab vocab,
    int index,
  ) {
    vocab.examples ??= [];

    late String japaneseText;
    late String englishText;

    for (var element in xmlElement.childElements) {
      if (element.name.local == 'ex_sent') {
        if (element.getAttribute('xml:lang') == 'jpn') {
          japaneseText = element.text;
        } else {
          englishText = element.text;
        }
      }
    }

    vocab.examples!.add(
      VocabExample()
        ..index = index
        ..japanese = japaneseText
        ..english = englishText,
    );
  }

  static PartOfSpeech _handlePartOfSpeechElement(String partOfSpeech) {
    switch (partOfSpeech) {
      case "&adj-f;":
        return PartOfSpeech.adjectiveF;
      case "&adj-i;":
        return PartOfSpeech.adjectiveI;
      case "&adj-ix;":
        return PartOfSpeech.adjectiveIx;
      case "&adj-kari;":
        return PartOfSpeech.adjectiveKari;
      case "&adj-ku;":
        return PartOfSpeech.adjectiveKu;
      case "&adj-na;":
        return PartOfSpeech.adjectiveNa;
      case "&adj-nari;":
        return PartOfSpeech.adjectiveNari;
      case "&adj-no;":
        return PartOfSpeech.adjectiveNo;
      case "&adj-pn;":
        return PartOfSpeech.adjectivePn;
      case "&adj-shiku;":
        return PartOfSpeech.adjectiveShiku;
      case "&adj-t;":
        return PartOfSpeech.adjectiveT;
      case "&adv;":
        return PartOfSpeech.adverb;
      case "&adv-to;":
        return PartOfSpeech.adverbTo;
      case "&aux;":
        return PartOfSpeech.auxiliary;
      case "&aux-adj;":
        return PartOfSpeech.auxiliaryAdj;
      case "&aux-v;":
        return PartOfSpeech.auxiliaryV;
      case "&conj;":
        return PartOfSpeech.conjunction;
      case "&cop;":
        return PartOfSpeech.copula;
      case "&ctr;":
        return PartOfSpeech.counter;
      case "&exp;":
        return PartOfSpeech.expressions;
      case "&int;":
        return PartOfSpeech.interjection;
      case "&n;":
        return PartOfSpeech.noun;
      case "&n-adv;":
        return PartOfSpeech.nounAdverbial;
      case "&n-pr;":
        return PartOfSpeech.nounProper;
      case "&n-pref;":
        return PartOfSpeech.nounPrefix;
      case "&n-suf;":
        return PartOfSpeech.nounSuffix;
      case "&n-t;":
        return PartOfSpeech.nounTemporal;
      case "&num;":
        return PartOfSpeech.numeric;
      case "&pn;":
        return PartOfSpeech.pronoun;
      case "&pref;":
        return PartOfSpeech.prefix;
      case "&prt;":
        return PartOfSpeech.particle;
      case "&suf;":
        return PartOfSpeech.suffix;
      case "&unc;":
        return PartOfSpeech.unclassified;
      case "&v-unspec;":
        return PartOfSpeech.verb;
      case "&v1;":
        return PartOfSpeech.verbIchidan;
      case "&v1-s;":
        return PartOfSpeech.verbIchidanS;
      case "&v2a-s;":
        return PartOfSpeech.verbNidanAS;
      case "&v2b-k;":
        return PartOfSpeech.verbNidanBK;
      case "&v2b-s;":
        return PartOfSpeech.verbNidanBS;
      case "&v2d-k;":
        return PartOfSpeech.verbNidanDK;
      case "&v2d-s;":
        return PartOfSpeech.verbNidanDS;
      case "&v2g-k;":
        return PartOfSpeech.verbNidanGK;
      case "&v2g-s;":
        return PartOfSpeech.verbNidanGS;
      case "&v2h-k;":
        return PartOfSpeech.verbNidanHK;
      case "&v2h-s;":
        return PartOfSpeech.verbNidanHS;
      case "&v2k-k;":
        return PartOfSpeech.verbNidanKK;
      case "&v2k-s;":
        return PartOfSpeech.verbNidanKS;
      case "&v2m-k;":
        return PartOfSpeech.verbNidanMK;
      case "&v2m-s;":
        return PartOfSpeech.verbNidanMS;
      case "&v2n-s;":
        return PartOfSpeech.verbNidanNS;
      case "&v2r-k;":
        return PartOfSpeech.verbNidanRK;
      case "&v2r-s;":
        return PartOfSpeech.verbNidanRS;
      case "&v2s-s;":
        return PartOfSpeech.verbNidanSS;
      case "&v2t-k;":
        return PartOfSpeech.verbNidanTK;
      case "&v2t-s;":
        return PartOfSpeech.verbNidanTS;
      case "&v2w-s;":
        return PartOfSpeech.verbNidanWS;
      case "&v2y-k;":
        return PartOfSpeech.verbNidanYK;
      case "&v2y-s;":
        return PartOfSpeech.verbNidanYS;
      case "&v2z-s;":
        return PartOfSpeech.verbNidanZS;
      case "&v4b;":
        return PartOfSpeech.verbYodanB;
      case "&v4g;":
        return PartOfSpeech.verbYodanG;
      case "&v4h;":
        return PartOfSpeech.verbYodanH;
      case "&v4k;":
        return PartOfSpeech.verbYodanK;
      case "&v4m;":
        return PartOfSpeech.verbYodanM;
      case "&v4n;":
        return PartOfSpeech.verbYodanN;
      case "&v4r;":
        return PartOfSpeech.verbYodanR;
      case "&v4s;":
        return PartOfSpeech.verbYodanS;
      case "&v4t;":
        return PartOfSpeech.verbYodanT;
      case "&v5aru;":
        return PartOfSpeech.verbGodanAru;
      case "&v5b;":
        return PartOfSpeech.verbGodanB;
      case "&v5g;":
        return PartOfSpeech.verbGodanG;
      case "&v5k;":
        return PartOfSpeech.verbGodanK;
      case "&v5k-s;":
        return PartOfSpeech.verbGodanKS;
      case "&v5m;":
        return PartOfSpeech.verbGodanM;
      case "&v5n;":
        return PartOfSpeech.verbGodanN;
      case "&v5r;":
        return PartOfSpeech.verbGodanR;
      case "&v5r-i;":
        return PartOfSpeech.verbGodanRI;
      case "&v5s;":
        return PartOfSpeech.verbGodanS;
      case "&v5t;":
        return PartOfSpeech.verbGodanT;
      case "&v5u;":
        return PartOfSpeech.verbGodanU;
      case "&v5u-s;":
        return PartOfSpeech.verbGodanUS;
      case "&v5uru;":
        return PartOfSpeech.verbGodanUru;
      case "&vi;":
        return PartOfSpeech.verbIntransitive;
      case "&vk;":
        return PartOfSpeech.verbKuru;
      case "&vn;":
        return PartOfSpeech.verbIrregularN;
      case "&vr;":
        return PartOfSpeech.verbIrregularR;
      case "&vs;":
        return PartOfSpeech.verbSuru;
      case "&vs-c;":
        return PartOfSpeech.verbSu;
      case "&vs-i;":
        return PartOfSpeech.verbSuruIncluded;
      case "&vs-s;":
        return PartOfSpeech.verbSuruSpecial;
      case "&vt;":
        return PartOfSpeech.verbTransitive;
      case "&vz;":
        return PartOfSpeech.verbIchidanZuru;
      default:
        print('Unknown part-of-speech');
        return PartOfSpeech.unknown;
    }
  }

  static Field? _handleFieldElement(String field) {
    switch (field) {
      case '&agric;':
        return Field.agriculture;
      case '&anat;':
        return Field.anatomy;
      case '&archeol;':
        return Field.archeology;
      case '&archit;':
        return Field.architecture;
      case '&art;':
        return Field.artAesthetics;
      case '&astron;':
        return Field.astronomy;
      case '&audvid;':
        return Field.audiovisual;
      case '&aviat;':
        return Field.aviation;
      case '&baseb;':
        return Field.baseball;
      case '&biochem;':
        return Field.biochemistry;
      case '&biol;':
        return Field.biology;
      case '&bot;':
        return Field.botany;
      case '&Buddh;':
        return Field.buddhism;
      case '&bus;':
        return Field.business;
      case '&cards;':
        return Field.cardGames;
      case '&chem;':
        return Field.chemistry;
      case '&Christn;':
        return Field.christianity;
      case '&cloth;':
        return Field.clothing;
      case '&comp;':
        return Field.computing;
      case '&cryst;':
        return Field.crystallography;
      case '&dent;':
        return Field.dentistry;
      case '&ecol;':
        return Field.ecology;
      case '&econ;':
        return Field.economics;
      case '&elec;':
        return Field.electricityElecEng;
      case '&electr;':
        return Field.electronics;
      case '&embryo;':
        return Field.embryology;
      case '&engr;':
        return Field.engineering;
      case '&ent;':
        return Field.entomology;
      case '&film;':
        return Field.film;
      case '&finc;':
        return Field.finance;
      case '&fish;':
        return Field.fishing;
      case '&food;':
        return Field.foodCooking;
      case '&gardn;':
        return Field.gardening;
      case '&genet;':
        return Field.genetics;
      case '&geogr;':
        return Field.geography;
      case '&geol;':
        return Field.geology;
      case '&geom;':
        return Field.geometry;
      case '&go;':
        return Field.go;
      case '&golf;':
        return Field.golf;
      case '&gramm;':
        return Field.grammar;
      case '&grmyth;':
        return Field.greekMythology;
      case '&hanaf;':
        return Field.hanafuda;
      case '&horse;':
        return Field.horseRacing;
      case '&kabuki;':
        return Field.kabuki;
      case '&law;':
        return Field.law;
      case '&ling;':
        return Field.linguistics;
      case '&logic;':
        return Field.logic;
      case '&MA;':
        return Field.martialArts;
      case '&mahj;':
        return Field.mahjong;
      case '&manga;':
        return Field.manga;
      case '&math;':
        return Field.mathematics;
      case '&mech;':
        return Field.mechanicalEngineering;
      case '&med;':
        return Field.medicine;
      case '&met;':
        return Field.meteorology;
      case '&mil;':
        return Field.military;
      case '&mining;':
        return Field.mining;
      case '&music;':
        return Field.music;
      case '&noh;':
        return Field.noh;
      case '&ornith;':
        return Field.ornithology;
      case '&paleo;':
        return Field.paleontology;
      case '&pathol;':
        return Field.pathology;
      case '&pharm;':
        return Field.pharmacology;
      case '&phil;':
        return Field.philosophy;
      case '&photo;':
        return Field.photography;
      case '&physics;':
        return Field.physics;
      case '&physiol;':
        return Field.physiology;
      case '&politics;':
        return Field.politics;
      case '&print;':
        return Field.printing;
      case '&psy;':
        return Field.psychiatry;
      case '&psyanal;':
        return Field.psychoanalysis;
      case '&psych;':
        return Field.psychology;
      case '&rail;':
        return Field.railway;
      case '&rommyth;':
        return Field.romanMythology;
      case '&Shinto;':
        return Field.shinto;
      case '&shogi;':
        return Field.shogi;
      case '&ski;':
        return Field.skiing;
      case '&sports;':
        return Field.sports;
      case '&stat;':
        return Field.statistics;
      case '&stockm;':
        return Field.stockMarket;
      case '&sumo;':
        return Field.sumo;
      case '&telec;':
        return Field.telecommunications;
      case '&tradem;':
        return Field.trademark;
      case '&tv;':
        return Field.television;
      case '&vidg;':
        return Field.videoGames;
      case '&zool;':
        return Field.zoology;
      default:
        return null;
    }
  }

  static MiscellaneousInfo? _handleMiscElement(String miscellaneousInfo) {
    switch (miscellaneousInfo) {
      case '&abbr;':
        return MiscellaneousInfo.abbreviation;
      case '&arch;':
        return MiscellaneousInfo.archaism;
      case '&char;':
        return MiscellaneousInfo.character;
      case '&chn;':
        return MiscellaneousInfo.childrensLanguage;
      case '&col;':
        return MiscellaneousInfo.colloquialism;
      case '&company;':
        return MiscellaneousInfo.companyName;
      case '&creat;':
        return MiscellaneousInfo.creature;
      case '&dated;':
        return MiscellaneousInfo.datedTerm;
      case '&dei;':
        return MiscellaneousInfo.deity;
      case '&derog;':
        return MiscellaneousInfo.derogatory;
      case '&doc;':
        return MiscellaneousInfo.document;
      case '&euph;':
        return MiscellaneousInfo.euphemistic;
      case '&ev;':
        return MiscellaneousInfo.event;
      case '&fam;':
        return MiscellaneousInfo.familiarLanguage;
      case '&fem;':
        return MiscellaneousInfo.femaleLanguage;
      case '&fict;':
        return MiscellaneousInfo.fiction;
      case '&form;':
        return MiscellaneousInfo.formalOrLiteraryTerm;
      case '&given;':
        return MiscellaneousInfo.givenName;
      case '&group;':
        return MiscellaneousInfo.group;
      case '&hist;':
        return MiscellaneousInfo.historicalTerm;
      case '&hon;':
        return MiscellaneousInfo.honorificOrRespectful;
      case '&hum;':
        return MiscellaneousInfo.humbleLanguage;
      case '&id;':
        return MiscellaneousInfo.idiomaticExpression;
      case '&joc;':
        return MiscellaneousInfo.humorousTerm;
      case '&leg;':
        return MiscellaneousInfo.legend;
      case '&m-sl;':
        return MiscellaneousInfo.mangaSlang;
      case '&male;':
        return MiscellaneousInfo.maleLanguage;
      case '&myth;':
        return MiscellaneousInfo.mythology;
      case '&net-sl;':
        return MiscellaneousInfo.internetSlang;
      case '&obj;':
        return MiscellaneousInfo.object;
      case '&obs;':
        return MiscellaneousInfo.obsoleteTerm;
      case '&on-mim;':
        return MiscellaneousInfo.onomatopoeicOrMimeticWord;
      case '&organization;':
        return MiscellaneousInfo.organizationName;
      case '&oth;':
        return MiscellaneousInfo.other;
      case '&person;':
        return MiscellaneousInfo.particularPerson;
      case '&place;':
        return MiscellaneousInfo.placeName;
      case '&poet;':
        return MiscellaneousInfo.poeticalTerm;
      case '&pol;':
        return MiscellaneousInfo.politeLanguage;
      case '&product;':
        return MiscellaneousInfo.productName;
      case '&proverb;':
        return MiscellaneousInfo.proverb;
      case '&quote;':
        return MiscellaneousInfo.quotation;
      case '&rare;':
        return MiscellaneousInfo.rare;
      case '&relig;':
        return MiscellaneousInfo.religion;
      case '&sens;':
        return MiscellaneousInfo.sensitive;
      case '&serv;':
        return MiscellaneousInfo.service;
      case '&ship;':
        return MiscellaneousInfo.shipName;
      case '&sl;':
        return MiscellaneousInfo.slang;
      case '&station;':
        return MiscellaneousInfo.railwayStation;
      case '&surname;':
        return MiscellaneousInfo.surname;
      case '&uk;':
        return MiscellaneousInfo.usuallyKanaAlone;
      case '&unclass;':
        return MiscellaneousInfo.unclassifiedName;
      case '&vulg;':
        return MiscellaneousInfo.vulgar;
      case '&work;':
        return MiscellaneousInfo.workOfArt;
      case '&X;':
        return MiscellaneousInfo.rudeOrXRatedTerm;
      case '&yoji;':
        return MiscellaneousInfo.yojijukugo;
      default:
        return null;
    }
  }

  static Dialect? _handleDialectElement(String dialect) {
    switch (dialect) {
      case '&bra;':
        return Dialect.brazilian;
      case '&hob;':
        return Dialect.hokkaidoBen;
      case '&ksb;':
        return Dialect.kansaiBen;
      case '&ktb;':
        return Dialect.kantouBen;
      case '&kyb;':
        return Dialect.kyotoBen;
      case '&kyu;':
        return Dialect.kyuushuuBen;
      case '&nab;':
        return Dialect.naganoBen;
      case '&osb;':
        return Dialect.osakaBen;
      case '&rkb;':
        return Dialect.ryuukyuuBen;
      case '&thb;':
        return Dialect.touhokuBen;
      case '&tsb;':
        return Dialect.tosaBen;
      case '&tsug;':
        return Dialect.tsugaruBen;
      default:
        return null;
    }
  }

  // Creates the radical database from the radical json
  @visibleForTesting
  static Future<void> createRadicalDictionaryIsolate(
    String kanjiRadicalsString,
    String kanjiStrokeDataString,
    Isar isar,
  ) async {
    Map<String, dynamic> kanjiRadicalMap = jsonDecode(kanjiRadicalsString);
    Map<String, dynamic> strokeMap = jsonDecode(kanjiStrokeDataString);

    // Loop through and add the basic data
    await isar.writeTxn(() async {
      for (var entry in kanjiRadicalMap.entries) {
        final kanjiRadical = KanjiRadical()
          ..radical = entry.key
          ..kangxiId = entry.value['kanjix']
          ..strokeCount = entry.value['strokes']
          ..meaning = entry.value['meaning']
          ..reading = entry.value['reading']
          ..position = entry.value.containsKey('position')
              ? KanjiRadicalPosition.values[entry.value['position']]
              : KanjiRadicalPosition.none
          ..importance = entry.value.containsKey('importance')
              ? KanjiRadicalImportance.values[entry.value['importance']]
              : KanjiRadicalImportance.none
          ..strokes = strokeMap[entry.key]?.cast<String>()
          ..variants = entry.value.containsKey('variants')
              ? entry.value['variants'].cast<String>()
              : null
          ..variantOf = entry.value['variant_of'];

        await isar.kanjiRadicals.put(kanjiRadical);
      }
    });
  }

  // Creates the kanji database from the raw dictionary file
  @visibleForTesting
  static Future<void> createKanjiDictionaryIsolate(
    String kanjidic2String,
    String kanjiComponentsString,
    String kanjiStrokeDataString,
    Isar isar,
  ) async {
    final List<Kanji> kanjiList = [];

    final kanjidic2Doc = XmlDocument.parse(kanjidic2String);

    final rawKanjiList = kanjidic2Doc.childElements.first.childElements;

    // Top level of kanji items (skip first element which is header)
    for (int i = 1; i < rawKanjiList.length; i++) {
      // Write to database every 1000 iterations
      if (i % 1000 == 0 && i != 0) {
        print("At kanji $i");
        await isar.writeTxn(() async {
          for (var kanji in kanjiList) {
            await isar.kanjis.put(kanji);
            await kanji.radical.save();
            await kanji.compounds.save();
          }
        });
        kanjiList.clear();
      }

      final kanji = Kanji();

      // Elements within kanji
      final rawKanjiItem = rawKanjiList.elementAt(i);
      for (var kanjiElement in rawKanjiItem.childElements) {
        switch (kanjiElement.name.local) {
          case 'literal':
            kanji.kanji = kanjiElement.text;
            break;
          case 'codepoint':
            _handleKanjiCodepointElements(kanjiElement.childElements, kanji);
            break;
          case 'radical':
            await _handleKanjiRadicalElements(
              kanjiElement.childElements,
              kanji,
              isar,
            );
            break;
          case 'misc':
            _handleKanjiMiscElements(kanjiElement.childElements, kanji);
            break;
          case 'dic_number':
            // Index numbers referencing published dictionaries
            break;
          case 'query_code':
            // Information related to the glyph
            break;
          case 'reading_meaning':
            _handleKanjiReadingElements(kanjiElement.childElements, kanji);
            break;
        }
      }

      // Search vocab for kanji and add links to them
      final vocabList = await isar.vocabs
          .filter()
          .japaneseTextIndexElementContains(kanji.kanji)
          .findAll();
      for (var vocab in vocabList) {
        kanji.compounds.add(vocab);
      }

      // Finally, add kanji to list
      kanjiList.add(kanji);
    }

    // Write the remaining kanji
    await isar.writeTxn(() async {
      for (var kanji in kanjiList) {
        await isar.kanjis.put(kanji);
        await kanji.radical.save();
        await kanji.compounds.save();
      }
    });

    // Add components to kanji
    await isar.writeTxn(() async {
      final lines = kanjiComponentsString.split('\n');
      for (var line in lines) {
        if (line.isEmpty || line.startsWith('#')) continue;

        final splits = line.split(':');
        final kanji = await isar.kanjis.getByKanji(splits[0].trim());
        if (kanji == null) continue;

        await kanji.radical.load();
        final componentStrings = splits[1].split(' ');
        for (var componentString in componentStrings) {
          final componentKanji = await isar.kanjis.getByKanji(componentString);
          if (componentString.isEmpty ||
              componentString == kanji.radical.value?.radical ||
              componentKanji == null) continue;

          kanji.componentLinks.add(componentKanji);
        }

        await kanji.componentLinks.save();
      }
    });

    // Add stroke data
    await isar.writeTxn(() async {
      Map<String, dynamic> strokeMap = jsonDecode(kanjiStrokeDataString);

      for (var entry in strokeMap.entries) {
        final kanji = await isar.kanjis.getByKanji(entry.key);
        if (kanji != null) {
          kanji.strokes = entry.value.cast<String>();
          await isar.kanjis.put(kanji);
        }
      }
    });
  }

  static void _handleKanjiCodepointElements(
    Iterable<XmlElement> elements,
    Kanji kanji,
  ) {
    for (var element in elements) {
      if (element.getAttribute('cp_type')!.startsWith('j')) {
        kanji.id = _getIdFromCodepoint(
          element.getAttribute('cp_type')!,
          element.text,
        );
        return;
      }
    }
  }

  static Future<void> _handleKanjiRadicalElements(
    Iterable<XmlElement> elements,
    Kanji kanji,
    Isar isar,
  ) async {
    for (var element in elements) {
      if (element.getAttribute('rad_type') == 'classical') {
        kanji.radical.value = (await isar.kanjiRadicals
            .filter()
            .kangxiIdEqualTo(int.parse(element.text))
            .findFirst());
        return;
      }
    }
  }

  static void _handleKanjiMiscElements(
    Iterable<XmlElement> elements,
    Kanji kanji,
  ) {
    int? strokeCount;

    for (var element in elements) {
      switch (element.name.local) {
        case 'grade':
          int grade = int.parse(element.text);
          if (grade <= 6) kanji.grade = grade;
          break;
        case 'stroke_count':
          strokeCount ??= int.parse(element.text);
          break;
        case 'variant':
          // Variant of the current kanji
          break;
        case 'freq':
          kanji.frequency = int.parse(element.text);
          break;
        case 'rad_name':
          // This kanji is itself a radical
          break;
        case 'jlpt':
          kanji.jlpt = int.parse(element.text);
          break;
      }
    }

    kanji.strokeCount = strokeCount!;
  }

  static void _handleKanjiReadingElements(
    Iterable<XmlElement> elements,
    Kanji kanji,
  ) {
    List<String> nanori = [];

    for (var element in elements) {
      switch (element.name.local) {
        case 'rmgroup':
          _handleKanjiRmgroupElements(element.childElements, kanji);
          break;
        case 'nanori':
          nanori.add(element.text);
          break;
      }
    }

    kanji.nanori = nanori.isEmpty ? null : nanori;
  }

  static void _handleKanjiRmgroupElements(
    Iterable<XmlElement> elements,
    Kanji kanji,
  ) {
    List<String> meanings = [];
    List<String> onReadings = [];
    List<String> kunReadings = [];

    for (var element in elements) {
      switch (element.name.local) {
        case 'reading':
          if (element.getAttribute('r_type') == 'ja_on') {
            onReadings.add(element.text);
          } else if (element.getAttribute('r_type') == 'ja_kun') {
            kunReadings.add(element.text);
          }
          break;
        case 'meaning':
          if (element.attributes.isEmpty) meanings.add(element.text);
          break;
      }
    }

    // Construct meaning
    final meaningBuffer = StringBuffer();
    if (meanings.isNotEmpty) {
      meaningBuffer.write(meanings.first);
      for (int i = 1; i < meanings.length; i++) {
        meaningBuffer.write(', ${meanings[i]}');
      }
    }

    kanji.meanings = meaningBuffer.isEmpty ? null : meaningBuffer.toString();
    kanji.onReadings = onReadings.isEmpty ? null : onReadings;
    kanji.kunReadings = kunReadings.isEmpty ? null : kunReadings;
  }

  static int _getIdFromCodepoint(String jisVersion, String value) {
    return int.parse('${jisVersion.substring(3)}${value.replaceAll('-', '')}');
  }

  // Creates the built-in dictionary lists
  static Future<void> _createDictionaryListsIsolate(
    String vocabLists,
    String kanjiLists,
    Isar isar,
  ) async {
    // Make sure list sources are not empty (empty for some tests)
    if (vocabLists.isEmpty || kanjiLists.isEmpty) return;

    // Parse vocab lists
    final vocabMap = jsonDecode(vocabLists);

    // JLPT vocab N5
    final jlptVocabN5List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptVocabN5
      ..name = 'N5 Vocab';
    final jlptVocabN5ListRaw = vocabMap['jlpt_n5'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptVocabN5ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptVocabN5ListRaw[i]);
        jlptVocabN5List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptVocabN5List);
      await jlptVocabN5List.vocabLinks.save();
    });

    // JLPT vocab N4
    final jlptVocabN4List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptVocabN4
      ..name = 'N4 Vocab';
    final jlptVocabN4ListRaw = vocabMap['jlpt_n4'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptVocabN4ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptVocabN4ListRaw[i]);
        jlptVocabN4List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptVocabN4List);
      await jlptVocabN4List.vocabLinks.save();
    });

    // JLPT vocab N3
    final jlptVocabN3List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptVocabN3
      ..name = 'N3 Vocab';
    final jlptVocabN3ListRaw = vocabMap['jlpt_n3'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptVocabN3ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptVocabN3ListRaw[i]);
        jlptVocabN3List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptVocabN3List);
      await jlptVocabN3List.vocabLinks.save();
    });

    // JLPT vocab N2
    final jlptVocabN2List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptVocabN2
      ..name = 'N2 Vocab';
    final jlptVocabN2ListRaw = vocabMap['jlpt_n2'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptVocabN2ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptVocabN2ListRaw[i]);
        jlptVocabN2List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptVocabN2List);
      await jlptVocabN2List.vocabLinks.save();
    });

    // JLPT vocab N1
    final jlptVocabN1List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptVocabN1
      ..name = 'N1 Vocab';
    final jlptVocabN1ListRaw = vocabMap['jlpt_n1'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptVocabN1ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptVocabN1ListRaw[i]);
        jlptVocabN1List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptVocabN1List);
      await jlptVocabN1List.vocabLinks.save();
    });

    // Parse kanji lists
    final kanjiListsMap = jsonDecode(kanjiLists);

    // Jouyou
    final jouyouList = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJouyou
      ..name = 'Jouyou';
    final jouyouListRaw = kanjiListsMap['jouyou'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jouyouListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jouyouListRaw[i]);
        jouyouList.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jouyouList);
      await jouyouList.kanjiLinks.save();
    });

    // JLPT kanji N5
    final jlptKanjiN5List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptKanjiN5
      ..name = 'N5 Kanji';
    final jlptKanjiN5ListRaw = kanjiListsMap['jlpt_n5'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptKanjiN5ListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jlptKanjiN5ListRaw[i]);
        jlptKanjiN5List.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jlptKanjiN5List);
      await jlptKanjiN5List.kanjiLinks.save();
    });

    // JLPT kanji N4
    final jlptKanjiN4List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptKanjiN4
      ..name = 'N4 Kanji';
    final jlptKanjiN4ListRaw = kanjiListsMap['jlpt_n4'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptKanjiN4ListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jlptKanjiN4ListRaw[i]);
        jlptKanjiN4List.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jlptKanjiN4List);
      await jlptKanjiN4List.kanjiLinks.save();
    });

    // JLPT kanji N3
    final jlptKanjiN3List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptKanjiN3
      ..name = 'N3 Kanji';
    final jlptKanjiN3ListRaw = kanjiListsMap['jlpt_n3'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptKanjiN3ListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jlptKanjiN3ListRaw[i]);
        jlptKanjiN3List.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jlptKanjiN3List);
      await jlptKanjiN3List.kanjiLinks.save();
    });

    // JLPT kanji N2
    final jlptKanjiN2List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptKanjiN2
      ..name = 'N2 Kanji';
    final jlptKanjiN2ListRaw = kanjiListsMap['jlpt_n2'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptKanjiN2ListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jlptKanjiN2ListRaw[i]);
        jlptKanjiN2List.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jlptKanjiN2List);
      await jlptKanjiN2List.kanjiLinks.save();
    });

    // JLPT kanji N1
    final jlptKanjiN1List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptKanjiN1
      ..name = 'N1 Kanji';
    final jlptKanjiN1ListRaw = kanjiListsMap['jlpt_n1'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptKanjiN1ListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jlptKanjiN1ListRaw[i]);
        jlptKanjiN1List.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jlptKanjiN1List);
      await jlptKanjiN1List.kanjiLinks.save();
    });

    // Grade level 1
    final gradeLevel1 = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdGradeLevel1
      ..name = '1st Grade Kanji';
    final gradeLevel1Raw = kanjiListsMap['grade_level_1'];
    await isar.writeTxn(() async {
      for (int i = 0; i < gradeLevel1Raw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(gradeLevel1Raw[i]);
        gradeLevel1.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(gradeLevel1);
      await gradeLevel1.kanjiLinks.save();
    });

    // Grade level 2
    final gradeLevel2 = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdGradeLevel2
      ..name = '2nd Grade Kanji';
    final gradeLevel2Raw = kanjiListsMap['grade_level_2'];
    await isar.writeTxn(() async {
      for (int i = 0; i < gradeLevel2Raw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(gradeLevel2Raw[i]);
        gradeLevel2.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(gradeLevel2);
      await gradeLevel2.kanjiLinks.save();
    });

    // Grade level 3
    final gradeLevel3 = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdGradeLevel3
      ..name = '3rd Grade Kanji';
    final gradeLevel3Raw = kanjiListsMap['grade_level_3'];
    await isar.writeTxn(() async {
      for (int i = 0; i < gradeLevel3Raw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(gradeLevel3Raw[i]);
        gradeLevel3.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(gradeLevel3);
      await gradeLevel3.kanjiLinks.save();
    });

    // Grade level 4
    final gradeLevel4 = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdGradeLevel4
      ..name = '4th Grade Kanji';
    final gradeLevel4Raw = kanjiListsMap['grade_level_4'];
    await isar.writeTxn(() async {
      for (int i = 0; i < gradeLevel4Raw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(gradeLevel4Raw[i]);
        gradeLevel4.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(gradeLevel4);
      await gradeLevel4.kanjiLinks.save();
    });

    // Grade level 5
    final gradeLevel5 = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdGradeLevel5
      ..name = '5th Grade Kanji';
    final gradeLevel5Raw = kanjiListsMap['grade_level_5'];
    await isar.writeTxn(() async {
      for (int i = 0; i < gradeLevel5Raw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(gradeLevel5Raw[i]);
        gradeLevel5.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(gradeLevel5);
      await gradeLevel5.kanjiLinks.save();
    });

    // Grade level 6
    final gradeLevel6 = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdGradeLevel6
      ..name = '6th Grade Kanji';
    final gradeLevel6Raw = kanjiListsMap['grade_level_6'];
    await isar.writeTxn(() async {
      for (int i = 0; i < gradeLevel6Raw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(gradeLevel6Raw[i]);
        gradeLevel6.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(gradeLevel6);
      await gradeLevel6.kanjiLinks.save();
    });

    // Jinmeiyou
    final jinmeiyouList = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJinmeiyou
      ..name = 'Jinmeiyou';
    final jinmeiyouListRaw = kanjiListsMap['jinmeiyou'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jinmeiyouListRaw.length; i++) {
        final kanji = await isar.kanjis.getByKanji(jinmeiyouListRaw[i]);
        jinmeiyouList.kanjiLinks.add(kanji!);
      }
      await isar.predefinedDictionaryLists.put(jinmeiyouList);
      await jinmeiyouList.kanjiLinks.save();
    });
  }

  // Exports the Isar database to given path
  static Future<void> exportDatabaseIsolate(String path) async {
    final isar = await Isar.open([
      DictionaryInfoSchema,
      VocabSchema,
      KanjiSchema,
      PredefinedDictionaryListSchema,
      MyDictionaryListSchema,
      FlashcardSetSchema,
      KanjiRadicalSchema,
      SearchHistoryItemSchema,
    ]);

    await isar.copyToFile('$path/db_export.isar');

    isar.close();
  }
}

class DictionarySource {
  final String vocabDict;
  final String kanjiDict;
  final String kanjiComponents;
  final String vocabLists;
  final String kanjiLists;
  final String kanjiStrokeData;
  final String kanjiRadicals;

  const DictionarySource(
    this.vocabDict,
    this.kanjiDict,
    this.kanjiComponents,
    this.vocabLists,
    this.kanjiLists,
    this.kanjiStrokeData,
    this.kanjiRadicals,
  );
}
