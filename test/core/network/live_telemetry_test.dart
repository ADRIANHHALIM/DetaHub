import 'package:detahub/core/network/models/device_manifest.dart';
import 'package:detahub/core/network/models/live_telemetry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LiveTelemetry', () {
    test('parses LAT field aliases without fabricating missing values', () {
      final telemetry = LiveTelemetry.fromJson({
        'temp': '25.4',
        'hum': 61,
        'eCO2': '525',
        'TVOC': 140,
        'AQI': 2,
        'ntp_time': '2026-09-21T20:15:00Z',
        'totalRecords': 42,
        'filename': 'data_2026-09-21.csv',
      });

      expect(telemetry.temperature, 25.4);
      expect(telemetry.humidity, 61);
      expect(telemetry.eco2, 525);
      expect(telemetry.tvoc, 140);
      expect(telemetry.aqi, 2);
      expect(telemetry.totalRecords, 42);
      expect(telemetry.fileName, 'data_2026-09-21.csv');
      expect(telemetry.hasHardwareTimestamp, isTrue);
      expect(telemetry.timestamp, DateTime.parse('2026-09-21T20:15:00Z'));
    });

    test('uses receipt time only when firmware omits timestamp', () {
      final receivedAt = DateTime.utc(2026, 9, 21, 20, 15);
      final telemetry = LiveTelemetry.fromJson(
        const {},
        receivedAt: receivedAt,
      );

      expect(telemetry.timestamp, receivedAt);
      expect(telemetry.hasHardwareTimestamp, isFalse);
      expect(telemetry.temperature, isNull);
      expect(telemetry.aqi, isNull);
    });

    test('rejects invalid supplied sensor values', () {
      expect(
        () => LiveTelemetry.fromJson(const {'temperature': 'warm'}),
        throwsFormatException,
      );
    });
  });

  test('manifest fallback derives a deterministic address identity', () {
    final telemetry = LiveTelemetry(
      timestamp: DateTime.utc(2026),
      hasHardwareTimestamp: true,
      temperature: 25,
    );

    final manifest = DeviceManifest.fromLiveTelemetry(
      telemetry,
      'http://192.168.4.1:80',
    );

    expect(manifest.deviceId, 'lat-192-168-4-1');
    expect(manifest.metrics, ['temperature']);
  });
}
