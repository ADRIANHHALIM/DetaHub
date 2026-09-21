// lib/core/database/tables/devices_table.dart
//
// Drift table definition for Device Nodes — the leaf level of the hierarchy.
// Each device is a physical IoT node (e.g., LAT-ENS160) exposing a local HTTP
// micro-server. The primary key is a user-defined string ID (not auto-increment)
// to preserve the hardware identifier across syncs.

import 'package:drift/drift.dart';

import 'sub_sectors_table.dart';

/// Represents a physical IoT device node (e.g., LAT, future DetaLab products).
///
/// The [id] is a user-assigned semantic string (e.g., "lat-lab-01") that
/// matches the device's self-reported identifier in /api/manifest.
class Devices extends Table {
  /// User-defined primary key mirroring the device's own ID from /api/manifest.
  /// Example: "lat-lab-01"
  TextColumn get id => text().withLength(min: 1, max: 64)();

  /// Friendly display name for UI (may differ from raw ID).
  TextColumn get name => text().withLength(min: 1, max: 128)();

  /// Base HTTP URL of the device's local micro-server.
  /// Example: "http://192.168.1.50"
  TextColumn get baseUrl => text().named('base_url')();

  /// Product type string matching a known DetaLab product family.
  /// Used to select the correct AI model and metric schema.
  /// Example: "LAT_ENS160"
  TextColumn get productType => text().named('product_type')();

  /// FK → sub_sectors.id. Cascades DELETE so that removing a Sub-Sector
  /// removes all its Device Nodes (and their telemetry records).
  IntColumn get subSectorId => integer()
      .named('sub_sector_id')
      .references(SubSectors, #id, onDelete: KeyAction.cascade)();

  /// Last successful ping timestamp. Null if device has never been reached.
  DateTimeColumn get lastSeenAt =>
      dateTime().nullable().named('last_seen_at')();

  /// Local creation timestamp.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
