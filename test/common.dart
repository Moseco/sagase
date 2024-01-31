import 'package:sagase_dictionary/sagase_dictionary.dart';

final vocabBasic = Vocab()
  ..kanjiReadingPairs = [
    KanjiReadingPair()
      ..kanjiWritings = [VocabKanji()..kanji = '秋']
      ..readings = [
        VocabReading()
          ..reading = 'あき'
          ..pitchAccents = [1]
      ],
  ]
  ..definitions = [
    VocabDefinition()
      ..definition = 'autumn; fall'
      ..pos = [PartOfSpeech.noun, PartOfSpeech.adverb]
      ..examples = [
        VocabExample()
          ..english = 'Leaves fall in the autumn.'
          ..japanese = '秋には木の葉が落ちる。'
      ],
  ]
  ..commonWord = true
  ..frequencyScore = 140148;

final vocabReadingOnly = Vocab()
  ..kanjiReadingPairs = [
    KanjiReadingPair()
      ..readings = [
        VocabReading()
          ..reading = 'はい'
          ..pitchAccents = [1]
      ],
  ]
  ..pos = [PartOfSpeech.interjection]
  ..definitions = [
    VocabDefinition()
      ..definition = 'yes; that is correct'
      ..miscInfo = [MiscellaneousInfo.politeLanguage]
      ..examples = [
        VocabExample()
          ..english = '"Hello, is this Mrs. Brown?" "Yes, this is Mrs. Brown."'
          ..japanese = '「もしもし、ブラウンさんですか」「はい、そうです」'
      ],
    VocabDefinition()
      ..definition = 'understood; I see; OK; okay'
      ..examples = [
        VocabExample()
          ..english = 'Here\'s a magazine for you to read in the plane.'
          ..japanese = 'はいどうぞ、君が飛行機の中で読む雑誌です。'
      ],
    VocabDefinition()
      ..definition = 'present; here'
      ..additionalInfo = 'as a response to a roll call',
    VocabDefinition()
      ..definition = 'with rising intonation'
      ..additionalInfo = 'pardon?; what\'s that?; come again?'
      ..miscInfo = [MiscellaneousInfo.colloquialism],
    VocabDefinition()
      ..definition = 'now; here; here you go'
      ..additionalInfo =
          'used when calling for someone\'s attention or when handing something to someone',
    VocabDefinition()..definition = 'giddy-up; giddap',
  ]
  ..commonWord = true
  ..frequencyScore = 26760;

final kanjiBasic = Kanji()
  ..kanji = '探'
  ..radical = '手'
  ..components = ['㓁', '木']
  ..grade = 6
  ..strokeCount = 11
  ..frequency = 930
  ..jlpt = 2
  ..meanings = ['grope', 'search', 'look for']
  ..kunReadings = ['さぐ.る', 'さが.す']
  ..onReadings = ['タン']
  ..strokes = [
    'M11.75,38.42c2.08,0.25,3.01,0.24,5.25,0c5.12-0.54,9.85-1.25,17.76-2.36c1.84-0.26,2.99-0.18,4.16-0.06',
    'M28.02,15c1.12,1.12,1.51,2.5,1.51,4.77c0,15.23,0.24,54.71,0.24,66.15c0,14.25-6.32,3.53-7.77,2',
    'M12.29,68.98c0.75,0.66,1.99,1.07,3.34,0.04c7.25-5.52,12.25-9.4,21.25-16.65',
    'M46.89,18.88c0,3.09-2.2,11.6-3.21,13.66',
    'M47.57,21.12c7.45-0.77,33.43-3.55,39.48-3.84c9.44-0.46,2,5.36-0.35,7.02',
    'M57.64,26.75c0.1,1.11,0.01,2.21-0.52,3.18c-2.5,4.57-5.5,9.07-12.1,14.24',
    'M70.35,23.62c0.7,0.7,1,1.75,1,2.95c0,2.43-0.04,4.56-0.04,7.57c0,2.74,1.19,4.42,9.64,4.42c5.04,0,8.12-0.64,8.82-1.01',
    'M43.55,55.58c2.45,0.42,4.64,0.3,6.82,0.05c7.14-0.79,22.48-2.24,32.25-2.95c1.86-0.13,4.37-0.19,5.77,0.18',
    'M64.99,42.25c0.82,0.82,1.08,2.12,1.08,3.29c0,5.89,0.02,32.12-0.07,44.84c-0.02,3.25,0.04,4.98,0,5.88',
    'M64.09,54.97c0,1.28-0.99,3.42-1.96,5C56.69,68.9,49.75,77.5,39.73,84.1',
    'M66.78,55.3c3.6,4.33,14.47,15.89,21.46,23.2c1.72,1.8,5.51,5,7.78,6.55',
  ]
  ..compounds = [1418380];
