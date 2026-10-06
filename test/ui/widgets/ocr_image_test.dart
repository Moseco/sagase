import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sagase/ui/widgets/ocr_image.dart';
import 'package:sagase/utils/constants.dart' as constants;

import '../../helpers/fake_path_provider_platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const exifRotationChannel = MethodChannel('flutter_exif_rotation');
  const textRecognizerChannel = MethodChannel('google_mlkit_text_recognizer');
  // 1x1 png
  const imageBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

  late Directory tempDir;
  late List<String> textRecognizerCalls;
  late Future<Object?> Function() recognizeText;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp();
    PathProviderPlatform.instance = FakePathProviderPlatform(tempDir.path);

    textRecognizerCalls = [];
    recognizeText = () async => {'text': '', 'blocks': []};

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Rotation overwrites the original file
    messenger.setMockMethodCallHandler(
      exifRotationChannel,
      (call) async => call.arguments['path'],
    );
    messenger.setMockMethodCallHandler(textRecognizerChannel, (call) async {
      textRecognizerCalls.add(call.method);
      if (call.method == 'vision#startTextRecognizer') return recognizeText();
      return null;
    });
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(exifRotationChannel, null);
    messenger.setMockMethodCallHandler(textRecognizerChannel, null);
    await tempDir.delete(recursive: true);
  });

  Future<XFile> createImage() async {
    final file = File(path.join(tempDir.path, 'image.png'));
    await file.writeAsBytes(base64Decode(imageBase64));
    return XFile(file.path);
  }

  bool imageFilesDeleted() {
    final ocrImagesDir = Directory(
      path.join(tempDir.path, 'applicationCache', constants.ocrImagesDir),
    );
    return !File(path.join(tempDir.path, 'image.png')).existsSync() &&
        (!ocrImagesDir.existsSync() || ocrImagesDir.listSync().isEmpty);
  }

  // File IO and image decoding need real time to pass, and the widget handles
  // their results when the test pumps
  Future<void> waitFor(WidgetTester tester, bool Function() condition) async {
    for (int i = 0; i < 200 && !condition(); i++) {
      await tester.runAsync(
        () => Future.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
  }

  Widget buildOcrImage(
    XFile image, {
    void Function(int)? onImageProcessed,
    void Function()? onImageError,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: OcrImage(
          image: image,
          onImageProcessed: onImageProcessed,
          onImageError: onImageError ?? () {},
          locked: true,
          singleSelection: true,
        ),
      ),
    );
  }

  testWidgets('Image is processed and the recognizer is closed when removed',
      (tester) async {
    int? textBlockCount;
    bool imageError = false;

    await tester.pumpWidget(buildOcrImage(
      (await tester.runAsync(createImage))!,
      onImageProcessed: (count) => textBlockCount = count,
      onImageError: () => imageError = true,
    ));
    await waitFor(tester, () => textBlockCount != null && imageFilesDeleted());

    expect(textBlockCount, 0);
    expect(imageError, false);
    expect(imageFilesDeleted(), true);
    expect(textRecognizerCalls, ['vision#startTextRecognizer']);

    await tester.pumpWidget(const SizedBox());

    expect(textRecognizerCalls, [
      'vision#startTextRecognizer',
      'vision#closeTextRecognizer',
    ]);
  });

  testWidgets('Text recognition error', (tester) async {
    recognizeText = () async => throw PlatformException(code: 'error');
    bool imageProcessed = false;
    bool imageError = false;

    await tester.pumpWidget(buildOcrImage(
      (await tester.runAsync(createImage))!,
      onImageProcessed: (_) => imageProcessed = true,
      onImageError: () => imageError = true,
    ));
    await waitFor(tester, () => imageError && imageFilesDeleted());

    expect(imageProcessed, false);
    expect(imageError, true);
    expect(imageFilesDeleted(), true);
  });

  testWidgets('Removed while recognizing text', (tester) async {
    final recognition = Completer<Object?>();
    recognizeText = () => recognition.future;
    bool imageProcessed = false;
    bool imageError = false;

    await tester.pumpWidget(buildOcrImage(
      (await tester.runAsync(createImage))!,
      onImageProcessed: (_) => imageProcessed = true,
      onImageError: () => imageError = true,
    ));
    await waitFor(
      tester,
      () => textRecognizerCalls.contains('vision#startTextRecognizer'),
    );

    await tester.pumpWidget(const SizedBox());
    recognition.complete({'text': '', 'blocks': []});
    await waitFor(tester, imageFilesDeleted);

    expect(imageProcessed, false);
    expect(imageError, false);
    expect(imageFilesDeleted(), true);
    expect(textRecognizerCalls, contains('vision#closeTextRecognizer'));
  });
}
