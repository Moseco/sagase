import 'package:kana_kit/kana_kit.dart';
import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/ui/views/practice/practice_viewmodel.dart';

class KanaPracticeViewModel extends PracticeViewModel<Kana> {
  final _kanaKit = const KanaKit();

  late Set<KanaScript> _scripts;
  late Set<KanaType> _types;

  late bool _typingEnabled;
  bool get typingEnabled => _typingEnabled;

  List<Kana> get allFlashcards => allItems;
  List<Kana> get activeFlashcards => activeItems;

  KanaPracticeViewModel({super.randomSeed}) {
    _scripts = sharedPreferencesService.getKanaPracticeScripts();
    _types = sharedPreferencesService.getKanaPracticeTypes();
    _typingEnabled = sharedPreferencesService.getKanaPracticeTypingEnabled();
    startSession();
  }

  @override
  List<Kana> createItems() => Kana.getKana(scripts: _scripts, types: _types);

  @override
  String get finishedDescription =>
      'You have completed all kana. Would you like to restart?';

  void toggleTypingEnabled() {
    _typingEnabled = !_typingEnabled;
    sharedPreferencesService.setKanaPracticeTypingEnabled(_typingEnabled);
    resetAnswerState();
    notifyListeners();
  }

  @override
  bool isCorrectAnswer(Kana item, String answer) {
    answer = answer.trim().toLowerCase();
    if (answer.isEmpty) return false;
    if (answer == item.romaji) return true;
    return _kanaKit.toHiragana(answer) == _kanaKit.toHiragana(item.kana);
  }

  Future<void> answerFlashcard(KanaPracticeAnswer answer) =>
      answerItem(answer == KanaPracticeAnswer.correct);

  Future<bool> editSelection() async {
    final response = await dialogService.showCustomDialog(
      variant: DialogType.kanaPracticeSelection,
      data: (_scripts, _types),
      barrierDismissible: true,
    );

    if (response?.data == null) return false;

    final (Set<KanaScript> scripts, Set<KanaType> types) = response!.data;
    if (scripts.isEmpty || types.isEmpty) return false;

    _scripts = scripts;
    _types = types;
    sharedPreferencesService.setKanaPracticeScripts(scripts);
    sharedPreferencesService.setKanaPracticeTypes(types);

    startSession();

    return true;
  }
}

enum KanaPracticeAnswer {
  wrong,
  correct,
}
