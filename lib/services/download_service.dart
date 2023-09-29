import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sagase/utils/download_options.dart';

class DownloadService {
  StreamController<double>? _streamController;
  Stream<double>? get progressStream => _streamController?.stream;

  Future<bool> downloadRequiredAssets({bool useLocal = false}) async {
    // Option to get assets locally
    if (useLocal) {
      await downloadBaseDictionary(useLocal: true);
      await downloadMecabDictionary(useLocal: true);

      return true;
    }

    _streamController?.close();
    _streamController = StreamController<double>();

    final tempPath = (await path_provider.getTemporaryDirectory()).path;

    final result = await _downloadFile(
      DownloadOptions.getRequiredAssetsUrl(),
      '$tempPath/required_assets.tar',
    );

    // Extract tar and delete after
    final tar = File('$tempPath/required_assets.tar');
    if (await tar.exists()) {
      final rootIsolateToken = RootIsolateToken.instance!;
      await Isolate.run(() async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
        await extractFileToDisk(tar.path, tempPath);
        await tar.delete();
      });
    }

    return result;
  }

  Future<bool> downloadBaseDictionary({bool useLocal = false}) async {
    // Option to get asset locally
    if (useLocal) {
      // Get zip data
      final byteData =
          await rootBundle.load('assets/dictionary/base_dictionary.zip');

      // Copy zip to temporary directory file
      final bytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final tempDir = await path_provider.getTemporaryDirectory();
      final file = File('${tempDir.path}/base_dictionary.zip');
      await file.writeAsBytes(bytes);

      return true;
    }

    _streamController?.close();
    _streamController = StreamController<double>();

    return _downloadFile(
      DownloadOptions.getBaseDictionaryUrl(),
      '${(await path_provider.getTemporaryDirectory()).path}/base_dictionary.zip',
    );
  }

  Future<bool> downloadMecabDictionary({bool useLocal = false}) async {
    // Option to get asset locally
    if (useLocal) {
      // Get zip data
      final byteData =
          await rootBundle.load('assets/mecab/mecab_dictionary.zip');

      // Copy zip to temporary directory file
      final bytes = byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
      final tempDir = await path_provider.getTemporaryDirectory();
      final file = File('${tempDir.path}/mecab_dictionary.zip');
      await file.writeAsBytes(bytes);

      return true;
    }

    _streamController?.close();
    _streamController = StreamController<double>();

    return _downloadFile(
      DownloadOptions.getMecabDictionaryUrl(),
      '${(await path_provider.getTemporaryDirectory()).path}/mecab_dictionary.zip',
    );
  }

  Future<bool> _downloadFile(String url, String path) async {
    late bool result;
    try {
      await Dio().download(
        url,
        path,
        onReceiveProgress: (count, total) =>
            _streamController!.add(count / total),
      );
      result = true;
    } catch (_) {
      result = false;
    }

    _streamController!.close();
    return result;
  }
}
