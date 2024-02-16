import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:path/path.dart';

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String basePath;

  FakePathProviderPlatform(this.basePath);

  @override
  Future<String?> getApplicationCachePath() async {
    String path = join(basePath, 'applicationCache');
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getApplicationDocumentsPath() async {
    String path = join(basePath, 'applicationDocuments');
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    String path = join(basePath, 'applicationSupport');
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    String path = join(basePath, 'downloads');
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<List<String>?> getExternalCachePaths() async {
    String path = join(basePath, 'externalCache');
    await Directory(path).create(recursive: true);
    return [path];
  }

  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    String path = join(basePath, 'externalStorage');
    await Directory(path).create(recursive: true);
    return [path];
  }

  @override
  Future<String?> getExternalStoragePath() async {
    String path = join(basePath, 'externalStorage');
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getLibraryPath() async {
    String path = join(basePath, 'library');
    await Directory(path).create(recursive: true);
    return path;
  }

  @override
  Future<String?> getTemporaryPath() async {
    String path = join(basePath, 'temporary');
    await Directory(path).create(recursive: true);
    return path;
  }
}
