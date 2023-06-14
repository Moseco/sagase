import 'package:flutter_test/flutter_test.dart';
import 'package:sagase/services/mecab_service.dart';

void main() {
  group('MecabServiceTest', () {
    final service = MecabService();

    test('createRubyTextPairs', () {
      var pairs = service.createRubyTextPairs('周り', 'まわり');
      expect(pairs.length, 2);
      expect(pairs[0].writing, '周');
      expect(pairs[0].reading, 'まわ');
      expect(pairs[1].writing, 'り');

      pairs = service.createRubyTextPairs('川', 'かわ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '川');
      expect(pairs[0].reading, 'かわ');

      pairs = service.createRubyTextPairs('ありがとう', 'ありがとう');
      expect(pairs.length, 1);
      expect(pairs[0].writing, 'ありがとう');

      pairs = service.createRubyTextPairs('コーヒー', 'コーヒー');
      expect(pairs.length, 1);
      expect(pairs[0].writing, 'コーヒー');

      pairs = service.createRubyTextPairs('仕返し', 'しかえし');
      expect(pairs.length, 2);
      expect(pairs[0].writing, '仕返');
      expect(pairs[0].reading, 'しかえ');
      expect(pairs[1].writing, 'し');

      pairs = service.createRubyTextPairs('我々', 'われわれ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '我々');
      expect(pairs[0].reading, 'われわれ');

      pairs = service.createRubyTextPairs('我われ', 'われわれ');
      expect(pairs.length, 2);
      expect(pairs[0].writing, '我');
      expect(pairs[0].reading, 'われ');
      expect(pairs[1].writing, 'われ');

      pairs = service.createRubyTextPairs('ジェット機', 'ジェットき');
      expect(pairs.length, 2);
      expect(pairs[0].writing, 'ジェット');
      expect(pairs[1].writing, '機');
      expect(pairs[1].reading, 'き');

      pairs = service.createRubyTextPairs('買い物', 'かいもの');
      expect(pairs.length, 3);
      expect(pairs[0].writing, '買');
      expect(pairs[0].reading, 'か');
      expect(pairs[1].writing, 'い');
      expect(pairs[2].writing, '物');
      expect(pairs[2].reading, 'もの');

      pairs = service.createRubyTextPairs('お金', 'おかね');
      expect(pairs.length, 2);
      expect(pairs[0].writing, 'お');
      expect(pairs[1].writing, '金');
      expect(pairs[1].reading, 'かね');

      pairs = service.createRubyTextPairs('お父さん', 'おとうさん');
      expect(pairs.length, 3);
      expect(pairs[0].writing, 'お');
      expect(pairs[1].writing, '父');
      expect(pairs[1].reading, 'とう');
      expect(pairs[2].writing, 'さん');

      pairs = service.createRubyTextPairs('立ち上がる', 'たちあがる');
      expect(pairs.length, 4);
      expect(pairs[0].writing, '立');
      expect(pairs[0].reading, 'た');
      expect(pairs[1].writing, 'ち');
      expect(pairs[2].writing, '上');
      expect(pairs[2].reading, 'あ');
      expect(pairs[3].writing, 'がる');

      pairs = service.createRubyTextPairs('ドン引き', 'どんびき');
      expect(pairs.length, 3);
      expect(pairs[0].writing, 'ドン');
      expect(pairs[1].writing, '引');
      expect(pairs[1].reading, 'び');
      expect(pairs[2].writing, 'き');
    });

    test('createRubyTextPairs katakana reading', () {
      var pairs = service.createRubyTextPairs('周り', 'マワリ');
      expect(pairs.length, 2);
      expect(pairs[0].writing, '周');
      expect(pairs[0].reading, 'まわ');
      expect(pairs[1].writing, 'り');

      pairs = service.createRubyTextPairs('川', 'カワ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '川');
      expect(pairs[0].reading, 'かわ');

      pairs = service.createRubyTextPairs('ありがとう', 'アリガトウ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, 'ありがとう');

      pairs = service.createRubyTextPairs('コーヒー', 'コーヒー');
      expect(pairs.length, 1);
      expect(pairs[0].writing, 'コーヒー');

      pairs = service.createRubyTextPairs('仕返し', 'シカエシ');
      expect(pairs.length, 2);
      expect(pairs[0].writing, '仕返');
      expect(pairs[0].reading, 'しかえ');
      expect(pairs[1].writing, 'し');

      pairs = service.createRubyTextPairs('我々', 'ワレワレ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '我々');
      expect(pairs[0].reading, 'われわれ');

      pairs = service.createRubyTextPairs('我われ', 'ワレワレ');
      expect(pairs.length, 2);
      expect(pairs[0].writing, '我');
      expect(pairs[0].reading, 'われ');
      expect(pairs[1].writing, 'われ');

      pairs = service.createRubyTextPairs('ジェット機', 'ジェットキ');
      expect(pairs.length, 2);
      expect(pairs[0].writing, 'ジェット');
      expect(pairs[1].writing, '機');
      expect(pairs[1].reading, 'き');

      pairs = service.createRubyTextPairs('買い物', 'カイモノ');
      expect(pairs.length, 3);
      expect(pairs[0].writing, '買');
      expect(pairs[0].reading, 'か');
      expect(pairs[1].writing, 'い');
      expect(pairs[2].writing, '物');
      expect(pairs[2].reading, 'もの');

      pairs = service.createRubyTextPairs('お金', 'オカネ');
      expect(pairs.length, 2);
      expect(pairs[0].writing, 'お');
      expect(pairs[1].writing, '金');
      expect(pairs[1].reading, 'かね');

      pairs = service.createRubyTextPairs('お父さん', 'オトウサン');
      expect(pairs.length, 3);
      expect(pairs[0].writing, 'お');
      expect(pairs[1].writing, '父');
      expect(pairs[1].reading, 'とう');
      expect(pairs[2].writing, 'さん');

      pairs = service.createRubyTextPairs('立ち上がる', 'タチアガル');
      expect(pairs.length, 4);
      expect(pairs[0].writing, '立');
      expect(pairs[0].reading, 'た');
      expect(pairs[1].writing, 'ち');
      expect(pairs[2].writing, '上');
      expect(pairs[2].reading, 'あ');
      expect(pairs[3].writing, 'がる');

      pairs = service.createRubyTextPairs('ドン引き', 'ドンビキ');
      expect(pairs.length, 3);
      expect(pairs[0].writing, 'ドン');
      expect(pairs[1].writing, '引');
      expect(pairs[1].reading, 'び');
      expect(pairs[2].writing, 'き');
    });

    test('createRubyTextPairs mismatched writing and reading', () {
      var pairs = service.createRubyTextPairs('周り', 'まわた');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '周り');
      expect(pairs[0].reading, 'まわた');
      pairs = service.createRubyTextPairs('周り', 'マワタ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '周り');
      expect(pairs[0].reading, 'まわた');

      pairs = service.createRubyTextPairs('周り', 'まわりた');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '周り');
      expect(pairs[0].reading, 'まわりた');
      pairs = service.createRubyTextPairs('周り', 'マワリタ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '周り');
      expect(pairs[0].reading, 'まわりた');

      pairs = service.createRubyTextPairs('周りた', 'まわり');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '周りた');
      expect(pairs[0].reading, 'まわり');
      pairs = service.createRubyTextPairs('周りた', 'マワリ');
      expect(pairs.length, 1);
      expect(pairs[0].writing, '周りた');
      expect(pairs[0].reading, 'まわり');
    });
  });
}
