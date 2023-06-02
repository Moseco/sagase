const int nestedNavigationKey = 1;

final kanjiRegExp = RegExp(r'(\p{Script=Han})', unicode: true);

const keyInitialCorrectInterval = 'initial_correct_interval';
const keyInitialVeryCorrectInterval = 'initial_very_correct_interval';
const keyShowNewInterval = 'show_new_interval';
const keyFlashcardLearningModeEnabled = 'flashcard_learning_mode_enabled';
const keyNewFlashcardsPerDay = 'new_flashcards_per_day';
const keyFlashcardDistance = 'flashcard_distance';
const keyFlashcardCorrectAnswersRequired = 'flashcard_correct_answers_required';
const keyShowPitchAccent = 'show_pitch_accent';

const defaultInitialCorrectInterval = 1;
const defaultInitialVeryCorrectInterval = 4;
const defaultShowNewInterval = false;
const defaultFlashcardLearningModeEnabled = false;
const defaultNewFlashcardsPerDay = 10;
const defaultFlashcardDistance = 15;
const defaultFlashcardCorrectAnswersRequired = 3;
const defaultShowPitchAccent = false;
