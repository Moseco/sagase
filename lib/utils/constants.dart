const int dictionaryVersion = 3;
const int nestedNavigationKey = 1;

const int dictionaryListIdJouyou = 0;
const int dictionaryListIdJlptVocabN1 = 1;
const int dictionaryListIdJlptVocabN2 = 2;
const int dictionaryListIdJlptVocabN3 = 3;
const int dictionaryListIdJlptVocabN4 = 4;
const int dictionaryListIdJlptVocabN5 = 5;
const int dictionaryListIdJlptKanjiN1 = 6;
const int dictionaryListIdJlptKanjiN2 = 7;
const int dictionaryListIdJlptKanjiN3 = 8;
const int dictionaryListIdJlptKanjiN4 = 9;
const int dictionaryListIdJlptKanjiN5 = 10;
const int dictionaryListIdGradeLevel1 = 11;
const int dictionaryListIdGradeLevel2 = 12;
const int dictionaryListIdGradeLevel3 = 13;
const int dictionaryListIdGradeLevel4 = 14;
const int dictionaryListIdGradeLevel5 = 15;
const int dictionaryListIdGradeLevel6 = 16;
const int dictionaryListIdJinmeiyou = 17;

final kanjiRegExp = RegExp(r'(\p{Script=Han})', unicode: true);

const keyInitialCorrectInterval = 'initial_correct_interval';
const keyInitialVeryCorrectInterval = 'initial_very_correct_interval';
const keyShowNewInterval = 'show_new_interval';
const keyFlashcardLearningModeEnabled = 'flashcard_learning_mode_enabled';
const keyNewFlashcardsPerDay = 'new_flashcards_per_day';
const keyFlashcardDistance = 'flashcard_distance';
const keyFlashcardCorrectAnswersRequired = 'flashcard_correct_answers_required';

const defaultInitialCorrectInterval = 1;
const defaultInitialVeryCorrectInterval = 4;
const defaultShowNewInterval = false;
const defaultFlashcardLearningModeEnabled = false;
const defaultNewFlashcardsPerDay = 10;
const defaultFlashcardDistance = 15;
const defaultFlashcardCorrectAnswersRequired = 3;
