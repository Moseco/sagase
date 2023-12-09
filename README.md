# Sagase 探せ

A Japanese-English dictionary and learning app built with [Flutter](https://docs.flutter.dev/).

<p align="center">
    <img width="400" alt="Search" src="https://github.com/Moseco/sagase/assets/10720298/4a0c240f-fc80-4135-aebd-4d48c15343af">
    <img width="400" alt="Hand writing recognition" src="https://github.com/Moseco/sagase/assets/10720298/7e08ac1f-efe7-47f3-bb13-051b5b14903c"> 
    <img width="400" alt="Vocab (light)" src="https://github.com/Moseco/sagase/assets/10720298/796609e5-aa3f-4199-bed9-82406525b174">
    <img width="400" alt="Vocab (dark)" src="https://github.com/Moseco/sagase/assets/10720298/5629c95f-c46f-4352-a09a-d721e6f323c1">
    <img width="400" alt="Kanji" src="https://github.com/Moseco/sagase/assets/10720298/37b0e0a6-242b-4941-9270-d079f590af52"> 
    <img width="400" alt="Lists" src="https://github.com/Moseco/sagase/assets/10720298/11da274a-fa29-47dc-bf95-33263bc5e6c4">
    <img width="400" alt="Flashcards front" src="https://github.com/Moseco/sagase/assets/10720298/08320b50-25ec-45ab-b8c5-63fb44be709a">
    <img width="400" alt="Flashcards back" src="https://github.com/Moseco/sagase/assets/10720298/00ce936f-f26f-43ee-923e-4998c13d2d74">
</p>

## Getting Started

### Generate files with the following command:

```dart run build_runner build```

### Firebase

This project uses Firebase for analytics and crash reporting.

See [this set up guide](https://firebase.google.com/docs/flutter/setup) for how to configure your own Firebase project.

### Dictionary assets

The download urls for the required assets are not included in the repo. You can either set up remote storage yourself or include the assets in the app itself. To do this complete the following steps:

1. Download the assets from the current [sagase dictionary Github](https://github.com/Moseco/sagase_dictionary) release.
2. Uncomment the asset inclusion in ```pubspec.yaml``` and place the downloaded files accordingly.
3. Modify ```splash_screen_viewmodel.dart``` and ```download_service.dart``` to always pull from the included assets.

## Feature list

- [x] Vocab dictionary
    - [x] Kanji writing
    - [x] Hiragana/katakana reading
    - [x] Definition
    - [x] Kanji info
    - [x] Reading info
    - [x] Example sentences
    - [x] Associate kanji with specific reading
    - [x] Mark common words
    - [x] Extra information
    - [x] Cross-referenced vocab
    - [x] Antonyms
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
- [x] Flashcards
    - [x] Spaced repetition
    - [x] Random order
    - [x] Japanese front
    - [x] English front 
    - [x] Customize front appearance
    - [x] View spaced repetition performance 

## Special thanks

Thanks to [Electronic Dictionary Research and Development Group](http://www.edrdg.org/) for managing the source vocab and kanji dictionary files.

Thanks to [Tatoeba](https://tatoeba.org) for managing the Japanese-English example sentence pairs.

Thanks to the [KanjiVG project](http://kanjivg.tagaini.net/) for the kanji stroke order and kanji component data.

Thanks to the [creator of MeCab](https://taku910.github.io/mecab) for the Japanese text analyzer and tokenizer.

Thanks to [mifunetoshiro on Github](https://github.com/mifunetoshiro/kanjium) for providing the pitch accent data.
