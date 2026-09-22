// lib/core/sync/csv/telemetry_csv_record.dart
//
// Intermediate validated domain record parsed from an ESP32 CSV row.

import 'package:drift/drift.dart';
import '../../database/app_database.dart';

/// One parsed and validated telemetry record from a hardware CSV row.
class TelemetryCsvRecord {
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;
  final int? eco2;
  final int? tvoc;
  final int? aqi;
  final int lineNumber;
  final bool isValid;
  final String? validationError;

  const TelemetryCsvRecord({
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.eco2,
    this.tvoc,
    this.aqi,
    required this.lineNumber,
    this.isValid = true,
    this.validationError,
  });

  /// Factory for an invalid row with error detail.
  factory TelemetryCsvRecord.invalid({
    required int lineNumber,
    required String reason,
    DateTime? fallbackTimestamp,
  }) {
    return TelemetryCsvRecord(
      timestamp: fallbackTimestamp ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      lineNumber: lineNumber,
      isValid: false,
      validationError: reason,
    );
  }

  /// Converts this record into a Drift companion ready for SQLite insertion.
  TelemetryRecordsCompanion toCompanion(String deviceId) {
    return TelemetryRecordsCompanion.insert(
      deviceId: deviceId,
      timestamp: timestamp,
      temperature: Value(temperature),
      humidity: Value(humidity),
      eco2: Value(eco2),
      tvoc: Value(tvoc),
      aqi: Value(aqi),
    );
  }

  @override
  String toString() =>
      'TelemetryCsvRecord(line: $lineNumber, time: $timestamp, temp: $temperature, hum: $humidity, '
      'eco2: $eco2, tvoc: $tvoc, aqi: $aqi, valid: $isValid${validationError != null ? ', err: $validationError' : ''})';
}
