import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/recognized_text_block.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class OcrViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final ImagePicker _imagePicker = ImagePicker();
  final _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);

  Uint8List? _currentImageBytes;
  Uint8List? get currentImageBytes => _currentImageBytes;
  Size? _imageSize;
  Size? get imageSize => _imageSize;

  List<RecognizedTextBlock>? _recognizedTextBlocks;
  List<RecognizedTextBlock>? get recognizedTextBlocks => _recognizedTextBlocks;

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
    _currentImageBytes = null;
    _recognizedTextBlocks = null;
    rebuildUi();

    XFile? image;

    try {
      image = await _imagePicker.pickImage(source: imageSource);
    } catch (_) {
      _snackbarService.showSnackbar(
        message: 'Failed to open camera or image picker',
      );
    }

    if (image == null) {
      _navigationService.back();
      return;
    }

    final inputImage = InputImage.fromFilePath(image.path);

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

    _recognizedTextBlocks = [];
    for (final textBlock in recognizedText.blocks) {
      _recognizedTextBlocks!.add(
        RecognizedTextBlock(
          text: textBlock.text,
          points: textBlock.cornerPoints,
        ),
      );
    }

    rebuildUi();
  }

  void reorderList(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    _recognizedTextBlocks!.insert(
      newIndex,
      _recognizedTextBlocks!.removeAt(oldIndex),
    );
    rebuildUi();
  }

  void toggleCheckBox(int index, bool value) {
    _recognizedTextBlocks![index].selected = value;
    rebuildUi();
  }

  void analyzeSelectedText() {
    if (_recognizedTextBlocks == null) return;
    if (_recognizedTextBlocks!.length == 1) {
      _navigationService.back(result: _recognizedTextBlocks![0].text);
      return;
    }

    List<String> lines = [];

    for (final textBlock in _recognizedTextBlocks!) {
      if (textBlock.selected) lines.add(textBlock.text);
    }

    if (lines.isEmpty) return;

    _navigationService.back(result: lines.join('\n'));
  }
}
