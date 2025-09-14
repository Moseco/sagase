import 'package:image_picker/image_picker.dart';
import 'package:sagase/app/app.locator.dart';
import 'package:stacked/stacked.dart';
import 'package:stacked_services/stacked_services.dart';

class OcrViewModel extends BaseViewModel {
  final _navigationService = locator<NavigationService>();
  final _snackbarService = locator<SnackbarService>();

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _image;
  XFile? get image => _image;

  List<String>? _selectedText;
  List<String>? get selectedText => _selectedText;

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
    _selectedText = null;
    rebuildUi();

    try {
      _image = await _imagePicker.pickImage(source: imageSource);
    } catch (_) {
      _snackbarService.showSnackbar(
        message: 'Failed to open camera or gallery',
      );
    }

    rebuildUi();
  }

  void handleImageProcessed() {
    _selectedText = [];
    rebuildUi();
  }

  void handleImageError() {
    _image = null;
    _snackbarService.showSnackbar(message: 'Failed to process image');
    rebuildUi();
  }

  void handleTextSelected(String text) {
    _selectedText?.add(text);
    rebuildUi();
  }

  void reorderList(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;

    _selectedText!.insert(
      newIndex,
      _selectedText!.removeAt(oldIndex),
    );
    rebuildUi();
  }

  void analyzeSelectedText() {
    if (_selectedText == null) return;
    if (_selectedText!.isEmpty) return;

    _navigationService.back(result: _selectedText!.join('\n'));
  }
}
