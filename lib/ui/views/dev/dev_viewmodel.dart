// ignore_for_file: avoid_print

import 'package:sagase/app/app.locator.dart';
import 'package:sagase/services/dictionary_service.dart';
import 'package:sagase/services/download_service.dart';
import 'package:stacked/stacked.dart';

class DevViewModel extends BaseViewModel {
  final _dictionaryService = locator<DictionaryService>();
  final _downloadService = locator<DownloadService>();

  bool _loading = false;
  bool get loading => _loading;

  Future<void> importDatabase() async {
    _loading = true;
    rebuildUi();

    // Get dictionary zip stored locally
    await _downloadService.downloadDictionary(useLocal: true);
    // Import database removing old database
    await _dictionaryService.close();
    await _dictionaryService.importDatabase(DictionaryStatus.invalid);

    _loading = false;
    rebuildUi();
  }
}
