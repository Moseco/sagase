import 'package:stacked/stacked.dart';

class KanaViewModel extends BaseViewModel {
  bool showHiragana = true;

  void toggleKana() {
    showHiragana = !showHiragana;
    notifyListeners();
  }
}
