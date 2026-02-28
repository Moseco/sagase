import 'package:stacked/stacked.dart';
import 'package:sagase/datamodels/grammar_content.dart';
import 'package:sagase/utils/grammar_lesson_parser.dart';

class GrammarLessonViewModel extends BaseViewModel {
  final int grammarLessonId;

  GrammarLesson? _grammarLesson;

  GrammarLesson? get grammarLesson => _grammarLesson;

  GrammarLessonViewModel(this.grammarLessonId) {
    _loadGrammarLesson();
  }

  Future<void> _loadGrammarLesson() async {
    setBusy(true);
    try {
      final assetPath = 'assets/grammar/lessons/$grammarLessonId.json';
      _grammarLesson = await GrammarLessonParser.parseFromAsset(assetPath);
      notifyListeners();
    } catch (e) {
      print('Error loading grammar lesson: $e');
    } finally {
      setBusy(false);
    }
  }
}
