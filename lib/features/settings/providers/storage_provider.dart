// lib/features/settings/providers/storage_provider.dart
//
// Reactive Riverpod providers for the Storage & Local Data Management dashboard.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/device_dao.dart';
import '../../../core/database/daos/telemetry_dao.dart';

class DeviceStorageSummary {
  final Device device;
  final int recordCount;
  final DateTime? oldestTimestamp;
  final DateTime? newestTimestamp;

  const DeviceStorageSummary({
    required this.device,
    required this.recordCount,
    this.oldestTimestamp,
    this.newestTimestamp,
  });
}

class StorageOverviewData {
  final int totalDevices;
  final int totalRecords;
  final DateTime? oldestTimestamp;
  final DateTime? newestTimestamp;
  final List<DeviceStorageSummary> deviceSummaries;

  const StorageOverviewData({
    required this.totalDevices,
    required this.totalRecords,
    this.oldestTimestamp,
    this.newestTimestamp,
    required this.deviceSummaries,
  });
}

final storageOverviewProvider =
    FutureProvider.autoDispose<StorageOverviewData>((ref) async {
  final deviceDao = ref.watch(deviceDaoProvider);
  final telemetryDao = ref.watch(telemetryDaoProvider);

  final devices = await deviceDao.getAllDevices();
  final totalRecords = await telemetryDao.countAllTelemetry();
  final oldestTimestamp = await telemetryDao.getOldestTimestamp();
  final newestTimestamp = await telemetryDao.getNewestTimestamp();

  final summaries = <DeviceStorageSummary>[];
  for (final device in devices) {
    final count = await telemetryDao.countTelemetryForDevice(device.id);
    final oldest = await telemetryDao.getOldestTimestampForDevice(device.id);
    final newest = await telemetryDao.getNewestTimestampForDevice(device.id);

    summaries.add(
      DeviceStorageSummary(
        device: device,
        recordCount: count,
        oldestTimestamp: oldest,
        newestTimestamp: newest,
      ),
    );
  }

  return StorageOverviewData(
    totalDevices: devices.length,
    totalRecords: totalRecords,
    oldestTimestamp: oldestTimestamp,
    newestTimestamp: newestTimestamp,
    deviceSummaries: summaries,
  );
});
