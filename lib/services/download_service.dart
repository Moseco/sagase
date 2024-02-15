import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:sagase/utils/constants.dart' as constants;
import 'package:sagase/utils/download_options.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:path/path.dart' as path;

class DownloadService {
  StreamController<double>? _streamController;
  Stream<double>? get progressStream => _streamController?.stream;

  Future<bool> downloadRequiredAssets({bool useLocal = false}) async {
    try {
      // Option to get assets locally
      if (useLocal) {
        await downloadBaseDictionary(useLocal: true);
        await downloadMecabDictionary(useLocal: true);

        return true;
      }

      _streamController?.close();
      _streamController = StreamController<double>();

      final cachePath =
          (await path_provider.getApplicationCacheDirectory()).path;
      final tarPath = path.join(cachePath, constants.requiredAssetsTar);

      final result = await _downloadFile(
        DownloadOptions.getRequiredAssetsUrl(),
        tarPath,
      );

      // Extract tar and delete after
      final tar = File(tarPath);
      if (await tar.exists()) {
        final rootIsolateToken = RootIsolateToken.instance!;
        await Isolate.run(() async {
          BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
          await extractFileToDisk(tar.path, cachePath);
          await tar.delete();
        });
      }

      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> downloadBaseDictionary({bool useLocal = false}) async {
    try {
      // Option to get asset locally
      if (useLocal) {
        // Get zip data
        final byteData =
            await rootBundle.load('assets/dictionary/base_dictionary.zip');

        // Copy zip to temporary directory file
        final bytes = byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
        final file = File(path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          constants.baseDictionaryZip,
        ));
        await file.writeAsBytes(bytes);

        return true;
      }

      _streamController?.close();
      _streamController = StreamController<double>();

      return _downloadFile(
        DownloadOptions.getBaseDictionaryUrl(),
        path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          constants.baseDictionaryZip,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> downloadMecabDictionary({bool useLocal = false}) async {
    try {
      // Option to get asset locally
      if (useLocal) {
        // Get zip data
        final byteData =
            await rootBundle.load('assets/mecab/mecab_dictionary.zip');

        // Copy zip to temporary directory file
        final bytes = byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);

        final file = File(path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          constants.mecabDictionaryZip,
        ));
        await file.writeAsBytes(bytes);

        return true;
      }

      _streamController?.close();
      _streamController = StreamController<double>();

      return _downloadFile(
        DownloadOptions.getMecabDictionaryUrl(),
        path.join(
          (await path_provider.getApplicationCacheDirectory()).path,
          constants.mecabDictionaryZip,
        ),
      );
    } catch (_) {
      return false;
    }
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

  Future<bool> hasSufficientFreeSpace() async {
    // Get free space in MB
    final freeSpace = await DiskSpacePlus.getFreeDiskSpace ?? 0;

    // If 0 return true
    // Can receive 0 (or null originally) if platform function fails
    // Download should be attempted and any possible error can caught later
    if (freeSpace == 0) return true;

    // Make sure there is at least 500 MB of free spaces
    return freeSpace > 500;
  }
}
