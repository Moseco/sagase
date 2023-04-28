import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:isar/isar.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:path/path.dart' as path;
import 'package:sagase/utils/constants.dart' as constants;

import 'test_helpers.mocks.dart';

// Run the following to generate files
//    flutter pub run build_runner build --delete-conflicting-outputs
@GenerateMocks([], customMocks: [
  MockSpec<NavigationService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<DialogService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<IsarService>(onMissingStub: OnMissingStub.throwException),
  MockSpec<SharedPreferencesService>(
      onMissingStub: OnMissingStub.throwException),
])
MockNavigationService getAndRegisterNavigationService() {
  _removeRegistrationIfExists<NavigationService>();
  final service = MockNavigationService();

  when(service.back()).thenAnswer((realInvocation) => false);

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
  )).thenAnswer((realInvocation) =>
      Future.value(DialogResponse(confirmed: dialogResponseConfirmed)));

  locator.registerSingleton<DialogService>(service);
  return service;
}

MockIsarService getAndRegisterIsarService() {
  _removeRegistrationIfExists<IsarService>();
  final service = MockIsarService();
  locator.registerSingleton<IsarService>(service);
  return service;
}

Future<IsarService> getAndRegisterRealIsarService(Isar isar) async {
  _removeRegistrationIfExists<IsarService>();
  final service = await IsarService.initialize(testingIsar: isar);
  locator.registerSingleton<IsarService>(service);
  return service;
}

MockSharedPreferencesService getAndRegisterSharedPreferencesService({
  bool flashcardLearningModeEnabled =
      constants.defaultFlashcardLearningModeEnabled,
  int newFlashcardsPerDay = constants.defaultNewFlashcardsPerDay,
  int flashcardDistance = constants.defaultFlashcardDistance,
  int flashcardCorrectAnswersRequired =
      constants.defaultFlashcardCorrectAnswersRequired,
}) {
  _removeRegistrationIfExists<SharedPreferencesService>();
  final service = MockSharedPreferencesService();

  when(service.getInitialCorrectInterval())
      .thenReturn(constants.defaultInitialCorrectInterval);
  when(service.getInitialVeryCorrectInterval())
      .thenReturn(constants.defaultInitialVeryCorrectInterval);
  when(service.getFlashcardLearningModeEnabled())
      .thenReturn(flashcardLearningModeEnabled);
  when(service.getNewFlashcardsPerDay()).thenReturn(newFlashcardsPerDay);
  when(service.getFlashcardDistance()).thenReturn(flashcardDistance);
  when(service.getFlashcardCorrectAnswersRequired())
      .thenReturn(flashcardCorrectAnswersRequired);

  locator.registerSingleton<SharedPreferencesService>(service);
  return service;
}

void registerServices() {
  getAndRegisterNavigationService();
  getAndRegisterDialogService();
  getAndRegisterIsarService();
  getAndRegisterSharedPreferencesService();
}

void unregisterServices() {
  locator.unregister<NavigationService>();
  locator.unregister<DialogService>();
  locator.unregister<IsarService>();
  locator.unregister<SharedPreferencesService>();
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
