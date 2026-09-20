// lib/core/database/tables/sub_sectors_table.dart
//
// Drift table definition for Sub-Sectors: second level of the data hierarchy.
// A Sub-Sector belongs to exactly one Sector and contains one or more Device Nodes.

import 'package:drift/drift.dart';

import 'sectors_table.dart';

/// Mid-level organizational unit within a Sector.
///
/// Examples: "Lab IoT Lt.3", "Ruang Rapat Gedung H", "Kamar Tidur"
class SubSectors extends Table {
  /// Auto-incremented surrogate primary key.
  IntColumn get id => integer().autoIncrement()();

  /// Human-readable sub-sector name. Required, non-empty.
  TextColumn get name => text().withLength(min: 1, max: 128)();

  /// FK → sectors.id. Cascades DELETE so that removing a Sector
  /// automatically removes all its Sub-Sectors (and their Devices
  /// via the chain of cascades).
  IntColumn get sectorId => integer()
      .named('sector_id')
      .references(Sectors, #id, onDelete: KeyAction.cascade)();

  /// ISO-8601 timestamp of local creation.
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .named('created_at')();
}
