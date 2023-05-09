import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String basePath;

  FakePathProviderPlatform(this.basePath);
  @override
  Future<String?> getTemporaryPath() async {
    String path = '$basePath${Platform.pathSeparator}temporary';
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    String path = '$basePath${Platform.pathSeparator}applicationSupport';
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getLibraryPath() async {
    String path = '$basePath${Platform.pathSeparator}library';
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    String path = '$basePath${Platform.pathSeparator}applicationDocuments';
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getExternalStoragePath() async {
    String path = '$basePath${Platform.pathSeparator}externalStorage';
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    String path = '$basePath${Platform.pathSeparator}externalCache';
    await Directory(path).create(recursive: true);
    return [path];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    String path = '$basePath${Platform.pathSeparator}externalStorage';
    await Directory(path).create(recursive: true);
    return [path];
  }

  @override
  Future<String?> getDownloadsPath() async {
    String path = '$basePath${Platform.pathSeparator}downloads';
    await Directory(path).create(recursive: true);
    return path;
  }
}
