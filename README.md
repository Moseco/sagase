# Sagase 探せ

A Japanese-English dictionary and learning tool built with [Flutter](https://docs.flutter.dev/).

<p align="center">
    <img width="400" alt="Search" src="https://user-images.githubusercontent.com/10720298/208696336-c4b5cab8-26d4-456a-bcbf-b2fe4e5ecc62.png"> 
    <img width="400" alt="Vocab" src="https://user-images.githubusercontent.com/10720298/208696345-4c77d60a-9528-4191-99fd-1ee8c0db6ebc.png">
    <img width="400" alt="Hand writing recognition" src="https://user-images.githubusercontent.com/10720298/209070998-3792e9c2-b14b-40e5-b686-283de429295e.png"> 
    <img width="400" alt="Lists" src="https://user-images.githubusercontent.com/10720298/208696348-b727ab3d-1d5c-4445-b20e-436cf8fc801c.png">
    <img width="400" alt="Flashcards" src="https://user-images.githubusercontent.com/10720298/208696328-d7a6c1c5-a7a9-487c-b078-32b82fa06aff.png">
</p>

## Getting Started

### Generate files with the following command:

```dart run build_runner build --delete-conflicting-outputs```

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
    - [x] Pitch accent
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
    - [x] Stroke order
- [x] Search
    - [x] Vocab
    - [x] Kanji
    - [x] Hand writing character recognition
- [x] Text analysis
- [x] Kanji radicals
    - [x] 214 classic kanji radicals
    - [x] Meaning
    - [x] Variants
    - [x] Kanji using the radical
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
    - [x] View spaced repetition performance 

## Special thanks

Thanks to [Electronic Dictionary Research and Development Group](http://www.edrdg.org/) for managing the source vocab and kanji dictionary files.

Thanks to the [KanjiVG project](http://kanjivg.tagaini.net/) for the kanji stroke order and kanji component data.

Thanks to [mifunetoshiro on Github](https://github.com/mifunetoshiro/kanjium) for providing the pitch accent data.
