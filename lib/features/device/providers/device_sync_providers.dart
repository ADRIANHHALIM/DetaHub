// lib/features/device/providers/device_sync_providers.dart
//
// Riverpod providers for offline historical telemetry synchronization.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/daos/telemetry_dao.dart';
import '../../../core/network/providers/network_providers.dart';
import '../../../core/sync/device_sync_service.dart';
import '../../../core/sync/models/sync_result.dart';
import '../../../core/sync/models/sync_state.dart';

/// Singleton provider for the [DeviceSyncService].
final deviceSyncServiceProvider = Provider<DeviceSyncService>((ref) {
  final api = ref.watch(deviceApiServiceProvider);
  final dao = ref.watch(telemetryDaoProvider);
  final service = DeviceSyncService(
    apiService: api,
    telemetryDao: dao,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive stream of the current [SyncState] for a given [deviceId].
final deviceSyncStateProvider =
    StreamProvider.family<SyncState, String>((ref, deviceId) {
  final syncService = ref.watch(deviceSyncServiceProvider);
  return syncService.watchSyncState(deviceId);
});

/// Helper notifier to trigger and track on-demand reconciliation.
class DeviceSyncController extends StateNotifier<AsyncValue<SyncResult?>> {
  final DeviceSyncService _syncService;

  DeviceSyncController(this._syncService) : super(const AsyncData(null));

  Future<SyncResult?> syncDevice({
    required String deviceId,
    required String baseUrl,
    String? activeFileName,
  }) async {
    state = const AsyncLoading();
    try {
      final result = await _syncService.reconcileDevice(
        deviceId: deviceId,
        baseUrl: baseUrl,
        activeFileName: activeFileName,
      );
      state = AsyncData(result);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      return null;
    }
  }
}

final deviceSyncControllerProvider =
    StateNotifierProvider.family<DeviceSyncController, AsyncValue<SyncResult?>, String>(
  (ref, deviceId) {
    return DeviceSyncController(ref.watch(deviceSyncServiceProvider));
  },
);
