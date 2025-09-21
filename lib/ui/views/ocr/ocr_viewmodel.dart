import 'package:image_picker/image_picker.dart';
import 'package:sagase/app/app.locator.dart';
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

  void handleTextSelected() {
    rebuildUi();
  }

  void analyzeText(String text) {
    if (text.isEmpty) return;

    _navigationService.back(result: text);
  }
}

enum OcrState {
  waiting,
  loading,
  viewing,
  viewEmpty,
  error,
}
