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

  bool shouldRequestAppReview() {
    // Only allow requests once
    if (_sharedPreferences.getBool(constants.keyReviewRequested) ?? false) {
      return false;
    }

    late DateTime startDateTime;
    int? millisecondsSinceEpoch =
        _sharedPreferences.getInt(constants.keyReviewStartTimestamp);
    if (millisecondsSinceEpoch == null) {
      startDateTime = DateTime.now();
      _sharedPreferences.setInt(constants.keyReviewStartTimestamp,
          startDateTime.millisecondsSinceEpoch);
    } else {
      startDateTime =
          DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    }

    int startCount =
        (_sharedPreferences.getInt(constants.keyReviewStartCount) ?? 0) + 1;
    // Make sure the user has used the app for a week and opened the app at least 20 times
    if (startCount > 20 &&
        DateTime.now().difference(startDateTime).inDays > 7) {
      _sharedPreferences.setBool(constants.keyReviewRequested, true);
      return true;
    } else {
      _sharedPreferences.setInt(constants.keyReviewStartCount, startCount);
      return false;
    }
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
}
