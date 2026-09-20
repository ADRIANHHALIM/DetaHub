// lib/features/sector/providers/sector_providers.dart
//
// Riverpod providers for the Sector and Sub-Sector feature.
// All providers are reactive — they automatically rebuild when the DB changes.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/sector_dao.dart';

// ---------------------------------------------------------------------------
// Sector providers
// ---------------------------------------------------------------------------

/// Reactive list of all Sectors, ordered by creation date.
final watchAllSectorsProvider = StreamProvider<List<Sector>>((ref) {
  return ref.watch(sectorDaoProvider).watchAllSectors();
});

/// Full navigation hierarchy: Sector → Sub-Sectors with device counts.
/// Powers the sidebar/home screen expansion list.
final watchFullHierarchyProvider =
    StreamProvider<List<SectorWithSubSectors>>((ref) {
  return ref.watch(sectorDaoProvider).watchFullHierarchy();
});

// ---------------------------------------------------------------------------
// Sub-Sector providers
// ---------------------------------------------------------------------------

/// Reactive list of Sub-Sectors for a specific Sector ID.
final watchSubSectorsProvider =
    StreamProvider.family<List<SubSector>, int>((ref, sectorId) {
  return ref.watch(sectorDaoProvider).watchSubSectorsForSector(sectorId);
});

// ---------------------------------------------------------------------------
// Mutation notifiers
// ---------------------------------------------------------------------------

/// Manages Sector CRUD mutations (insert, update, delete).
/// Using [AsyncNotifier] to track loading state during operations.
class SectorMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addSector(String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sectorDaoProvider).insertSector(
            SectorsCompanion.insert(name: name),
          );
    });
  }

  Future<void> deleteSector(int sectorId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sectorDaoProvider).deleteSector(sectorId);
    });
  }
}

final sectorMutationProvider =
    AsyncNotifierProvider<SectorMutationNotifier, void>(
  SectorMutationNotifier.new,
);

/// Manages Sub-Sector CRUD mutations.
class SubSectorMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> addSubSector(int sectorId, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sectorDaoProvider).insertSubSector(
            SubSectorsCompanion.insert(
              name: name,
              sectorId: sectorId,
            ),
          );
    });
  }

  Future<void> deleteSubSector(int subSectorId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(sectorDaoProvider).deleteSubSector(subSectorId);
    });
  }
}

final subSectorMutationProvider =
    AsyncNotifierProvider<SubSectorMutationNotifier, void>(
  SubSectorMutationNotifier.new,
);
