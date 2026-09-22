// test/core/network/device_file_test.dart
//
// Regression tests for DeviceFile deletion safety and filename normalization (Group A).

import 'package:flutter_test/flutter_test.dart';
import 'package:detahub/core/network/models/device_file.dart';

void main() {
  final refDate = DateTime.utc(2026, 9, 22);

  group('Group A: DeviceFile Deletion Safety & Normalization', () {
    test('1. historical dated CSV can be eligible', () {
      const file = DeviceFile(name: 'data_2026-09-20.csv');
      expect(file.isEligibleForDeletion(referenceTime: refDate), isTrue);
    });

    test("2. today's CSV cannot be deleted", () {
      const todayFile = DeviceFile(name: 'data_2026-09-22.csv');
      expect(todayFile.isEligibleForDeletion(referenceTime: refDate), isFalse);

      const futureFile = DeviceFile(name: 'data_2026-09-23.csv');
      expect(futureFile.isEligibleForDeletion(referenceTime: refDate), isFalse);
    });

    test('3. undated CSV cannot be deleted', () {
      const logFile = DeviceFile(name: 'log.csv');
      expect(logFile.isEligibleForDeletion(referenceTime: refDate), isFalse);

      const backupFile = DeviceFile(name: 'backup.csv');
      expect(backupFile.isEligibleForDeletion(referenceTime: refDate), isFalse);

      const unknownFile = DeviceFile(name: 'unknown');
      expect(unknownFile.isEligibleForDeletion(referenceTime: refDate), isFalse);
    });

    test('4. malformed date cannot be deleted', () {
      const malformed1 = DeviceFile(name: 'data_2026-99-99.csv');
      expect(malformed1.isEligibleForDeletion(referenceTime: refDate), isFalse);

      const malformed2 = DeviceFile(name: 'data_2026-02-31.csv');
      expect(malformed2.isEligibleForDeletion(referenceTime: refDate), isFalse);

      const malformed3 = DeviceFile(name: 'malformed-date.csv');
      expect(malformed3.isEligibleForDeletion(referenceTime: refDate), isFalse);
    });

    test('5. activeFileName prevents deletion', () {
      const file = DeviceFile(name: 'data_2026-09-20.csv');
      expect(
        file.isEligibleForDeletion(
          activeFileName: 'data_2026-09-20.csv',
          referenceTime: refDate,
        ),
        isFalse,
      );

      // Even with leading slash or different casing
      expect(
        file.isEligibleForDeletion(
          activeFileName: '/DATA_2026-09-20.CSV',
          referenceTime: refDate,
        ),
        isFalse,
      );
    });

    test('6. "/data_2026-09-21.csv" matches "data_2026-09-21.csv"', () {
      final normWithSlash = DeviceFile.normalizeFileName('/data_2026-09-21.csv');
      final normPlain = DeviceFile.normalizeFileName('data_2026-09-21.csv');
      expect(normWithSlash, equals(normPlain));
      expect(normWithSlash, 'data_2026-09-21.csv');
    });

    test('7. case and whitespace normalization', () {
      final normalized = DeviceFile.normalizeFileName('  DATA_2026-09-21.CSV  ');
      expect(normalized, 'data_2026-09-21.csv');

      final leadingSlashes = DeviceFile.normalizeFileName('///data_2026-09-21.csv');
      expect(leadingSlashes, 'data_2026-09-21.csv');
    });
  });
}
