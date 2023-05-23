// ignore_for_file: avoid_print

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show compute;
import 'package:path_provider/path_provider.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:sagase/utils/dictionary_utils.dart';
import 'package:stacked/stacked.dart';

class DevViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();

  bool _loading = false;
  bool get loading => _loading;

  Future<void> createDatabase() async {
    _loading = true;
    notifyListeners();
    await DictionaryUtils.createDictionary();
    _loading = false;
    notifyListeners();
  }

  Future<void> exportDatabase() async {
    if (!Platform.isAndroid) {
      print('This function only works on Android');
      return;
    }
    _loading = true;
    notifyListeners();
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      print('Directory does not exist');
      return;
    }
    await compute(
      DictionaryUtils.exportDatabaseIsolate,
      directory.path,
    );
    _loading = false;
    notifyListeners();
  }

  Future<void> importDatabase() async {
    _loading = true;
    notifyListeners();
    await _isarService.close();
    await IsarService.importDatabase(DictionaryStatus.invalid);
    _loading = false;
    notifyListeners();
  }

  Future<void> runPerformanceTest() async {
    _loading = true;
    notifyListeners();

    String searchTerm = 'する';
    int iterations = 20;

    // Run once for index warmup
    await _isarService.searchDictionary(searchTerm);

    final start = DateTime.now();
    for (int i = 0; i < iterations; i++) {
      await _isarService.searchDictionary(searchTerm);
    }

    final end = DateTime.now();
    print('Time: ${end.difference(start).inMilliseconds / iterations}');

    _loading = false;
    notifyListeners();
  }
}
