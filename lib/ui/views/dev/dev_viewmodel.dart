// ignore_for_file: avoid_print

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sagase/utils/constants.dart' as constants;
import 'package:path/path.dart' as path;

class DevViewModel extends BaseViewModel {
  var _isarService = locator<IsarService>();

  bool _loading = false;
  bool get loading => _loading;

  Future<void> importDatabase() async {
    _loading = true;
    notifyListeners();
    // Get zip
    final byteData =
        await rootBundle.load('assets/dictionary/base_dictionary.zip');
    final bytes = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    final file = File(path.join(
      (await path_provider.getApplicationCacheDirectory()).path,
      constants.baseDictionaryZip,
    ));
    await file.writeAsBytes(bytes);
    // Import
    await _isarService.close();
    await IsarService.importDatabase(DictionaryStatus.invalid);
    // Reset isar
    final isarService = IsarService();
    await isarService.initialize(validate: false);
    locator.removeRegistrationIfExists<IsarService>();
    locator.registerSingleton<IsarService>(isarService);
    _isarService = isarService;
    _loading = false;
    notifyListeners();
  }

  Future<void> runPerformanceTest() async {
    _loading = true;
    notifyListeners();

    String searchTerm = 'する';
    int iterations = 20;

    // Run once for index warmup
    await _isarService.searchDictionary(searchTerm, SearchFilter.vocab);

    final start = DateTime.now();
    for (int i = 0; i < iterations; i++) {
      await _isarService.searchDictionary(searchTerm, SearchFilter.vocab);
    }

    final end = DateTime.now();
    print('Time: ${end.difference(start).inMilliseconds / iterations}');

    _loading = false;
    notifyListeners();
  }
}
