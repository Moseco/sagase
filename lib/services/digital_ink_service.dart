import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class DigitalInkService {
  final _modelManager = DigitalInkRecognizerModelManager();
  final _digitalInkRecognizer = DigitalInkRecognizer(languageCode: 'ja');

  bool _ready = false;
  bool get ready => _ready;

  Future<bool> initialize() async {
    _ready = await _modelManager.isModelDownloaded('ja');
    return _ready;
  }

  Future<bool> downloadModel() async {
    try {
      _ready = await _modelManager.downloadModel('ja', isWifiRequired: false);
    } catch (_) {
      _ready = false;
    }

    return _ready;
  }

  Future<List<String>> recognizeWriting(Ink ink) async {
    if (ink.strokes.isEmpty) return [];

    final List<RecognitionCandidate> candidates =
        await _digitalInkRecognizer.recognize(ink);

    List<String> result = [];
    for (final candidate in candidates) {
      result.add(candidate.text);
    }
    return result;
  }
}
