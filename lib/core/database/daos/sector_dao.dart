// lib/core/database/daos/sector_dao.dart
//
// Data Access Object for Sectors and the full Sector → Sub-Sector → Device
// navigation tree. All reads are reactive (Drift stream-based).

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../tables/sectors_table.dart';
import '../tables/sub_sectors_table.dart';
import '../tables/devices_table.dart';

part 'sector_dao.g.dart';

// ---------------------------------------------------------------------------
// Data Transfer Objects
// ---------------------------------------------------------------------------

/// Aggregated node in the navigation hierarchy.
/// Contains a Sector with its nested Sub-Sectors (each with device count).
class SectorWithSubSectors {
  final Sector sector;
  final List<SubSectorWithDeviceCount> subSectors;

  const SectorWithSubSectors({
    required this.sector,
    required this.subSectors,
  });
}

class SubSectorWithDeviceCount {
  final SubSector subSector;
  final int deviceCount;

  const SubSectorWithDeviceCount({
    required this.subSector,
    required this.deviceCount,
  });
}

/// Enriched Device representation containing its Area (SubSector) and Location (Sector) names.
/// Maps internal database hierarchy to user mental model (Issue #2).
class DeviceWithLocation {
  final Device device;
  final String areaName;
  final String locationName;
  final int sectorId;
  final int subSectorId;

  const DeviceWithLocation({
    required this.device,
    required this.areaName,
    required this.locationName,
    required this.sectorId,
    required this.subSectorId,
  });
}

// ---------------------------------------------------------------------------
// DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [Sectors, SubSectors, Devices])
class SectorDao extends DatabaseAccessor<AppDatabase> with _$SectorDaoMixin {
  SectorDao(super.db);

  // --- Sector CRUD ---

  /// Reactive stream of all sectors ordered by creation date (oldest first).
  Stream<List<Sector>> watchAllSectors() =>
      (select(sectors)..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
          .watch();

  /// Inserts a new sector. Returns the auto-generated row ID.
  Future<int> insertSector(SectorsCompanion entry) =>
      into(sectors).insert(entry);

  /// Updates an existing sector (by primary key match).
  Future<bool> updateSector(SectorsCompanion entry) =>
      update(sectors).replace(entry);

  /// Permanently deletes a sector. Sub-Sectors and their Devices cascade.
  Future<int> deleteSector(int sectorId) =>
      (delete(sectors)..where((s) => s.id.equals(sectorId))).go();

  // --- Sub-Sector CRUD ---

  /// Reactive stream of sub-sectors belonging to a specific sector.
  Stream<List<SubSector>> watchSubSectorsForSector(int sectorId) =>
      (select(subSectors)
            ..where((ss) => ss.sectorId.equals(sectorId))
            ..orderBy([(ss) => OrderingTerm.asc(ss.createdAt)]))
          .watch();

  /// Inserts a new sub-sector. Returns the auto-generated row ID.
  Future<int> insertSubSector(SubSectorsCompanion entry) =>
      into(subSectors).insert(entry);

  Future<bool> updateSubSector(SubSectorsCompanion entry) =>
      update(subSectors).replace(entry);

  Future<int> deleteSubSector(int subSectorId) =>
      (delete(subSectors)..where((ss) => ss.id.equals(subSectorId))).go();

  // --- Full Hierarchy ---

  /// Reactive stream of the complete navigation tree:
  /// All Sectors → Sub-Sectors → Device count per Sub-Sector.
  ///
  /// Uses a LEFT JOIN to count devices per sub-sector so that sub-sectors
  /// with zero devices are still visible in the sidebar.
  Stream<List<SectorWithSubSectors>> watchFullHierarchy() {
    // Step 1: Watch all sectors reactively.
    return watchAllSectors().asyncExpand((allSectors) {
      // Step 2: For each emission, fetch sub-sectors + device counts.
      return Stream.fromFuture(_buildHierarchy(allSectors));
    });
  }

  Future<List<SectorWithSubSectors>> _buildHierarchy(
      List<Sector> allSectors) async {
    if (allSectors.isEmpty) return [];

    // Fetch all sub-sectors in one query (more efficient than N+1).
    final allSubSectors = await select(subSectors).get();

    // Fetch device counts grouped by sub_sector_id using a custom expression.
    final deviceCountQuery = selectOnly(devices)
      ..addColumns([devices.subSectorId, devices.id.count()]);
    deviceCountQuery.groupBy([devices.subSectorId]);

    final countRows = await deviceCountQuery.get();

    // Build a map: subSectorId → deviceCount for O(1) lookup.
    final countMap = <int, int>{
      for (final row in countRows)
        row.read(devices.subSectorId)!: row.read(devices.id.count())!,
    };

    // Group sub-sectors by sector ID.
    final subSectorMap = <int, List<SubSector>>{};
    for (final ss in allSubSectors) {
      subSectorMap.putIfAbsent(ss.sectorId, () => []).add(ss);
    }

    // Assemble the tree.
    return allSectors.map((sector) {
      final subs = subSectorMap[sector.id] ?? [];
      return SectorWithSubSectors(
        sector: sector,
        subSectors: subs
            .map((ss) => SubSectorWithDeviceCount(
                  subSector: ss,
                  deviceCount: countMap[ss.id] ?? 0,
                ))
            .toList(),
      );
    }).toList();
  }

  // --- Devices with Location (User Mental Model) ---

  /// Reactive stream of all devices enriched with their Area (SubSector) and Location (Sector).
  Stream<List<DeviceWithLocation>> watchAllDevicesWithLocation() {
    final query = select(devices).join([
      innerJoin(subSectors, subSectors.id.equalsExp(devices.subSectorId)),
      innerJoin(sectors, sectors.id.equalsExp(subSectors.sectorId)),
    ])
      ..orderBy([OrderingTerm.asc(devices.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return DeviceWithLocation(
          device: row.readTable(devices),
          areaName: row.readTable(subSectors).name,
          locationName: row.readTable(sectors).name,
          sectorId: row.readTable(sectors).id,
          subSectorId: row.readTable(subSectors).id,
        );
      }).toList();
    });
  }

  /// Reactive stream for a single device enriched with Area and Location.
  Stream<DeviceWithLocation?> watchDeviceWithLocation(String deviceId) {
    final query = select(devices).join([
      innerJoin(subSectors, subSectors.id.equalsExp(devices.subSectorId)),
      innerJoin(sectors, sectors.id.equalsExp(subSectors.sectorId)),
    ])
      ..where(devices.id.equals(deviceId));

    return query.watchSingleOrNull().map((row) {
      if (row == null) return null;
      return DeviceWithLocation(
        device: row.readTable(devices),
        areaName: row.readTable(subSectors).name,
        locationName: row.readTable(sectors).name,
        sectorId: row.readTable(sectors).id,
        subSectorId: row.readTable(subSectors).id,
      );
    });
  }
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

/// Provides a [SectorDao] scoped to the app's [AppDatabase] instance.
final sectorDaoProvider = Provider<SectorDao>((ref) {
  return ref.watch(appDatabaseProvider).sectorDao;
});
