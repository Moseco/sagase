import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/digital_ink_service.dart';
import 'package:sagase/services/download_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:sagase/utils/constants.dart' as constants;

import 'dictionary_service_helper.dart';
import 'mocks.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NavigationService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<DialogService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<BottomSheetService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<SnackbarService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<DictionaryService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<SharedPreferencesService>(
      onMissingStub: OnMissingStub.throwException),
  MockSpec<MecabService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<DigitalInkService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<DownloadService>(onMissingStub: OnMissingStub.throwException),
])
MockNavigationService getAndRegisterNavigationService() {
  _removeRegistrationIfExists<NavigationService>();
  final service = MockNavigationService();

  when(service.back()).thenReturn(false);

  locator.registerSingleton<NavigationService>(service);
  return service;
}

MockDialogService getAndRegisterDialogService({
  bool dialogResponseConfirmed = false,
}) {
  _removeRegistrationIfExists<DialogService>();
  final service = MockDialogService();

  when(service.showDialog(
    barrierDismissible: anyNamed('barrierDismissible'),
    buttonTitle: anyNamed('buttonTitle'),
    buttonTitleColor: anyNamed('buttonTitleColor'),
    cancelTitle: anyNamed('cancelTitle'),
    cancelTitleColor: anyNamed('cancelTitleColor'),
    description: anyNamed('description'),
    dialogPlatform: anyNamed('dialogPlatform'),
    title: anyNamed('title'),
  )).thenAnswer(
      (_) async => DialogResponse(confirmed: dialogResponseConfirmed));

  when(service.showCustomDialog(
    variant: anyNamed('variant'),
    title: anyNamed('title'),
    description: anyNamed('description'),
    hasImage: anyNamed('hasImage'),
    imageUrl: anyNamed('imageUrl'),
    showIconInMainButton: anyNamed('showIconInMainButton'),
    mainButtonTitle: anyNamed('mainButtonTitle'),
    showIconInSecondaryButton: anyNamed('showIconInSecondaryButton'),
    secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
    showIconInAdditionalButton: anyNamed('showIconInAdditionalButton'),
    additionalButtonTitle: anyNamed('additionalButtonTitle'),
    takesInput: anyNamed('takesInput'),
    barrierColor: anyNamed('barrierColor'),
    barrierDismissible: anyNamed('barrierDismissible'),
    barrierLabel: anyNamed('barrierLabel'),
    useSafeArea: anyNamed('useSafeArea'),
    customData: anyNamed('customData'),
    data: anyNamed('data'),
  )).thenAnswer(
      (_) async => DialogResponse(confirmed: dialogResponseConfirmed));

  locator.registerSingleton<DialogService>(service);
  return service;
}

MockBottomSheetService getAndRegisterBottomSheetService() {
  _removeRegistrationIfExists<BottomSheetService>();
  final service = MockBottomSheetService();
  locator.registerSingleton<BottomSheetService>(service);
  return service;
}

MockSnackbarService getAndRegisterSnackbarService() {
  _removeRegistrationIfExists<SnackbarService>();
  final service = MockSnackbarService();
  locator.registerSingleton<SnackbarService>(service);
  return service;
}

