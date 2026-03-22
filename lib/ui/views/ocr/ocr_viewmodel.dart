import 'package:image_picker/image_picker.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:sagase/datamodels/recognized_text_block.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class OcrViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final ImagePicker _imagePicker = ImagePicker();

  OcrState _state = OcrState.waiting;
  OcrState get state => _state;

  XFile? _image;
  XFile? get image => _image;

  late List<(String, RecognizedTextBlock?)> _history;
  late int _historyIndex;
  bool get canUndo => _historyIndex >= 0;
  bool get canRedo => _historyIndex < _history.length - 1;

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
    _history = [];
    _historyIndex = -1;
    _image = null;
    _state = OcrState.waiting;
    rebuildUi();

    try {
      _image = await _imagePicker.pickImage(source: imageSource);
    } catch (_) {
      _snackbarService.showSnackbar(
        message: 'Failed to open camera or gallery',
      );
    }

    if (image == null) {
      _navigationService.back();
      return;
    }

    _state = OcrState.loading;

    rebuildUi();
  }

  void handleImageProcessed(int length) {
    if (length == 0) {
      _state = OcrState.viewEmpty;
    } else {
      _state = OcrState.viewing;
    }
    rebuildUi();
  }

  void handleImageError() {
    _image = null;
    _state = OcrState.error;
    rebuildUi();
  }

  void analyzeText(String text) {
    if (text.isEmpty) return;

    _navigationService.back(result: text);
  }

  void appendToHistory(String text, [RecognizedTextBlock? block]) {
    _historyIndex++;

    if (_historyIndex != _history.length) {
      _history = _history.sublist(0, _historyIndex);
    }

    _history.add((text, block));

    rebuildUi();
  }

  String undo() {
    if (!canUndo) return '';

    _history[_historyIndex].$2?.selected = false;

    _historyIndex--;
    rebuildUi();

    if (_historyIndex == -1) {
      return '';
    } else {
      return _history[_historyIndex].$1;
    }
  }

  String redo() {
    if (!canRedo) return '';

    _historyIndex++;
    _history[_historyIndex].$2?.selected = true;

    rebuildUi();

    return _history[_historyIndex].$1;
  }
}

enum OcrState {
  waiting,
  loading,
  viewing,
  viewEmpty,
  error,
}
