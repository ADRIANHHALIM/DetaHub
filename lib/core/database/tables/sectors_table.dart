// lib/core/database/tables/sectors_table.dart
//
// Drift table definition for top-level organizational units called "Sectors".
// A Sector represents a physical location or organization (e.g., "Universitas Trisakti").

import 'package:drift/drift.dart';

/// Top-level organizational grouping for Sub-Sectors and Device Nodes.
///
/// Examples: "Universitas Trisakti", "Rumah Pribadi"
class Sectors extends Table {
  /// Auto-incremented surrogate primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Human-readable sector name. Required, non-empty.
  TextColumn get name => text().withLength(min: 1, max: 128)();

  /// ISO-8601 timestamp of when this sector was created locally.
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
}
