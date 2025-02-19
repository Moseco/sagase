import 'package:sagase_dictionary/sagase_dictionary.dart';

class WritingReadingPair {
  final List<VocabWriting>? writings;
  final List<VocabReading> readings;

  WritingReadingPair({
    required this.writings,
    required this.readings,
  });

  static List<WritingReadingPair> fromVocab(Vocab vocab) {
    if (vocab.writings != null) {
      List<WritingReadingPair> pairs = [];
      // First create a pair for each non-search form writing
      for (final writing in vocab.writings!) {
        if (writing.info != null &&
            writing.info!.contains(WritingInfo.searchOnlyForm)) {
          continue;
        }
        pairs.add(WritingReadingPair(writings: [writing], readings: []));
      }

      if (pairs.isEmpty) return _readingOnlyPairs(vocab);

      // Sort readings into writings
      for (final reading in vocab.readings) {
        if (reading.info != null &&
            reading.info!.contains(ReadingInfo.searchOnlyForm)) {
          continue;
        }
        if (reading.associatedWritings == null) {
          // Add to all pairs
          for (final pair in pairs) {
            pair.readings.add(reading);
          }
        } else {
          // Add only to associated writings
          for (final pair in pairs) {
            if (reading.associatedWritings!
                .contains(pair.writings![0].writing)) {
              pair.readings.add(reading);
            }
          }
        }
      }

      // Merge pairs
      for (int i = 0; i < pairs.length; i++) {
        for (int j = i + 1; j < pairs.length; j++) {
          // If reading list length is not the same, can  skip
          if (pairs[i].readings.length != pairs[j].readings.length) continue;

          // Go through readings and check if they are all the same
          bool readingMismatch = false;
          for (int k = 0; k < pairs[i].readings.length; k++) {
            if (pairs[i].readings[k] != pairs[j].readings[k]) {
              readingMismatch = true;
              break;
            }
          }
          // If any of the readings were different, can skip
          if (readingMismatch) continue;

          // If got here, then can merge pairs if both kanji writing lists exist
          if (pairs[i].writings != null && pairs[j].writings != null) {
            pairs[i].writings!.addAll(pairs[j].writings!);

            // Remove pair that was merged from
            pairs.removeAt(j);
            j--;
          }
        }
      }

      return pairs;
    } else {
      // If have no writings return single pair with all non-search form readings
      return _readingOnlyPairs(vocab);
    }
  }

  static List<WritingReadingPair> _readingOnlyPairs(Vocab vocab) {
    List<VocabReading> readings = [];
    for (final reading in vocab.readings) {
      if (reading.info != null &&
          reading.info!.contains(ReadingInfo.searchOnlyForm)) {
        continue;
      }
      readings.add(reading);
    }

    return [WritingReadingPair(writings: null, readings: readings)];
  }
}
