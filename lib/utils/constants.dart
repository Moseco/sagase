const int nestedNavigationKey = 1;

final kanjiRegExp = RegExp(r'(\p{Script=Han})', unicode: true);
final onlyFullWidthRomajiRegExp = RegExp(r'^[\uff01-\uff5e]+$');

const keyOnboardingFinished = 'onboarding_finished';
const keyInitialCorrectInterval = 'initial_correct_interval';
const keyInitialVeryCorrectInterval = 'initial_very_correct_interval';
const keyShowNewInterval = 'show_new_interval';
const keyFlashcardLearningModeEnabled = 'flashcard_learning_mode_enabled';
const keyNewFlashcardsPerDay = 'new_flashcards_per_day';
const keyFlashcardDistance = 'flashcard_distance';
const keyFlashcardCorrectAnswersRequired = 'flashcard_correct_answers_required';
const keyShowPitchAccent = 'show_pitch_accent';
const keyUseJapaneseSerifFont = 'use_japanese_serif_font';
const keyAnalyticsEnabled = 'analytics_enabled';
const keyStartOnLearningView = 'start_on_learning_view';
const keyStrokeDiagramStartExpanded = 'stroke_diagram_start_expanded';
const keyReviewStartTimestamp = 'review_start_timestamp';
const keyReviewStartCount = 'review_start_count';
const keyReviewRequested = 'review_requested';
const keyTutorialFlashcardSetSettings = 'tutorial_flashcard_set_settings';
const keyTutorialFlashcards = 'tutorial_flashcards';
const keyTutorialVocab = 'tutorial_vocab';
const keyShowDetailedProgress = 'show_detailed_progress';
const keyChangelogVersionShown = 'changelog_version_shown';

const defaultInitialCorrectInterval = 1;
const defaultInitialVeryCorrectInterval = 4;
const defaultShowNewInterval = false;
const defaultFlashcardLearningModeEnabled = false;
const defaultNewFlashcardsPerDay = 10;
const defaultFlashcardDistance = 15;
const defaultFlashcardCorrectAnswersRequired = 3;
const defaultShowPitchAccent = false;
const defaultUseJapaneseSerifFont = false;
const defaultAnalyticsEnabled = true;
const defaultStartOnLearningView = false;
const defaultStrokeDiagramStartExpanded = true;
const defaultShowDetailedProgress = false;

const searchQueryLimit = 1000;

const requiredAssetsTar = 'required_assets.tar';
const baseDictionaryZip = 'base_dictionary.zip';
const mecabDictionaryZip = 'mecab_dictionary.zip';

const currentChangelogVersion = 1;
