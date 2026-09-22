// test/core/sync/telemetry_csv_parser_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:detahub/core/sync/csv/telemetry_csv_parser.dart';

void main() {
  const parser = TelemetryCsvParser();

  group('TelemetryCsvParser', () {
    test('parses standard DetaLab CSV with header and CRLF line breaks', () {
      const csv =
          'Timestamp,Temperature(C),Humidity(%),eCO2(ppm),TVOC(ppb),AQI\r\n'
          '2026-09-21T10:00:00Z,24.5,58.2,450,120,1\r\n'
          '2026-09-21T10:01:00Z,24.6,58.0,455,125,2\r\n';

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

      final r2 = result.validRecords[1];
      expect(r2.timestamp, DateTime.utc(2026, 9, 21, 10, 1));
      expect(r2.temperature, 24.6);
      expect(r2.aqi, 2);
    });

    test('preserves original timestamps without interpolation', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,24.0,50.0,400,100,1\n'
          '2026-09-21T10:05:00Z,24.2,50.1,410,105,1\n'; // 5-min gap

      final result = parser.parseString(csv);

      expect(result.validCount, 2);
      expect(result.validRecords[0].timestamp, DateTime.utc(2026, 9, 21, 10, 0));
      expect(result.validRecords[1].timestamp, DateTime.utc(2026, 9, 21, 10, 5));
    });

    test('tolerates epoch timestamps in seconds and milliseconds', () {
      const csv =
          'Time,Temp,Hum,CO2,VOC,AQI\n'
          '1774137600,25.0,55.0,420,110,1\n' // 2026-03-22T00:00:00Z
          '1774137660000,25.1,55.2,425,115,1\n'; // +60s

      final result = parser.parseString(csv);

      expect(result.validCount, 2);
      expect(result.validRecords[0].timestamp.year, 2026);
      expect(result.validRecords[1].timestamp.year, 2026);
    });

    test('rejects malformed row without failing remaining valid rows', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-21T10:00:00Z,24.0,50.0,400,100,1\n'
          'corrupted-time,24.5,50.0,400,100,1\n' // malformed timestamp
          '2026-09-21T10:02:00Z,NaN,50.0,400,100,1\n' // NaN temperature
          '2026-09-21T10:03:00Z,24.2,50.1,410,105,1\n'; // valid

      final result = parser.parseString(csv);

      expect(result.totalRowsRead, 4);
      expect(result.validCount, 2);
      expect(result.invalidCount, 2);
      expect(result.invalidRecords[0].validationError, contains('timestamp'));
      expect(result.invalidRecords[1].validationError, contains('NaN'));
      expect(result.validRecords[0].timestamp, DateTime.utc(2026, 9, 21, 10, 0));
      expect(result.validRecords[1].timestamp, DateTime.utc(2026, 9, 21, 10, 3));
    });

    test('ignores blank lines and handles missing optional sensor values gracefully', () {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '\n'
          '2026-09-21T10:00:00Z,24.0,-,null,,1\n'
          '   \n'
          '2026-09-21T10:01:00Z,24.5,55.0,400,100,1\n';

      final result = parser.parseString(csv);

      expect(result.validCount, 2);
      expect(result.validRecords[0].humidity, isNull);
      expect(result.validRecords[0].eco2, isNull);
      expect(result.validRecords[0].tvoc, isNull);
      expect(result.validRecords[0].aqi, 1);
    });

    test('chunkList correctly slices records into bounded chunks', () {
      final items = List.generate(1440, (i) => i);
      final chunks = TelemetryCsvParser.chunkList(items, 500);

      expect(chunks.length, 3);
      expect(chunks[0].length, 500);
      expect(chunks[1].length, 500);
      expect(chunks[2].length, 440);
    });
  });
}
