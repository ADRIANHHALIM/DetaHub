// test/core/network/device_manifest_test.dart
//
// Tests for DeviceManifest JSON deserialization and validation.

import 'package:flutter_test/flutter_test.dart';
import 'package:detahub/core/network/models/device_manifest.dart';

void main() {
  group('DeviceManifest', () {
    test('parses valid manifest correctly', () {
      final json = {
        'device_id': 'lat-esp32h2-01',
        'product_type': 'LAT',
        'firmware_version': '1.0.4',
        'metrics': ['aqi', 'tvoc_ppb', 'eco2_ppm', 'temp_c', 'humidity_pct'],
        'uptime': 3600,
      };

      final manifest = DeviceManifest.fromJson(json);

      expect(manifest.deviceId, 'lat-esp32h2-01');
      expect(manifest.productType, 'LAT');
      expect(manifest.firmwareVersion, '1.0.4');
      expect(manifest.metrics, [
        'aqi',
        'tvoc_ppb',
        'eco2_ppm',
        'temp_c',
        'humidity_pct',
      ]);
      expect(manifest.uptime, 3600);
    });

    test('uses defaults for optional fields', () {
      final json = {
        'device_id': 'lat-02',
        'product_type': 'LAT',
      };

      final manifest = DeviceManifest.fromJson(json);

      expect(manifest.deviceId, 'lat-02');
      expect(manifest.productType, 'LAT');
      expect(manifest.firmwareVersion, 'unknown');
      expect(manifest.metrics, isEmpty);
      expect(manifest.uptime, isNull);
    });

    test('throws FormatException if device_id is missing', () {
      final json = {
        'product_type': 'LAT',
      };

      expect(
        () => DeviceManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException if product_type is missing', () {
      final json = {
        'device_id': 'lat-01',
      };

      expect(
        () => DeviceManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
