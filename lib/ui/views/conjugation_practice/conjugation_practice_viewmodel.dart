import 'package:sagase/app/app.dialogs.dart';
import 'package:sagase/datamodels/conjugation_practice.dart';
import 'package:sagase/ui/views/practice/practice_viewmodel.dart';
import 'package:sagase/utils/romaji_converter.dart';

class ConjugationPracticeViewModel
    extends PracticeViewModel<ConjugationPracticeQuestion> {
  static const questionsPerSession = 20;

  late Set<ConjugationPracticeWordType> _types;
  late Set<ConjugationPracticeForm> _forms;

  ConjugationPracticeViewModel({super.randomSeed}) {
    _types = sharedPreferencesService.getConjugationPracticeWordTypes();
    _forms = sharedPreferencesService.getConjugationPracticeForms();
    startSession();
  }

  @override
  List<ConjugationPracticeQuestion> createItems() =>
      ConjugationPracticeQuestion.getRandom(
        types: _types,
        forms: _forms,
        count: questionsPerSession,
        random: random,
      );

  @override
  String get finishedDescription =>
      'You have completed all conjugations. Would you like to restart with new words?';

  @override
  bool get showAnswerWhenCorrect => true;

  @override
  bool isCorrectAnswer(ConjugationPracticeQuestion item, String answer) {
    return item.isCorrect(romajiToHiragana(answer, finalize: true));
  }

  Future<bool> editSelection() async {
    final response = await dialogService.showCustomDialog(
      variant: DialogType.conjugationPracticeSelection,
      data: (_types, _forms),
      barrierDismissible: true,
    );

    if (response?.data == null) return false;

    final (
      Set<ConjugationPracticeWordType> types,
      Set<ConjugationPracticeForm> forms,
    ) = response!.data;
    if (types.isEmpty || forms.isEmpty) return false;

    _types = types;
    _forms = forms;
    sharedPreferencesService.setConjugationPracticeWordTypes(types);
    sharedPreferencesService.setConjugationPracticeForms(forms);

    startSession();

    return true;
  }
}
