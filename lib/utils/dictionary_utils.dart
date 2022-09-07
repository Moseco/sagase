// ignore_for_file: avoid_print
import 'package:isar/isar.dart';
import 'package:kana_kit/kana_kit.dart';
import 'package:sagase/datamodels/dictionary_info.dart';
import 'package:sagase/datamodels/vocab.dart';
import 'package:xml/xml.dart';

// This class contains functions only to be used during development
class DictionaryUtils {
  // Creates the vocab database from the raw dictionary file
  // Optional argument testingIsar exists for testing
  static Future<void> createVocabDictionaryIsolate(
    String jmdictString, {
    Isar? testingIsar,
  }) async {
    Isar isar =
        testingIsar ?? await Isar.open([DictionaryInfoSchema, VocabSchema]);

    await isar.writeTxn(() async {
      await isar.clear();
      return isar.dictionaryInfos.put(DictionaryInfo());
    });

    final List<Vocab> vocabList = [];

    final jmdictDoc = XmlDocument.parse(jmdictString);

    final rawVocabList = jmdictDoc.childElements.first.childElements;
    // Top level of vocab items
    for (int i = 0; i < rawVocabList.length; i++) {
      // Write to database every 10,000 iterations
      if (i % 10000 == 0) {
        print("Writing at $i");
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

      // Elements within vocab
      final rawVocabItem = rawVocabList.elementAt(i);
      for (var vocabElement in rawVocabItem.childElements) {
        switch (vocabElement.name.local) {
          case 'ent_seq':
            vocab.id = int.parse(vocabElement.firstChild!.text);
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
            _handleSenseElement(vocabElement, vocab);
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
          for (var pos in vocab.definitions.first.pos!) {
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

      for (var definition in vocab.definitions) {
        // Split words for improved searching
        vocab.definitionIndex
            .addAll(Isar.splitWords(definition.definition.toLowerCase()));
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

    // If did not receive the isar instance, close it
    if (testingIsar == null) {
      isar.close();
    }
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
          if (kanjiInfo != null) {
            kanjiWriting.info ??= [];
            kanjiWriting.info!.add(kanjiInfo);
          }
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
          if (readingInfo != null) {
            reading.info ??= [];
            reading.info!.add(readingInfo);
          }
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
      case '&uK;':
        return ReadingInfo.onlyKanji;
      default:
        return null;
    }
  }

  static void _handleSenseElement(XmlElement xmlElement, Vocab vocab) {
    List<String> definitions = [];
    List<PartOfSpeech> partsOfSpeech = [];
    String? additionalInfo;

    for (var senseElement in xmlElement.childElements) {
      switch (senseElement.name.local) {
        case 'stagk':
          break;
        case 'stagr':
          break;
        case 'pos':
          partsOfSpeech.add(_handlePartOfSpeechElement(senseElement.text));
          break;
        case 'xref':
          // Cross-reference to another entry with similar/related meaning
          break;
        case 'ant':
          // Reference to another entry that is an antonym of the current entry
          break;
        case 'field':
          break;
        case 'misc':
          break;
        case 's_inf':
          additionalInfo = senseElement.text;
          break;
        case 'lsource':
          // Indicates the source language of a loan-word/gairaigo
          break;
        case 'dial':
          // For words associated with a specific regional dialect
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
      definitionBuffer.write(', ${definitions[i]}');
    }

    // Set definition
    vocab.definitions.add(
      VocabDefinition()
        ..definition = definitionBuffer.toString()
        ..additionalInfo = additionalInfo
        ..pos = partsOfSpeech,
    );
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

  // Exports the Isar database to given path
  static Future<void> exportDatabaseIsolate(String path) async {
    final isar = await Isar.open([DictionaryInfoSchema, VocabSchema]);

    await isar.copyToFile('$path/db_export.isar');

    isar.close();
  }
}
