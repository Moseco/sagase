import 'package:shared_preferences/shared_preferences.dart';
import 'package:sagase/utils/constants.dart' as constants;

class SharedPreferencesService {
  final SharedPreferences _sharedPreferences;

  SharedPreferencesService(this._sharedPreferences);

  static Future<SharedPreferencesService> initialize() async {
    return SharedPreferencesService(await SharedPreferences.getInstance());
  }

  int getInitialCorrectInterval() {
    return _sharedPreferences.getInt(constants.keyInitialCorrectInterval) ?? 1;
  }

  Future<void> setInitialCorrectInterval(int value) async {
    await _sharedPreferences.setInt(
      constants.keyInitialCorrectInterval,
      value,
    );
  }

  int getInitialVeryCorrectInterval() {
    return _sharedPreferences.getInt(constants.keyInitialVeryCorrectInterval) ??
        4;
  }

  Future<void> setInitialVeryCorrectInterval(int value) async {
    await _sharedPreferences.setInt(
      constants.keyInitialVeryCorrectInterval,
      value,
    );
  }

  bool getShowNewInterval() {
    return _sharedPreferences.getBool(constants.keyShowNewInterval) ?? false;
  }

  Future<void> setShowNewInterval(bool value) async {
    await _sharedPreferences.setBool(constants.keyShowNewInterval, value);
  }
}
