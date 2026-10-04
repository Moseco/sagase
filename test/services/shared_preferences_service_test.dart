import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/kana.dart';
import 'package:sagase/services/shared_preferences_service.dart';
import 'package:sagase/utils/constants.dart' as constants;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesServiceTest', () {
    Future<SharedPreferencesService> createService([
      Map<String, Object> values = const {},
    ]) async {
      SharedPreferences.setMockInitialValues(values);
      final service = SharedPreferencesService();
      await service.init();
      return service;
    }

    group('Kana practice', () {
      test('Defaults', () async {
        final service = await createService();

        expect(service.getKanaPracticeScripts(), {KanaScript.hiragana});
        expect(service.getKanaPracticeTypes(), {KanaType.basic});
        expect(service.getKanaPracticeTypingEnabled(), false);
      });

      test('Set and get', () async {
        final service = await createService();

        await service.setKanaPracticeScripts(
          {KanaScript.hiragana, KanaScript.katakana},
        );
        await service.setKanaPracticeTypes(
          {KanaType.voiced, KanaType.combination},
        );
        await service.setKanaPracticeTypingEnabled(true);

        expect(
          service.getKanaPracticeScripts(),
          {KanaScript.hiragana, KanaScript.katakana},
        );
        expect(
          service.getKanaPracticeTypes(),
          {KanaType.voiced, KanaType.combination},
        );
        expect(service.getKanaPracticeTypingEnabled(), true);

        // Stored by name so reordering the enums does not change the selection
        final sharedPreferences = await SharedPreferences.getInstance();
        expect(
          sharedPreferences.getStringList(constants.keyKanaPracticeScripts),
          unorderedEquals(['hiragana', 'katakana']),
        );
        expect(
          sharedPreferences.getStringList(constants.keyKanaPracticeTypes),
          unorderedEquals(['voiced', 'combination']),
        );
      });

      test('Unknown values are ignored', () async {
        final service = await createService({
          constants.keyKanaPracticeScripts: ['katakana', 'romaji'],
          constants.keyKanaPracticeTypes: ['semiVoiced', 'obsolete'],
        });

        expect(service.getKanaPracticeScripts(), {KanaScript.katakana});
        expect(service.getKanaPracticeTypes(), {KanaType.semiVoiced});
      });

      test('Empty or invalid selection falls back to default', () async {
        final service = await createService({
          constants.keyKanaPracticeScripts: <String>[],
          constants.keyKanaPracticeTypes: ['obsolete'],
        });

        expect(service.getKanaPracticeScripts(), {KanaScript.hiragana});
        expect(service.getKanaPracticeTypes(), {KanaType.basic});

        await service.setKanaPracticeScripts({});
        await service.setKanaPracticeTypes({});

        expect(service.getKanaPracticeScripts(), {KanaScript.hiragana});
        expect(service.getKanaPracticeTypes(), {KanaType.basic});
      });
    });
  });
}
