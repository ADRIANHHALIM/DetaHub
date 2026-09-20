// lib/core/database/tables/telemetry_records_table.dart
//
// High-volume time-series table storing every telemetry sample from IoT devices.
// Designed for:
//   - Bulk batch inserts (CSV sync: up to 1440 rows/device/day)
//   - Fast time-range queries for charting (indexed on timestamp)
//   - Zero-duplication via UNIQUE(device_id, timestamp) → ON CONFLICT IGNORE

import 'package:drift/drift.dart';

import 'devices_table.dart';

/// One telemetry sample from an IoT device.
///
/// Corresponds to a single row in the device's CSV log or a /api/live response.
/// AQI values follow the ENS160 standard (1 = Excellent → 5 = Unhealthy).
@TableIndex(name: 'idx_telemetry_timestamp', columns: {#timestamp})
@TableIndex(
  name: 'idx_telemetry_device_timestamp',
  columns: {#deviceId, #timestamp},
  unique: true, // Basis for ON CONFLICT IGNORE deduplication
)
class TelemetryRecords extends Table {
  /// Auto-incremented internal row ID.
  IntColumn get id => integer().autoIncrement()();

  /// FK → devices.id. Cascades DELETE so that removing a Device also removes
  /// all its historical telemetry data, keeping the DB lean.
  TextColumn get deviceId => text()
      .named('device_id')
      .references(Devices, #id, onDelete: KeyAction.cascade)();

  /// UTC timestamp of the sample. Combined with deviceId forms the unique key.
  DateTimeColumn get timestamp => dateTime()();

  /// Ambient temperature in degrees Celsius.
  RealColumn get temperature => real().nullable()();

  /// Relative humidity in percent (0–100).
  RealColumn get humidity => real().nullable()();

  /// Equivalent CO₂ concentration in ppm (ENS160 calculated).
  IntColumn get eco2 => integer().nullable().named('eco2')();

  /// Total Volatile Organic Compounds in ppb (ENS160 calculated).
  IntColumn get tvoc => integer().nullable().named('tvoc')();

  /// ENS160 Air Quality Index: integer 1 (Excellent) to 5 (Unhealthy).
  IntColumn get aqi => integer().nullable()();
}
