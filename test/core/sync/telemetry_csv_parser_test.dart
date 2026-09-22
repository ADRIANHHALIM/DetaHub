// test/core/sync/telemetry_csv_parser_test.dart
//
// Regression tests for TelemetryCsvParser (Group B).

import 'package:flutter_test/flutter_test.dart';
import 'package:detahub/core/sync/csv/telemetry_csv_parser.dart';

void main() {
  const parser = TelemetryCsvParser();

  group('Group B: CSV Parser Regression Tests (8-18)', () {
    test('8. standard valid CSV', () {
      const csv =
          'Timestamp,Temperature(C),Humidity(%),eCO2(ppm),TVOC(ppb),AQI\n'
          '2026-09-21T10:00:00Z,24.5,58.2,450,120,1\n'
          '2026-09-21T10:01:00Z,24.6,58.0,455,125,2\n';

      final result = parser.parseString(csv);

      expect(result.totalRowsRead, 2);
      expect(result.validCount, 2);
      expect(result.invalidCount, 0);

      final r1 = result.validRecords[0];
      expect(r1.timestamp, DateTime.utc(2026, 9, 21, 10, 0));
      expect(r1.temperature, 24.5);
      expect(r1.humidity, 58.2);
      expect(r1.eco2, 450);
      expect(r1.tvoc, 120);
      expect(r1.aqi, 1);
    });

    test('9. CRLF line endings', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\r\n'
          '2026-09-21T10:00:00Z,24.5,58.2,450,120,1\r\n'
          '2026-09-21T10:01:00Z,24.6,58.0,455,125,2\r\n';

      final result = parser.parseString(csv);

      expect(result.totalRowsRead, 2);
      expect(result.validCount, 2);
      expect(result.invalidCount, 0);
    });

    test('10. LF line endings', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,24.5,58.2,450,120,1\n'
          '2026-09-21T10:01:00Z,24.6,58.0,455,125,2\n';

      final result = parser.parseString(csv);

      expect(result.totalRowsRead, 2);
      expect(result.validCount, 2);
      expect(result.invalidCount, 0);
    });

    test('11. malformed row is caught as invalid without dropping valid rows', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,24.0,50.0,400,100,1\n'
          'incomplete-row-corrupted\n'
          '2026-09-21T10:02:00Z,24.2,50.1,410,105,1\n';

      final result = parser.parseString(csv);

      expect(result.totalRowsRead, 3);
      expect(result.validCount, 2);
      expect(result.invalidCount, 1);
      expect(result.invalidRecords[0].isValid, isFalse);
    });

    test('12. invalid timestamp is rejected', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          'not-a-timestamp,24.0,50.0,400,100,1\n'
          '1999-01-01T00:00:00Z,24.0,50.0,400,100,1\n' // pre-2020 unsynced NTP
          '2026-09-21T10:00:00Z,24.0,50.0,400,100,1\n';

      final result = parser.parseString(csv);

      expect(result.totalRowsRead, 3);
      expect(result.validCount, 1);
      expect(result.invalidCount, 2);
    });

    test('13. invalid numeric values handled safely', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,abc,50.0,400,100,1\n' // invalid temp -> null double
          '2026-09-21T10:01:00Z,24.0,xyz,400,100,1\n'; // invalid hum -> null double

      final result = parser.parseString(csv);

      expect(result.validCount, 2);
      expect(result.validRecords[0].temperature, isNull);
      expect(result.validRecords[1].humidity, isNull);
    });

    test('14. NaN numeric is rejected as invalid record', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,NaN,50.0,400,100,1\n'
          '2026-09-21T10:01:00Z,24.0,NaN,400,100,1\n';

      final result = parser.parseString(csv);

      expect(result.validCount, 0);
      expect(result.invalidCount, 2);
      expect(result.invalidRecords[0].validationError, contains('NaN'));
    });

    test('15. Infinity numeric is rejected as invalid record', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,Infinity,50.0,400,100,1\n'
          '2026-09-21T10:01:00Z,24.0,-Infinity,400,100,1\n';

      final result = parser.parseString(csv);

      expect(result.validCount, 0);
      expect(result.invalidCount, 2);
      expect(result.invalidRecords[0].validationError, contains('Infinite'));
    });

    test('16. empty CSV produces clean empty result', () {
      final r1 = parser.parseString('');
      expect(r1.validCount, 0);
      expect(r1.invalidCount, 0);
      expect(r1.totalRowsRead, 0);

      final r2 = parser.parseString('   \n\r\n   ');
      expect(r2.validCount, 0);
      expect(r2.invalidCount, 0);
      expect(r2.totalRowsRead, 0);
    });

    test('17. timestamp preservation (wall clock without timezone preserved as UTC)', () {
      // Timezone-less ESP32 wall clock: 2026-09-21 14:30:00
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21 14:30:00,24.0,50.0,400,100,1\n';

      final result = parser.parseString(csv);

      expect(result.validCount, 1);
      final ts = result.validRecords[0].timestamp;
      // Must NOT be shifted by phone timezone offset (must stay 14:30:00)
      expect(ts.year, 2026);
      expect(ts.month, 9);
      expect(ts.day, 21);
      expect(ts.hour, 14);
      expect(ts.minute, 30);
      expect(ts.second, 0);
    });

    test('18. flexible header mapping across different column namings', () {
      const csv =
          'Date,Temp,Hum,CO2,VOC,AQI\n'
          '2026-09-21T10:00:00Z,25.3,55.1,430,115,1\n';

      final result = parser.parseString(csv);

      expect(result.validCount, 1);
      final r = result.validRecords[0];
      expect(r.temperature, 25.3);
      expect(r.humidity, 55.1);
      expect(r.eco2, 430);
      expect(r.tvoc, 115);
      expect(r.aqi, 1);
    });
  });
}
