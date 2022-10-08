// ignore_for_file: avoid_print

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart';
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
    await compute(
      DictionaryUtils.createDictionaryIsolate,
      DictionarySource(
        await rootBundle.loadString('assets/dictionary_source/JMdict_e_examp'),
        await rootBundle.loadString('assets/dictionary_source/kanjidic2.xml'),
        await rootBundle.loadString('assets/dictionary_source/kradfilex_utf-8'),
      ),
    );
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
    await IsarService.importDatabase();
    _loading = false;
    notifyListeners();
  }

  Future<void> runPerformanceTest() async {
    _loading = true;
    notifyListeners();

    final start = DateTime.now();
    final list = await _isarService.searchVocab('ku');
    final end = DateTime.now();
    print('Time: ${end.difference(start).inMilliseconds}');

    _loading = false;
    notifyListeners();
  }
}
