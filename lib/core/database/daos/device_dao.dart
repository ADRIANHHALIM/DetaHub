// lib/core/database/daos/device_dao.dart
//
// Data Access Object for Device Nodes — the leaf of the data hierarchy.
// Handles CRUD, upsert (for re-registering a device at a new IP), and
// reactive streams scoped to a Sub-Sector.

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../tables/devices_table.dart';

part 'device_dao.g.dart';

@DriftAccessor(tables: [Devices])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.db);

  // --- Read ---

  /// Reactive stream of all devices across all sub-sectors.
  Stream<List<Device>> watchAllDevices() =>
      (select(devices)..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
          .watch();

  /// Reactive stream of all devices within a given sub-sector.
  /// Emits a new list whenever any device in that sub-sector changes.
  Stream<List<Device>> watchDevicesForSubSector(int subSectorId) =>
      (select(devices)
            ..where((d) => d.subSectorId.equals(subSectorId))
            ..orderBy([(d) => OrderingTerm.asc(d.createdAt)]))
          .watch();

  /// One-shot fetch of a single device by its string ID.
  /// Returns null if the device does not exist.
  Future<Device?> getDeviceById(String deviceId) =>
      (select(devices)..where((d) => d.id.equals(deviceId))).getSingleOrNull();

  /// Reactive stream for a single device (used on the device detail screen).
  Stream<Device?> watchDeviceById(String deviceId) =>
      (select(devices)..where((d) => d.id.equals(deviceId)))
          .watchSingleOrNull();

  // --- Write ---

  /// Inserts a new device or replaces it if the same [id] already exists.
  /// Use this for both initial registration and IP/URL updates.
  Future<void> upsertDevice(DevicesCompanion entry) =>
      into(devices).insertOnConflictUpdate(entry);

  /// Updates the [lastSeenAt] timestamp after a successful ping.
  Future<void> updateLastSeen(String deviceId, DateTime timestamp) =>
      (update(devices)..where((d) => d.id.equals(deviceId)))
          .write(DevicesCompanion(lastSeenAt: Value(timestamp)));

  /// Permanently removes a device. Its telemetry_records cascade-delete.
  Future<int> deleteDevice(String deviceId) =>
      (delete(devices)..where((d) => d.id.equals(deviceId))).go();
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

final deviceDaoProvider = Provider<DeviceDao>((ref) {
  return ref.watch(appDatabaseProvider).deviceDao;
});
