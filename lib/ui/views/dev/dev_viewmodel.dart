// ignore_for_file: avoid_print

import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/isar_service.dart';
import 'package:stacked/stacked.dart';

class DevViewModel extends BaseViewModel {
  final _isarService = locator<IsarService>();

  bool _loading = false;
  bool get loading => _loading;

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
