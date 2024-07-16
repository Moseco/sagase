import 'dart:convert';

import 'package:sagase/datamodels/isar/spaced_repetition_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpacedRepetitionDataTest', () {
    test('copyWithInitialCorrectCount', () {
      var data = SpacedRepetitionData();
      expect(data.interval, 0);
      expect(data.repetitions, 0);
      expect(data.easeFactor, 2.5);
      expect(data.dueDate, null);
      expect(data.totalAnswers, 0);
      expect(data.totalWrongAnswers, 0);
      expect(data.initialCorrectCount, 0);

      data = data.copyWithInitialCorrectCount(1);
      expect(data.interval, 0);
      expect(data.repetitions, 0);
      expect(data.easeFactor, 2.5);
      expect(data.dueDate, null);
      expect(data.totalAnswers, 0);
      expect(data.totalWrongAnswers, 0);
      expect(data.initialCorrectCount, 1);

      data = data.copyWithInitialCorrectCount(-1);
      expect(data.initialCorrectCount, 0);
      data = data.copyWithInitialCorrectCount(-1);
      expect(data.initialCorrectCount, 0);
      data = data.copyWithInitialCorrectCount(1);
      data = data.copyWithInitialCorrectCount(1);
      expect(data.initialCorrectCount, 2);
    });

    test('toBackupJson and fromBackupJson', () {
      final data = SpacedRepetitionData()
        ..interval = 1
        ..repetitions = 2
        ..easeFactor = 3
        ..dueDate = 2022
        ..totalAnswers = 5
        ..totalWrongAnswers = 4;

      // Backup and import
      final newData =
          SpacedRepetitionData.fromBackupJson(jsonDecode(data.toBackupJson()));

      expect(newData.interval, 1);
      expect(newData.repetitions, 2);
      expect(newData.easeFactor, 3);
      expect(newData.dueDate, 2022);
      expect(newData.totalAnswers, 5);
      expect(newData.totalWrongAnswers, 4);
    });
  });
}
