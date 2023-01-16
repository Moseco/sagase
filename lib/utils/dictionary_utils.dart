// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter/material.dart' show visibleForTesting;
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:sagase/datamodels/flashcard_set.dart';
import 'package:sagase/datamodels/my_dictionary_list.dart';
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/kanji.dart';
import 'package:sagase/datamodels/predefined_dictionary_list.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:xml/xml.dart';
import 'package:sagase/utils/constants.dart' as constants;

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
        ]);

    await isar.writeTxn(() async {
      await isar.clear();
      return isar.dictionaryInfos.put(
        DictionaryInfo()..version = constants.dictionaryVersion,
      );
    });

    await createVocabDictionaryIsolate(source.vocabDict, isar);
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
      // Write to database every 10,000 iterations
      if (i % 10000 == 0) {
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
      const kanaKit = KanaKit();
      final simplifyNonVerbRegex = RegExp(r'(?<=.{1})(う|っ|ー)');
      final simplifyVerbRegex = RegExp(r'(?<=.{1})(ー|っ|(う(?=.)))');
      for (var pair in vocab.kanjiReadingPairs) {
        // Add readings
        for (var reading in pair.readings) {
          // Japanese text
          vocab.japaneseTextIndex.add(reading.reading);
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
            vocab.japaneseTextIndex.add(kanjiWriting.kanji);
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
        return PartOfSpeech.adjective;
      case "&adj-i;":
        return PartOfSpeech.adjective;
      case "&adj-ix;":
        return PartOfSpeech.adjective;
      case "&adj-kari;":
        return PartOfSpeech.adjective;
      case "&adj-ku;":
        return PartOfSpeech.adjective;
      case "&adj-na;":
        return PartOfSpeech.adjective;
      case "&adj-nari;":
        return PartOfSpeech.adjective;
      case "&adj-no;":
        return PartOfSpeech.adjective;
      case "&adj-pn;":
        return PartOfSpeech.adjective;
      case "&adj-shiku;":
        return PartOfSpeech.adjective;
      case "&adj-t;":
        return PartOfSpeech.adjective;
      case "&adv;":
        return PartOfSpeech.adverb;
      case "&adv-to;":
        return PartOfSpeech.adverb;
      case "&aux;":
        return PartOfSpeech.auxiliary;
      case "&aux-adj;":
        return PartOfSpeech.auxiliary;
      case "&aux-v;":
        return PartOfSpeech.auxiliary;
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
        return PartOfSpeech.verbIchidan;
      case "&v2a-s;":
        return PartOfSpeech.verbNidan;
      case "&v2b-k;":
        return PartOfSpeech.verbNidan;
      case "&v2b-s;":
        return PartOfSpeech.verbNidan;
      case "&v2d-k;":
        return PartOfSpeech.verbNidan;
      case "&v2d-s;":
        return PartOfSpeech.verbNidan;
      case "&v2g-k;":
        return PartOfSpeech.verbNidan;
      case "&v2g-s;":
        return PartOfSpeech.verbNidan;
      case "&v2h-k;":
        return PartOfSpeech.verbNidan;
      case "&v2h-s;":
        return PartOfSpeech.verbNidan;
      case "&v2k-k;":
        return PartOfSpeech.verbNidan;
      case "&v2k-s;":
        return PartOfSpeech.verbNidan;
      case "&v2m-k;":
        return PartOfSpeech.verbNidan;
      case "&v2m-s;":
        return PartOfSpeech.verbNidan;
      case "&v2n-s;":
        return PartOfSpeech.verbNidan;
      case "&v2r-k;":
        return PartOfSpeech.verbNidan;
      case "&v2r-s;":
        return PartOfSpeech.verbNidan;
      case "&v2s-s;":
        return PartOfSpeech.verbNidan;
      case "&v2t-k;":
        return PartOfSpeech.verbNidan;
      case "&v2t-s;":
        return PartOfSpeech.verbNidan;
      case "&v2w-s;":
        return PartOfSpeech.verbNidan;
      case "&v2y-k;":
        return PartOfSpeech.verbNidan;
      case "&v2y-s;":
        return PartOfSpeech.verbNidan;
      case "&v2z-s;":
        return PartOfSpeech.verbNidan;
      case "&v4b;":
        return PartOfSpeech.verbYodan;
      case "&v4g;":
        return PartOfSpeech.verbYodan;
      case "&v4h;":
        return PartOfSpeech.verbYodan;
      case "&v4k;":
        return PartOfSpeech.verbYodan;
      case "&v4m;":
        return PartOfSpeech.verbYodan;
      case "&v4n;":
        return PartOfSpeech.verbYodan;
      case "&v4r;":
        return PartOfSpeech.verbYodan;
      case "&v4s;":
        return PartOfSpeech.verbYodan;
      case "&v4t;":
        return PartOfSpeech.verbYodan;
      case "&v5aru;":
        return PartOfSpeech.verbGodan;
      case "&v5b;":
        return PartOfSpeech.verbGodan;
      case "&v5g;":
        return PartOfSpeech.verbGodan;
      case "&v5k;":
        return PartOfSpeech.verbGodan;
      case "&v5k-s;":
        return PartOfSpeech.verbGodan;
      case "&v5m;":
        return PartOfSpeech.verbGodan;
      case "&v5n;":
        return PartOfSpeech.verbGodan;
      case "&v5r;":
        return PartOfSpeech.verbGodan;
      case "&v5r-i;":
        return PartOfSpeech.verbGodan;
      case "&v5s;":
        return PartOfSpeech.verbGodan;
      case "&v5t;":
        return PartOfSpeech.verbGodan;
      case "&v5u;":
        return PartOfSpeech.verbGodan;
      case "&v5u-s;":
        return PartOfSpeech.verbGodan;
      case "&v5uru;":
        return PartOfSpeech.verbGodan;
      case "&vi;":
        return PartOfSpeech.verbIntransitive;
      case "&vk;":
        return PartOfSpeech.verbKuru;
      case "&vn;":
        return PartOfSpeech.verbIrregular;
      case "&vr;":
        return PartOfSpeech.verbIrregular;
      case "&vs;":
        return PartOfSpeech.verbSuru;
      case "&vs-c;":
        return PartOfSpeech.verbSuru;
      case "&vs-i;":
        return PartOfSpeech.verbSuru;
      case "&vs-s;":
        return PartOfSpeech.verbSuru;
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
      // // Write to database every 10,000 iterations
      if (i % 1000 == 0) print("At kanji $i");

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
            _handleKanjiRadicalElements(kanjiElement.childElements, kanji);
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
        await kanji.compounds.save();
      }
    });

    // Add components to kanji
    await isar.writeTxn(() async {
      final lines = kanjiComponentsString.split('\n');
      for (var line in lines) {
        if (line.isNotEmpty && !line.startsWith('#')) {
          final splits = line.split(':');
          final kanji = await isar.kanjis.getByKanji(splits[0].trim());
          if (kanji != null) {
            final componentStrings = splits[1].split(' ');
            for (var component in componentStrings) {
              // If component is the same as the radical, don't add it
              if (component.isEmpty ||
                  component == constants.radicals[kanji.radical].radical) {
                continue;
              }
              kanji.components ??= [];
              kanji.components!.add(component);
            }
            await isar.kanjis.put(kanji);
          }
        }
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

  static void _handleKanjiRadicalElements(
    Iterable<XmlElement> elements,
    Kanji kanji,
  ) {
    for (var element in elements) {
      if (element.getAttribute('rad_type') == 'classical') {
        kanji.radical = int.parse(element.text);
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

    // JLPT N5
    final jlptN5List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptN5
      ..name = 'N5';
    final jlptN5ListRaw = vocabMap['jlpt_n5'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptN5ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptN5ListRaw[i]);
        jlptN5List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptN5List);
      await jlptN5List.vocabLinks.save();
    });

    // JLPT N4
    final jlptN4List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptN4
      ..name = 'N4';
    final jlptN4ListRaw = vocabMap['jlpt_n4'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptN4ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptN4ListRaw[i]);
        jlptN4List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptN4List);
      await jlptN4List.vocabLinks.save();
    });

    // JLPT N3
    final jlptN3List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptN3
      ..name = 'N3';
    final jlptN3ListRaw = vocabMap['jlpt_n3'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptN3ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptN3ListRaw[i]);
        jlptN3List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptN3List);
      await jlptN3List.vocabLinks.save();
    });

    // JLPT N2
    final jlptN2List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptN2
      ..name = 'N2';
    final jlptN2ListRaw = vocabMap['jlpt_n2'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptN2ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptN2ListRaw[i]);
        jlptN2List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptN2List);
      await jlptN2List.vocabLinks.save();
    });

    // JLPT N1
    final jlptN1List = PredefinedDictionaryList()
      ..id = constants.dictionaryListIdJlptN1
      ..name = 'N1';
    final jlptN1ListRaw = vocabMap['jlpt_n1'];
    await isar.writeTxn(() async {
      for (int i = 0; i < jlptN1ListRaw.length; i++) {
        final vocab = await isar.vocabs.get(jlptN1ListRaw[i]);
        jlptN1List.vocabLinks.add(vocab!);
      }
      await isar.predefinedDictionaryLists.put(jlptN1List);
      await jlptN1List.vocabLinks.save();
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

  const DictionarySource(
    this.vocabDict,
    this.kanjiDict,
    this.kanjiComponents,
    this.vocabLists,
    this.kanjiLists,
    this.kanjiStrokeData,
  );
}
