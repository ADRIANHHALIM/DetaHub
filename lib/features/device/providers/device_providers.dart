// lib/features/device/providers/device_providers.dart
//
// Riverpod providers for the Device feature.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/device_dao.dart';
import '../../../core/database/daos/telemetry_dao.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/models/device_manifest.dart';
import '../../../core/network/providers/network_providers.dart';

// ---------------------------------------------------------------------------
// Read providers
// ---------------------------------------------------------------------------

/// Reactive list of all devices across all sub-sectors.
final watchAllDevicesProvider = StreamProvider<List<Device>>((ref) {
  return ref.watch(deviceDaoProvider).watchAllDevices();
});

/// Reactive list of devices within a given Sub-Sector.
final watchDevicesProvider =
    StreamProvider.family<List<Device>, int>((ref, subSectorId) {
  return ref.watch(deviceDaoProvider).watchDevicesForSubSector(subSectorId);
});

/// Reactive single device by its string ID.
final watchDeviceProvider =
    StreamProvider.family<Device?, String>((ref, deviceId) {
  return ref.watch(deviceDaoProvider).watchDeviceById(deviceId);
});

/// Last persisted reading, used as honest offline/initial state on detail.
final watchLatestTelemetryRecordProvider =
    StreamProvider.family<TelemetryRecord?, String>((ref, deviceId) {
  return ref.watch(telemetryDaoProvider).watchLatestRecord(deviceId);
});

// ---------------------------------------------------------------------------
// Handshake / connection test
// ---------------------------------------------------------------------------

/// Performs a GET /api/manifest handshake against the given [baseUrl].
/// Used in DeviceFormScreen's "Test Connection" button.
/// Automatically caches and deduplicates requests via Riverpod's family key.
final deviceHandshakeProvider =
    FutureProvider.family<Result<DeviceManifest, NetworkError>, String>(
        (ref, baseUrl) async {
  final service = ref.watch(deviceApiServiceProvider);
  return service.fetchManifest(baseUrl);
});

// ---------------------------------------------------------------------------
// Device mutation notifier
// ---------------------------------------------------------------------------

class DeviceMutationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> upsertDevice(DevicesCompanion entry) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deviceDaoProvider).upsertDevice(entry);
    });
  }

  Future<void> deleteDevice(String deviceId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deviceDaoProvider).deleteDevice(deviceId);
      // Also remove associated telemetry (cascade handles DB, but we can
      // proactively prune to avoid orphan records from manual FK issues).
    });
  }

  Future<void> updateLastSeen(String deviceId) async {
    await ref.read(deviceDaoProvider).updateLastSeen(deviceId, DateTime.now());
  }
}

final deviceMutationProvider =
    AsyncNotifierProvider<DeviceMutationNotifier, void>(
  DeviceMutationNotifier.new,
);