MockDictionaryService getAndRegisterDictionaryService({
  DictionaryStatus? open,
  ImportResult? importDatabase,
  List<Vocab>? getVocabList,
  List<Kanji>? getKanjiList,
  List<DictionaryItemIdsResult>? watchMyDictionaryListItems,
  List<int>? getMyDictionaryListsContainingDictionaryItem,
  Radical? getRadical,
  List<Kanji>? getKanjiWithRadical,
  Kanji? getKanji,
  List<DictionaryItem>? getFlashcardSetFlashcards,
  FlashcardSetReport? createFlashcardSetReport,
  FlashcardSetReport? getFlashcardSetReport,
  FlashcardSetReport? getRecentFlashcardSetReport,
  List<FlashcardSetReport>? getFlashcardSetReportRange,
}) {
  _removeRegistrationIfExists<DictionaryService>();
  final service = MockDictionaryService();

  when(service.initialize()).thenAnswer((_) async {});
  when(service.open(
    validate: anyNamed('validate'),
    transferCheck: anyNamed('transferCheck'),
  )).thenAnswer((_) async => open!);
  when(service.importDatabase(any)).thenAnswer((_) async => importDatabase!);
  when(service.close()).thenAnswer((_) async {});
  when(service.getVocabList(any)).thenAnswer((_) async => getVocabList!);
  when(service.getKanjiList(any)).thenAnswer((_) async => getKanjiList!);
  when(service.watchMyDictionaryListItems(any))
      .thenAnswer((_) => Stream.fromIterable(watchMyDictionaryListItems!));
  when(service.getMyDictionaryListsContainingDictionaryItem(any))
      .thenAnswer((_) async => getMyDictionaryListsContainingDictionaryItem!);
  when(service.getRadical(any)).thenAnswer((_) async => getRadical!);
  when(service.getKanjiWithRadical(any))
      .thenAnswer((_) async => getKanjiWithRadical!);
  when(service.getKanji(any)).thenAnswer((_) async => getKanji!);
  when(service.updateFlashcardSet(any)).thenAnswer((_) async {});
  when(service.getFlashcardSetFlashcards(any))
      .thenAnswer((_) async => getFlashcardSetFlashcards!);
  when(service.createFlashcardSetReport(any, any))
      .thenAnswer((_) async => createFlashcardSetReport!);
  when(service.setFlashcardSetReport(any)).thenAnswer((_) async {});
  when(service.getFlashcardSetReport(any, any))
      .thenAnswer((_) async => getFlashcardSetReport);
  when(service.getRecentFlashcardSetReport(any))
      .thenAnswer((_) async => getRecentFlashcardSetReport);
  when(service.getFlashcardSetReportRange(any, any, any))
      .thenAnswer((_) async => getFlashcardSetReportRange!);

  locator.registerSingleton<DictionaryService>(service);
  return service;
}

MockSharedPreferencesService getAndRegisterSharedPreferencesService({
  int getInitialCorrectInterval = constants.defaultInitialCorrectInterval,
  int getInitialVeryCorrectInterval =
      constants.defaultInitialVeryCorrectInterval,
  bool getFlashcardLearningModeEnabled =
      constants.defaultFlashcardLearningModeEnabled,
  int getNewFlashcardsPerDay = constants.defaultNewFlashcardsPerDay,
  int getFlashcardDistance = constants.defaultFlashcardDistance,
  int getFlashcardCorrectAnswersRequired =
      constants.defaultFlashcardCorrectAnswersRequired,
  bool getStrokeDiagramStartExpanded =
      constants.defaultStrokeDiagramStartExpanded,
  bool getAndSetTutorialVocab = false,
  bool getAndSetTutorialFlashcards = false,
  bool getShowPitchAccent = constants.defaultShowPitchAccent,
  bool getShowNewInterval = constants.defaultShowNewInterval,
  bool getShowDetailedProgress = constants.defaultShowDetailedProgress,
  bool getOnboardingFinished = false,
  bool getProperNounsEnabled = constants.defaultProperNounsEnabled,
}) {
  _removeRegistrationIfExists<SharedPreferencesService>();
  final service = MockSharedPreferencesService();

  when(service.getInitialCorrectInterval())
      .thenReturn(getInitialCorrectInterval);
  when(service.getInitialVeryCorrectInterval())
      .thenReturn(getInitialVeryCorrectInterval);
  when(service.getFlashcardLearningModeEnabled())
      .thenReturn(getFlashcardLearningModeEnabled);
  when(service.getNewFlashcardsPerDay()).thenReturn(getNewFlashcardsPerDay);
  when(service.getFlashcardDistance()).thenReturn(getFlashcardDistance);
  when(service.getFlashcardCorrectAnswersRequired())
      .thenReturn(getFlashcardCorrectAnswersRequired);
  when(service.getStrokeDiagramStartExpanded())
      .thenReturn(getStrokeDiagramStartExpanded);
  when(service.getAndSetTutorialVocab()).thenReturn(getAndSetTutorialVocab);
  when(service.getAndSetTutorialFlashcards())
      .thenReturn(getAndSetTutorialFlashcards);
  when(service.getShowPitchAccent()).thenReturn(getShowPitchAccent);
  when(service.getShowNewInterval()).thenReturn(getShowNewInterval);
  when(service.getShowDetailedProgress()).thenReturn(getShowDetailedProgress);
  when(service.getOnboardingFinished()).thenReturn(getOnboardingFinished);
  when(service.getProperNounsEnabled()).thenReturn(getProperNounsEnabled);

  locator.registerSingleton<SharedPreferencesService>(service);
  return service;
}

