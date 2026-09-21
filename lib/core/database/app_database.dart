// lib/core/database/app_database.dart
//
// Root Drift database definition.
// Registers all 4 tables and 3 DAOs. Provides the singleton database
// connection factory and the Riverpod provider used throughout the app.

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables/sectors_table.dart';
import 'tables/sub_sectors_table.dart';
import 'tables/devices_table.dart';
import 'tables/telemetry_records_table.dart';
import 'daos/sector_dao.dart';
import 'daos/device_dao.dart';
import 'daos/telemetry_dao.dart';

part 'app_database.g.dart';

/// The single Drift database instance for DetaHub.
///
/// All local data lives in `detahub.db` in the app's documents directory.
/// Schema migration is handled via [MigrationStrategy]; bump [schemaVersion]
/// on any breaking table change and add a migration step.
@DriftDatabase(
  tables: [
    Sectors,
    SubSectors,
    Devices,
    TelemetryRecords,
  ],
  daos: [
    SectorDao,
    DeviceDao,
    TelemetryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Increment this whenever the schema changes.
  /// Add corresponding steps in [migration] below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // Create all tables and indexes on first launch.
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // Future migration steps go here.
          // Example: if (from < 2) await m.addColumn(devices, devices.firmwareVersion);
        },
        beforeOpen: (details) async {
          // Enable foreign key enforcement (SQLite disables it by default).
          await customStatement('PRAGMA foreign_keys = ON');
          // Enable Write-Ahead Logging for better concurrent read performance.
          await customStatement('PRAGMA journal_mode = WAL');
          // Tune page cache size (~4MB for telemetry-heavy queries).
          await customStatement('PRAGMA cache_size = -4096');
        },
      );
}

// ---------------------------------------------------------------------------
// Connection Factory
// ---------------------------------------------------------------------------

/// Opens the SQLite database file at the platform-appropriate documents path.
/// Uses `drift_flutter` which selects the correct backend per platform
/// (NativeDatabase on Android/iOS, WebDatabase on web).
QueryExecutor _openConnection() {
  return driftDatabase(name: 'detahub');
}

// ---------------------------------------------------------------------------
// Riverpod Providers
// ---------------------------------------------------------------------------

/// Global singleton [AppDatabase] provider.
/// Disposed when the root ProviderScope is destroyed (app exit).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
