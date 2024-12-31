import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/recognized_text_block.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class OcrViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();

  final ImagePicker _imagePicker = ImagePicker();
  final _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);

  bool _selectingImage = false;
  bool get selectingImage => _selectingImage;

  Uint8List? _currentImageBytes;
  Uint8List? get currentImageBytes => _currentImageBytes;
  Size? _imageSize;
  Size? get imageSize => _imageSize;

  List<RecognizedTextBlock>? recognizedTextBlocks;

  OcrViewModel(bool cameraStart) {
    if (cameraStart) {
      openCamera();
    } else {
      selectImage();
    }
  }

  void openCamera() {
    _processImage(ImageSource.camera);
  }

  void selectImage() {
    _processImage(ImageSource.gallery);
  }

  Future<void> _processImage(ImageSource imageSource) async {
    _selectingImage = true;
    recognizedTextBlocks = null;
    rebuildUi();

    XFile? image;

    try {
      image = await _imagePicker.pickImage(source: imageSource);
    } catch (_) {
      _selectingImage = false;
      rebuildUi();
      return;
    }

    _selectingImage = false;

    if (image == null) {
      rebuildUi();
      return;
    }

    InputImage inputImage = InputImage.fromFilePath(image.path);

    _currentImageBytes = await image.readAsBytes();
    rebuildUi();

    if (inputImage.metadata?.size != null) {
      _imageSize = inputImage.metadata!.size;
    } else {
      final decodedImage = await decodeImageFromList(currentImageBytes!);
      _imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
    }

    final recognizedText = await _textRecognizer.processImage(inputImage);

    recognizedTextBlocks = [];
    for (final textBlock in recognizedText.blocks) {
      recognizedTextBlocks!.add(
        RecognizedTextBlock(
          text: textBlock.text,
          points: textBlock.cornerPoints,
        ),
      );
    }

    rebuildUi();
  }

  void refresh() {
    rebuildUi();
  }

  void reorderList(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    recognizedTextBlocks!.insert(
      newIndex,
      recognizedTextBlocks!.removeAt(oldIndex),
    );
    rebuildUi();
  }

  void toggleCheckBox(int index, bool value) {
    recognizedTextBlocks![index].selected = value;
    rebuildUi();
  }

  void analyzeSelectedText() {
    if (recognizedTextBlocks == null) return;
    if (recognizedTextBlocks!.length == 1) {
      _navigationService.back(result: recognizedTextBlocks![0].text);
      return;
    }

    List<String> lines = [];

    for (final textBlock in recognizedTextBlocks!) {
      if (textBlock.selected) lines.add(textBlock.text);
    }

    if (lines.isEmpty) return;

    _navigationService.back(result: lines.join('\n'));
  }
}
