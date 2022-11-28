# Sagase 探せ

A Japanese-English dictionary and learning tool built with [Flutter](https://docs.flutter.dev/).

## Getting Started

### Generate files with the following command:

```flutter pub run build_runner build --delete-conflicting-outputs```

## Feature list

- [ ] Vocab dictionary
    - [x] Kanji writing
    - [x] Hiragana/katakana reading
    - [x] Definition
    - [x] Kanji info
    - [x] Reading info
    - [x] Example sentences
    - [x] Associate kanji with specific reading
    - [x] Mark common words
    - [x] Extra information
    - [ ] Cross-referenced vocab
    - [ ] Antonyms
    - [x] Definition only associated with a certain kanji/reading
    - [x] Field of application
    - [x] Miscellaneous information
    - [x] Dialect
    - [x] Index
        - [x] Kanji writing
        - [x] Hiragana/katakana reading
        - [x] Romaji reading
        - [x] Simplified romaji reading (e.g. remove small tsu before conversion)
- [x] Kanji dictionary
    - [x] Kanji character
    - [x] Radical
    - [x] Components
    - [x] Grade
    - [x] Stroke count
    - [x] Frequency
    - [x] JLPT level
    - [x] Meanings
    - [x] On readings
    - [x] Kun readings
    - [x] Nanori
    - [x] Compounds
- [ ] Search
    - [x] Vocab
    - [x] Kanji
    - [ ] Hand writing character recognition
    - [ ] Sort by closest match
- [ ] Kanji radicals
    - [x] 214 classic kanji radicals
    - [x] Meaning
    - [x] Variants
    - [ ] Kanji using the radical
- [x] Hiragana and katakana table
- [x] Export/import database
- [x] Predefined vocab and kanji lists
- [x] User defined lists
- [ ] Flashcards
    - [x] Spaced repetition
    - [x] Random order
    - [x] Japanese front
    - [ ] English front 
    - [x] Customize front appearance
    - [ ] View spaced repetition performance 

## Special thanks

Thanks to [Electronic Dictionary Research and Development Group](http://www.edrdg.org/) for managing the source dictionary file.

### Files used

- [Vocab dictionary file from Electronic Dictionary Research and Development Group.](http://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project) Version used for this project is `JMdict_e_examp` (English only, with examples).

- [Kanji dictionary file from Electronic Dictionary Research and Development Group.](http://www.edrdg.org/wiki/index.php/KANJIDIC_Project) Version used for this project is `kanjidic2` (contains all 13,108 kanji).

- [Kanji component file from Electronic Dictionary Research and Development Group.](http://www.edrdg.org/krad/kradinf.html) Version used for this project is `kradfile` and `kradfile2` merged together and converted to utf-8 encoding (renamed to `kradfilex_utf-8`).
