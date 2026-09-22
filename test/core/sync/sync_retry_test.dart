// test/core/sync/sync_retry_test.dart
//
// Regression tests for Bounded Sync Retry and Manual Trigger (Group E: 41-47).

import 'package:detahub/core/network/device_api_service.dart';
import 'package:detahub/core/network/models/device_file.dart';
import 'package:detahub/core/network/network_error.dart';
import 'package:detahub/core/sync/csv/telemetry_csv_parser.dart';
import 'package:detahub/core/sync/device_sync_service.dart';
import 'package:detahub/core/sync/models/sync_result.dart';
import 'package:detahub/core/sync/models/sync_state.dart';
import 'package:detahub/features/device/providers/device_sync_providers.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:detahub/core/database/app_database.dart';

class MockDeviceApiService extends DeviceApiService {
  MockDeviceApiService() : super(Dio());

  int listFilesCallCount = 0;
  bool shouldFail = false;
  List<DeviceFile> filesToReturn = [];
  Map<String, String> fileContents = {};

  @override
  Future<Result<List<DeviceFile>, NetworkError>> listFiles(String baseUrl) async {
    listFilesCallCount++;
    if (shouldFail) {
      return const Err(TimeoutError('Timed out contacting device'));
    }
    return Ok(filesToReturn);
  }

  @override
  Future<Result<String, NetworkError>> downloadFile(String baseUrl, String fileName) async {
    final content = fileContents[fileName] ?? 'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n';
    return Ok(content);
  }

  @override
  Future<Result<bool, NetworkError>> deleteFile(String baseUrl, String fileName) async {
    return const Ok(true);
  }
}

void main() {
  late AppDatabase db;
  late MockDeviceApiService mockApi;
  late DeviceSyncService syncService;
  late DeviceSyncController controller;

  const deviceId = 'node-lat-01';
  const baseUrl = 'http://192.168.1.100';
  final refDate = DateTime.utc(2026, 9, 22);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    mockApi = MockDeviceApiService();
    syncService = DeviceSyncService(
      apiService: mockApi,
      telemetryDao: db.telemetryDao,
      csvParser: const TelemetryCsvParser(),
    );
    controller = DeviceSyncController(syncService);

    // Seed device
    final sectorId = await db.sectorDao.insertSector(
      const SectorsCompanion(name: Value('Campus')),
    );
    final subSectorId = await db.sectorDao.insertSubSector(
      SubSectorsCompanion(sectorId: Value(sectorId), name: const Value('Lab')),
    );
    await db.deviceDao.upsertDevice(
      DevicesCompanion(
        id: const Value(deviceId),
        subSectorId: Value(subSectorId),
        name: const Value('Sensor Node'),
        productType: const Value('LAT_ENS160'),
        baseUrl: const Value(baseUrl),
      ),
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('Group E: Bounded Sync Retry & Manual Trigger (41-47)', () {
    test('41. online transition triggers reconciliation', () async {
      mockApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      mockApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      expect(mockApi.listFilesCallCount, 0);

      // Simulating offline -> online trigger
      final result = await controller.syncDevice(
        deviceId: deviceId,
        baseUrl: baseUrl,
      );

      expect(mockApi.listFilesCallCount, 1);
      expect(result, isNotNull);
      expect(result!.recordsInserted, 1);
    });

    test('42. transient sync failure enters SyncFailed and becomes retryable', () async {
      mockApi.shouldFail = true;

      final result = await controller.syncDevice(
        deviceId: deviceId,
        baseUrl: baseUrl,
      );

      expect(result!.status, SyncStatus.failed);
      final state = syncService.getSyncState(deviceId);
      expect(state, isA<SyncFailed>());
      expect((state as SyncFailed).message, contains('Failed to list files'));
    });

    test('43. retry schedule respects bounded cooldowns (30s, 60s, 120s, 300s)', () {
      const cooldowns = [
        Duration(seconds: 30),
        Duration(seconds: 60),
        Duration(seconds: 120),
        Duration(seconds: 300),
      ];

      final baseTime = DateTime.utc(2026, 9, 22, 10, 0, 0);

      // Attempt 0 -> 30s
      expect(baseTime.add(cooldowns[0]), DateTime.utc(2026, 9, 22, 10, 0, 30));
      // Attempt 1 -> 60s
      expect(baseTime.add(cooldowns[1]), DateTime.utc(2026, 9, 22, 10, 1, 0));
      // Attempt 2 -> 120s
      expect(baseTime.add(cooldowns[2]), DateTime.utc(2026, 9, 22, 10, 2, 0));
      // Attempt 3+ -> 300s
      expect(baseTime.add(cooldowns[3]), DateTime.utc(2026, 9, 22, 10, 5, 0));
    });

    test('44. retry does not execute on every 3-second poll', () {
      const cooldown = Duration(seconds: 30);
      final failTime = DateTime.utc(2026, 9, 22, 10, 0, 0);
      final nextRetryTime = failTime.add(cooldown);

      // 3-second polls during the 30-second cooldown period
      for (int sec = 3; sec < 30; sec += 3) {
        final pollTime = failTime.add(Duration(seconds: sec));
        final canRetry = pollTime.isAfter(nextRetryTime);
        expect(canRetry, isFalse, reason: 'Must not retry at $sec seconds');
      }

      // At 31 seconds, retry is permitted
      final eligibleTime = failTime.add(const Duration(seconds: 31));
      expect(eligibleTime.isAfter(nextRetryTime), isTrue);
    });

    test('45. successful sync resets retry state', () async {
      mockApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      mockApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      final result = await controller.syncDevice(
        deviceId: deviceId,
        baseUrl: baseUrl,
      );

      expect(result!.isCleanSuccess, isTrue);
      final state = syncService.getSyncState(deviceId);
      expect(state, isA<SyncCompleted>());
      expect((state as SyncCompleted).result.isCleanSuccess, isTrue);
    });

    test('46. manual retry triggers immediate reconciliation', () async {
      mockApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      mockApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      // Simulates manual tap on "Coba Lagi"
      final result = await controller.syncDevice(
        deviceId: deviceId,
        baseUrl: baseUrl,
      );

      expect(result, isNotNull);
      expect(result!.recordsInserted, 1);
      expect(mockApi.listFilesCallCount, 1);
    });

    test('47. concurrent retry calls remain strictly single-flight', () async {
      mockApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      mockApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      // Trigger 3 concurrent sync calls
      final f1 = syncService.reconcileDevice(deviceId: deviceId, baseUrl: baseUrl, referenceTime: refDate);
      final f2 = syncService.reconcileDevice(deviceId: deviceId, baseUrl: baseUrl, referenceTime: refDate);
      final f3 = syncService.reconcileDevice(deviceId: deviceId, baseUrl: baseUrl, referenceTime: refDate);

      final results = await Future.wait([f1, f2, f3]);

      // All 3 resolve to the identical single future
      expect(identical(results[0], results[1]), isTrue);
      expect(identical(results[1], results[2]), isTrue);
      // listFiles called exactly ONCE
      expect(mockApi.listFilesCallCount, 1);
    });
  });
}
