import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart';

class DigitalInkService {
  late final DigitalInkRecognizerModelManager _modelManager;
  late final DigitalInkRecognizer _digitalInkRecognizer;

  bool _ready = false;
  bool get ready => _ready;

  DigitalInkService(
    this._modelManager,
    this._digitalInkRecognizer,
    this._ready,
  );

  static Future<DigitalInkService> initialize() async {
    final DigitalInkRecognizerModelManager modelManager =
        DigitalInkRecognizerModelManager();
    final DigitalInkRecognizer digitalInkRecognizer =
        DigitalInkRecognizer(languageCode: 'ja');

    bool ready = await modelManager.isModelDownloaded('ja');

    return DigitalInkService(modelManager, digitalInkRecognizer, ready);
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