MockMecabService getAndRegisterMecabService({
  bool? initialize,
  bool? extractFiles,
  List<List<JapaneseTextToken>>? parseTextList,
  List<List<RubyTextPair>>? createRubyTextPairs,
}) {
  _removeRegistrationIfExists<MecabService>();
  final service = MockMecabService();

  when(service.initialize()).thenAnswer((_) async => initialize!);
  when(service.extractFiles()).thenAnswer((_) async => extractFiles!);
  when(service.parseText(any)).thenAnswer((_) => parseTextList!.removeAt(0));
  when(service.createRubyTextPairs(any, any))
      .thenAnswer((_) => createRubyTextPairs!.removeAt(0));

  locator.registerSingleton<MecabService>(service);
  return service;
}

MockDigitalInkService getAndRegisterDigitalInkService({
  bool? initialize,
}) {
  _removeRegistrationIfExists<DigitalInkService>();
  final service = MockDigitalInkService();

  when(service.initialize()).thenAnswer((_) async => initialize!);

  locator.registerSingleton<DigitalInkService>(service);
  return service;
}

MockDownloadService getAndRegisterDownloadService({
  bool? hasSufficientFreeSpace,
  bool? downloadRequiredAssets,
  bool? downloadDictionary,
}) {
  _removeRegistrationIfExists<DownloadService>();
  final service = MockDownloadService();

  when(service.hasSufficientFreeSpace())
      .thenAnswer((_) async => hasSufficientFreeSpace!);
  when(service.downloadRequiredAssets(useLocal: anyNamed('useLocal')))
      .thenAnswer((_) async => downloadRequiredAssets!);
  when(service.downloadDictionary(useLocal: anyNamed('useLocal')))
      .thenAnswer((_) async => downloadDictionary!);
  when(service.progressStream).thenAnswer((_) => Stream.fromIterable([1]));

  locator.registerSingleton<DownloadService>(service);
  return service;
}

void registerServices() {
  getAndRegisterNavigationService();
  getAndRegisterDialogService();
  getAndRegisterBottomSheetService();
  getAndRegisterSnackbarService();
  getAndRegisterDictionaryService();
  getAndRegisterSharedPreferencesService();
  getAndRegisterMecabService();
  getAndRegisterDigitalInkService();
  getAndRegisterDownloadService();
}

void unregisterServices() {
  locator.unregister<NavigationService>();
  locator.unregister<DialogService>();
  locator.unregister<BottomSheetService>();
  locator.unregister<SnackbarService>();
  locator.unregister<DictionaryService>();
  locator.unregister<SharedPreferencesService>();
  locator.unregister<MecabService>();
  locator.unregister<DigitalInkService>();
  locator.unregister<DownloadService>();
}

void _removeRegistrationIfExists<T extends Object>() {
  if (locator.isRegistered<T>()) {
    locator.unregister<T>();
  }
}

Future<DictionaryService> getAndRegisterRealDictionaryService({
  int vocabToCreate = 50,
}) async {
  _removeRegistrationIfExists<DictionaryService>();
  final service = await setUpDictionaryData(vocabToCreate: vocabToCreate);
  locator.registerSingleton<DictionaryService>(service);
  return service;
}
