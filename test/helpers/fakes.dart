import 'dart:io';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'fake_path_provider_platform.dart';

void setUpFakePathProvider() {
  final directory = Directory.systemTemp.createTempSync('path_provider_test.');
  PathProviderPlatform.instance = FakePathProviderPlatform(directory.path);
}

void cleanUpFakePathProvider() {
  Directory(
    (PathProviderPlatform.instance as FakePathProviderPlatform).basePath,
  ).deleteSync(recursive: true);
}
