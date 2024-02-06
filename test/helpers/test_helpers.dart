import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/mecab_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:path/path.dart' as path;
import 'package:sagase/utils/constants.dart' as constants;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'fake_path_provider_platform.dart';
import 'test_helpers.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NavigationService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<DialogService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<BottomSheetService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<SnackbarService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<IsarService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<SharedPreferencesService>(
      onMissingStub: OnMissingStub.throwException),
  MockSpec<MecabService>(onMissingStub: OnMissingStub.throwException),
])
MockNavigationService getAndRegisterNavigationService() {
  _removeRegistrationIfExists<NavigationService>();
  final service = MockNavigationService();

  when(service.back()).thenReturn(false);
  when(service.navigateTo(any, arguments: anyNamed('arguments')))
      .thenAnswer((_) async => null);

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

MockIsarService getAndRegisterIsarService({
  List<Vocab>? getVocabList,
  List<Kanji>? getKanjiList,
  Stream<void>? watchMyDictionaryList,
  MyDictionaryList? getMyDictionaryList,
  bool? isKanjiInMyDictionaryLists,
  KanjiRadical? getKanjiRadical,
  List<Kanji>? getKanjiWithRadical,
  Kanji? getKanji,
  bool? isVocabInMyDictionaryLists,
  List<PredefinedDictionaryList>? getPredefinedDictionaryLists,
  List<MyDictionaryList>? getMyDictionaryLists,
}) {
  _removeRegistrationIfExists<IsarService>();
  final service = MockIsarService();

  when(service.getVocabList(any)).thenAnswer((_) async => getVocabList!);
  when(service.getKanjiList(any)).thenAnswer((_) async => getKanjiList!);
  when(service.watchMyDictionaryList(any))
      .thenAnswer((_) => watchMyDictionaryList!);
  when(service.getMyDictionaryList(any))
      .thenAnswer((_) async => getMyDictionaryList);
  when(service.isKanjiInMyDictionaryLists(any))
      .thenAnswer((_) async => isKanjiInMyDictionaryLists!);
  when(service.getKanjiRadical(any)).thenAnswer((_) async => getKanjiRadical!);
  when(service.getKanjiWithRadical(any))
      .thenAnswer((_) async => getKanjiWithRadical!);
  when(service.getKanji(any)).thenAnswer((_) async => getKanji!);
  when(service.isVocabInMyDictionaryLists(any))
      .thenAnswer((_) async => isVocabInMyDictionaryLists!);
  when(service.getPredefinedDictionaryLists(any))
      .thenAnswer((_) async => getPredefinedDictionaryLists!);
  when(service.getMyDictionaryLists(any))
      .thenAnswer((_) async => getMyDictionaryLists!);
  when(service.updateFlashcardSet(any)).thenAnswer((_) async {});

  locator.registerSingleton<IsarService>(service);
  return service;
}

Future<IsarService> getAndRegisterRealIsarService(Isar isar) async {
  _removeRegistrationIfExists<IsarService>();
  final service = IsarService(isar: isar);
  locator.registerSingleton<IsarService>(service);
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

  locator.registerSingleton<SharedPreferencesService>(service);
  return service;
}

MockMecabService getAndRegisterMecabService({
  List<List<JapaneseTextToken>>? parseTextList,
  List<List<RubyTextPair>>? createRubyTextPairs,
}) {
  _removeRegistrationIfExists<MecabService>();
  final service = MockMecabService();

  when(service.parseText(any)).thenAnswer((_) => parseTextList!.removeAt(0));
  when(service.createRubyTextPairs(any, any))
      .thenAnswer((_) => createRubyTextPairs!.removeAt(0));

  locator.registerSingleton<MecabService>(service);
  return service;
}

void registerServices() {
  getAndRegisterNavigationService();
  getAndRegisterDialogService();
  getAndRegisterBottomSheetService();
  getAndRegisterSnackbarService();
  getAndRegisterIsarService();
  getAndRegisterSharedPreferencesService();
  getAndRegisterMecabService();
}

void unregisterServices() {
  locator.unregister<NavigationService>();
  locator.unregister<DialogService>();
  locator.unregister<BottomSheetService>();
  locator.unregister<SnackbarService>();
  locator.unregister<IsarService>();
  locator.unregister<SharedPreferencesService>();
  locator.unregister<MecabService>();
}

void _removeRegistrationIfExists<T extends Object>() {
  if (locator.isRegistered<T>()) {
    locator.unregister<T>();
  }
}

Future<Isar> setUpIsar() async {
  // Create directory .dart_tool/isar_test/tmp/
  final dartToolDir = path.join(Directory.current.path, '.dart_tool');
  String testTempPath = path.join(dartToolDir, 'isar_test', 'tmp');
  String downloadPath = path.join(dartToolDir, 'isar_test');
  await Directory(testTempPath).create(recursive: true);

  // Get name of isar binary based on platform
  late String binaryName;
  switch (Abi.current()) {
    case Abi.macosX64:
      binaryName = 'libisar.dylib';
      break;
    case Abi.linuxX64:
      binaryName = 'libisar.so';
      break;
    case Abi.windowsX64:
      binaryName = 'isar.dll';
      break;
    default:
      throw Exception('Unsupported platform for testing');
  }

  // Downloads Isar binary file
  await Isar.initializeIsarCore(
    libraries: {
      Abi.current(): '$downloadPath${Platform.pathSeparator}$binaryName'
    },
    download: true,
  );

  // Open Isar instance with random name
  return Isar.open(
    IsarService.schemas,
    directory: testTempPath,
    name: Random().nextInt(pow(2, 32) as int).toString(),
    inspector: false,
  );
}

Future<void> setUpFakePathProvider() async {
  final dartToolDir = path.join(Directory.current.path, '.dart_tool');
  String pathProviderPath = path.join(dartToolDir, 'path_provider_test');
  await Directory(pathProviderPath).create(recursive: true);
  PathProviderPlatform.instance = FakePathProviderPlatform(pathProviderPath);
}
