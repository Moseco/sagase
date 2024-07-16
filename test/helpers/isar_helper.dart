import 'dart:ffi';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

Future<Isar> setUpIsar() async {
  // Create directory .dart_tool/isar_test/ to place Isar binary
  String downloadPath = path.join(
    Directory.current.path,
    '.dart_tool',
    'isar_test',
  );
  await Directory(downloadPath).create(recursive: true);

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
    libraries: {Abi.current(): path.join(downloadPath, binaryName)},
    download: true,
  );

  // Open Isar instance
  return Isar.open(
    IsarService.schemas,
    directory: (await path_provider.getApplicationSupportDirectory()).path,
    inspector: false,
  );
}
