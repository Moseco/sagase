import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:stacked/stacked_annotations.dart';

class SharedPreferencesService implements InitializableDependency {
  late final SharedPreferences _sharedPreferences;

  @override
  Future<void> init() async {
    _sharedPreferences = await SharedPreferences.getInstance();
  }

  bool getOnboardingFinished() {
    return _sharedPreferences.getBool(constants.keyOnboardingFinished) ?? false;
  }

  Future<void> setOnboardingFinished() async {
    await _sharedPreferences.setBool(constants.keyOnboardingFinished, true);
  }

  int getInitialCorrectInterval() {
    return _sharedPreferences.getInt(constants.keyInitialCorrectInterval) ??
        constants.defaultInitialCorrectInterval;
  }

  Future<void> setInitialCorrectInterval(int value) async {
    await _sharedPreferences.setInt(
      constants.keyInitialCorrectInterval,
      value,
    );
  }

  int getInitialVeryCorrectInterval() {
    return _sharedPreferences.getInt(constants.keyInitialVeryCorrectInterval) ??
        constants.defaultInitialVeryCorrectInterval;
  }

  Future<void> setInitialVeryCorrectInterval(int value) async {
    await _sharedPreferences.setInt(
      constants.keyInitialVeryCorrectInterval,
      value,
    );
  }

  bool getShowNewInterval() {
    return _sharedPreferences.getBool(constants.keyShowNewInterval) ??
        constants.defaultShowNewInterval;
  }

  Future<void> setShowNewInterval(bool value) async {
    await _sharedPreferences.setBool(constants.keyShowNewInterval, value);
  }

  bool getFlashcardLearningModeEnabled() {
    return _sharedPreferences
            .getBool(constants.keyFlashcardLearningModeEnabled) ??
        constants.defaultFlashcardLearningModeEnabled;
  }

  Future<void> setFlashcardLearningModeEnabled(bool value) async {
    await _sharedPreferences.setBool(
      constants.keyFlashcardLearningModeEnabled,
      value,
    );
  }

  int getNewFlashcardsPerDay() {
    return _sharedPreferences.getInt(constants.keyNewFlashcardsPerDay) ??
        constants.defaultNewFlashcardsPerDay;
  }

  Future<void> setNewFlashcardsPerDay(int value) async {
    await _sharedPreferences.setInt(
      constants.keyNewFlashcardsPerDay,
      value,
    );
  }

  int getFlashcardDistance() {
    return _sharedPreferences.getInt(constants.keyFlashcardDistance) ??
        constants.defaultFlashcardDistance;
  }

  Future<void> setFlashcardDistance(int value) async {
    await _sharedPreferences.setInt(
      constants.keyFlashcardDistance,
      value,
    );
  }

  int getFlashcardCorrectAnswersRequired() {
    return _sharedPreferences
            .getInt(constants.keyFlashcardCorrectAnswersRequired) ??
        constants.defaultFlashcardCorrectAnswersRequired;
  }

  Future<void> setFlashcardCorrectAnswersRequired(int value) async {
    await _sharedPreferences.setInt(
      constants.keyFlashcardCorrectAnswersRequired,
      value,
    );
  }

  bool getShowPitchAccent() {
    return _sharedPreferences.getBool(constants.keyShowPitchAccent) ??
        constants.defaultShowPitchAccent;
  }

  Future<void> setShowPitchAccent(bool value) async {
    await _sharedPreferences.setBool(constants.keyShowPitchAccent, value);
  }

  bool getUseJapaneseSerifFont() {
    return _sharedPreferences.getBool(constants.keyUseJapaneseSerifFont) ??
        constants.defaultUseJapaneseSerifFont;
  }

  Future<void> setUseJapaneseSerifFont(bool value) async {
    await _sharedPreferences.setBool(constants.keyUseJapaneseSerifFont, value);
  }

  bool getAnalyticsEnabled() {
    return _sharedPreferences.getBool(constants.keyAnalyticsEnabled) ??
        constants.defaultAnalyticsEnabled;
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    await _sharedPreferences.setBool(constants.keyAnalyticsEnabled, value);
  }

  bool getStartOnLearningView() {
    return _sharedPreferences.getBool(constants.keyStartOnLearningView) ??
        constants.defaultStartOnLearningView;
  }

  Future<void> setStartOnLearningView(bool value) async {
    await _sharedPreferences.setBool(constants.keyStartOnLearningView, value);
  }

  bool getStrokeDiagramStartExpanded() {
    return _sharedPreferences
            .getBool(constants.keyStrokeDiagramStartExpanded) ??
        constants.defaultStrokeDiagramStartExpanded;
  }

  Future<void> setStrokeDiagramStartExpanded(bool value) async {
    await _sharedPreferences.setBool(
        constants.keyStrokeDiagramStartExpanded, value);
  }

  bool getReviewRequested() {
    return _sharedPreferences.getBool(constants.keyReviewRequested) ?? false;
  }

  Future<void> setReviewRequested() async {
    await _sharedPreferences.setBool(constants.keyReviewRequested, true);
  }

  DateTime getReviewStartTimestamp() {
    late DateTime dateTime;
    int? millisecondsSinceEpoch =
        _sharedPreferences.getInt(constants.keyReviewStartTimestamp);
    if (millisecondsSinceEpoch == null) {
      dateTime = DateTime.now();
      _sharedPreferences.setInt(
          constants.keyReviewStartTimestamp, dateTime.millisecondsSinceEpoch);
    } else {
      dateTime = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }
    return dateTime;
  }

  int getReviewStartCount() {
    return _sharedPreferences.getInt(constants.keyReviewStartCount) ?? 0;
  }

  Future<void> setReviewStartCount(int value) async {
    _sharedPreferences.setInt(constants.keyReviewStartCount, value);
  }

  bool getAndSetTutorialFlashcardSetSettings() {
    bool value =
        _sharedPreferences.getBool(constants.keyTutorialFlashcardSetSettings) ??
            true;
    if (value) {
      _sharedPreferences.setBool(
          constants.keyTutorialFlashcardSetSettings, false);
    }

    return value;
  }

  bool getAndSetTutorialFlashcards() {
    bool value =
        _sharedPreferences.getBool(constants.keyTutorialFlashcards) ?? true;
    if (value) {
      _sharedPreferences.setBool(constants.keyTutorialFlashcards, false);
    }

    return value;
  }

  bool getAndSetTutorialVocab() {
    bool value = _sharedPreferences.getBool(constants.keyTutorialVocab) ?? true;
    if (value) {
      _sharedPreferences.setBool(constants.keyTutorialVocab, false);
    }

    return value;
  }

  bool getShowDetailedProgress() {
    return _sharedPreferences.getBool(constants.keyShowDetailedProgress) ??
        constants.defaultShowDetailedProgress;
  }

  Future<void> setShowDetailedProgress(bool value) async {
    await _sharedPreferences.setBool(constants.keyShowDetailedProgress, value);
  }

  int? getChangelogVersionShown() {
    return _sharedPreferences.getInt(constants.keyChangelogVersionShown);
  }

  Future<void> setChangelogVersionShown() async {
    await _sharedPreferences.setInt(
      constants.keyChangelogVersionShown,
      constants.currentChangelogVersion,
    );
  }

  bool getProperNounsEnabled() {
    return _sharedPreferences.getBool(constants.keyProperNounsEnabled) ??
        constants.defaultProperNounsEnabled;
  }

  Future<void> setProperNounsEnabled(bool value) async {
    await _sharedPreferences.setBool(constants.keyProperNounsEnabled, value);
  }
}
