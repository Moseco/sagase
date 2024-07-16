import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/datamodels/isar/my_dictionary_list.dart';
import 'package:sagase_dictionary/sagase_dictionary.dart'
    show JapaneseTextHelpers;

void main() {
  group('MyDictionaryListTest', () {
    test('toBackupJson and fromBackupJson', () async {
      final now = DateTime.now();
      final myList = MyDictionaryList()
        ..id = 1
        ..name = 'list1'
        ..timestamp = now
        ..vocab = [0, 1]
        ..kanji = ['a'.kanjiCodePoint(), 'b'.kanjiCodePoint()];

      // Backup and import
      final newMyList = MyDictionaryList.fromBackupJson(myList.toBackupJson());

      expect(newMyList.id, 1);
      expect(newMyList.name, 'list1');
      expect(newMyList.timestamp.millisecondsSinceEpoch,
          now.millisecondsSinceEpoch);
      expect(newMyList.vocab.length, 2);
      expect(newMyList.vocab.contains(0), true);
      expect(newMyList.vocab.contains(1), true);
      expect(newMyList.kanji.length, 2);
      expect(newMyList.kanji.contains('a'.kanjiCodePoint()), true);
      expect(newMyList.kanji.contains('b'.kanjiCodePoint()), true);
    });

    test('toShareJson and fromShareJson', () {
      final myList = MyDictionaryList()
        ..id = 1
        ..name = 'list1'
        ..timestamp = DateTime.now()
        ..vocab = [0, 1]
        ..kanji = ['a'.kanjiCodePoint(), 'b'.kanjiCodePoint()];

      // Export and import
      final newMyList = MyDictionaryList.fromShareJson(myList.toShareJson());

      expect(newMyList!.name, 'list1');
      expect(newMyList.vocab, [0, 1]);
      expect(newMyList.kanji, ['a'.kanjiCodePoint(), 'b'.kanjiCodePoint()]);
    });

    test('fromShareJson with invalid input', () {
      String json = '{"name":"list1","vocab":[0,1],"kanji":[97,98]}';

      final myList = MyDictionaryList.fromShareJson(json);

      expect(myList, null);
    });
  });
}
