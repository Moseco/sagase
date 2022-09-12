# Sagase 探せ

A Japanese-English dictionary and learning tool built with [Flutter](https://docs.flutter.dev/).

## Getting Started

### Generate files with the following command:

```flutter pub run build_runner build --delete-conflicting-outputs```

### Download required files

Download the following files and place them in `assets/dictionary_source/`

- [Vocab dictionary file from Electronic Dictionary Research and Development Group.](http://www.edrdg.org/wiki/index.php/JMdict-EDICT_Dictionary_Project) Version used for this project is the `JMdict_e_examp` (English only, with examples).

- [Kanji dictionary file from Electronic Dictionary Research and Development Group.](http://www.edrdg.org/wiki/index.php/KANJIDIC_Project) Version used for this project is the `kanjidic2` (contains all 13,108 kanji).

## Feature list

- [ ] Create vocab dictionary
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
    - [x] Index
        - [x] Kanji writing
        - [x] Hiragana/katakana reading
        - [x] Romaji reading
        - [x] Simplified romaji reading (e.g. remove small tsu before conversion)
- [x] Create kanji dictionary
    - [x] Kanji character
    - [x] Radical
    - [x] Grade
    - [x] Stroke count
    - [x] Variants
    - [x] Frequency
    - [x] JLPT level
    - [x] Meanings
    - [x] On readings
    - [x] Kun readings
    - [x] Nanori
    - [x] Compounds
- [x] Export/import database
- [ ] Search
    - [ ] Search vocab
    - [ ] Search kanji
    - [ ] Hand writing character recognition
- [ ] Vocab entry view
- [ ] Kanji entry view
- [ ] Standard kanji and vocab lists
- [ ] Bookmarks
- [ ] Flashcards

## Special thanks

Thanks to [Electronic Dictionary Research and Development Group](http://www.edrdg.org/) for managing the dictionary file.
