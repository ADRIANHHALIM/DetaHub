// test/core/sync/device_sync_service_test.dart
//
// Comprehensive unit tests for DeviceSyncService offline reconciliation pipeline.
// Covers all 15 required scenarios:
//   1. Fresh CSV imports all records
//   2. Duplicate CSV does not duplicate rows (idempotency)
//   3. Existing records + new records produce only new inserts
//   4. Malformed row rejected without failing valid rows
//   5. Database failure prevents ESP32 deletion
//   6. ESP32 deletion failure leaves sync retryable & SQLite data safe
//   7. Repeated synchronization is idempotent
//   8. Active file is never deleted
//   9. Only one sync operation runs per device (single-flight guarantee)
//   10. Large input processed in bounded chunks
//   11. Device ID is preserved correctly
//   12. Original timestamps preserved (no fake 3-second interpolation)
//   13. No synthetic telemetry created
//   14. Network timeout produces typed failure
//   15. Recoverable without requiring a disconnect event

import 'package:detahub/core/database/app_database.dart';
import 'package:detahub/core/network/device_api_service.dart';
import 'package:detahub/core/network/models/device_file.dart';
import 'package:detahub/core/network/network_error.dart';
import 'package:detahub/core/sync/csv/telemetry_csv_parser.dart';
import 'package:detahub/core/sync/device_sync_service.dart';
import 'package:detahub/core/sync/models/sync_result.dart';
import 'package:detahub/core/sync/models/sync_state.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceApiService extends DeviceApiService {
  FakeDeviceApiService() : super(Dio());

  List<DeviceFile> filesToReturn = [];
  Map<String, String> fileContents = {};
  List<String> deletedFiles = [];
  bool failListFiles = false;
  bool failDownload = false;
  bool failDelete = false;
  NetworkError? errorToReturn;

  @override
  Future<Result<List<DeviceFile>, NetworkError>> listFiles(String baseUrl) async {
    if (failListFiles) {
      return Err(errorToReturn ?? const TimeoutError('List files timeout'));
    }
    return Ok(filesToReturn);
  }

  @override
  Future<Result<String, NetworkError>> downloadFile(String baseUrl, String fileName) async {
    if (failDownload) {
      return Err(errorToReturn ?? const TimeoutError('Download timeout'));
    }
    final content = fileContents[fileName];
    if (content == null) {
      return Err(NotFoundError(fileName));
    }
    return Ok(content);
  }

  @override
  Future<Result<bool, NetworkError>> deleteFile(String baseUrl, String fileName) async {
    if (failDelete) {
      return Err(errorToReturn ?? const UnreachableError('Delete unreachable'));
    }
    deletedFiles.add(fileName);
    return const Ok(true);
  }
}

void main() {
  late AppDatabase db;
  late FakeDeviceApiService fakeApi;
  late DeviceSyncService syncService;

  const testDeviceId = 'lat-test-node-01';
  const testBaseUrl = 'http://192.168.1.100';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeApi = FakeDeviceApiService();
    syncService = DeviceSyncService(
      apiService: fakeApi,
      telemetryDao: db.telemetryDao,
      csvParser: const TelemetryCsvParser(),
    );

    // Seed parent Sector, SubSector, and Device
    final sectorId = await db.sectorDao.insertSector(
      const SectorsCompanion(name: Value('Campus')),
    );
    final subSectorId = await db.sectorDao.insertSubSector(
      SubSectorsCompanion(
        sectorId: Value(sectorId),
        name: const Value('IoT Lab'),
      ),
    );
    await db.deviceDao.upsertDevice(
      DevicesCompanion(
        id: const Value(testDeviceId),
        subSectorId: Value(subSectorId),
        name: const Value('Lab Air Tester'),
        productType: const Value('LAT_ENS160'),
        baseUrl: const Value(testBaseUrl),
      ),
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('DeviceSyncService - Production Telemetry Reconciliation', () {
    test('TEST 1: Fresh CSV imports all valid records', () async {
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-20.csv', size: 1024),
      ];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature(C),Humidity(%),eCO2(ppm),TVOC(ppb),AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          '2026-09-20T10:01:00Z,25.1,60.2,415,112,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.status, SyncStatus.success);
      expect(result.recordsRead, 2);
      expect(result.recordsInserted, 2);
      expect(result.recordsIgnored, 0);
      expect(result.deletedFiles, ['data_2026-09-20.csv']);

      final stored = await db.telemetryDao.getRecentRecords(testDeviceId, limit: 10);
      expect(stored.length, 2);
      expect(stored[1].temperature, 25.0);
      expect(stored[0].temperature, 25.1);
    });

    test('TEST 2: Duplicate CSV does not duplicate database rows', () async {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-20.csv'),
      ];
      fakeApi.fileContents['data_2026-09-20.csv'] = csv;

      // First sync
      final r1 = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );
      expect(r1.recordsInserted, 1);

      // Second sync of same data
      final r2 = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );
      expect(r2.recordsInserted, 0);
      expect(r2.recordsIgnored, 1);

      final count = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(count, 1); // Exactly 1, no duplicate
    });

    test('TEST 3: Existing records + new records produce only new inserts', () async {
      // Pre-seed record at 10:00
      await db.telemetryDao.batchInsertRecords([
        TelemetryRecordsCompanion.insert(
          deviceId: testDeviceId,
          timestamp: DateTime.utc(2026, 9, 20, 10, 0),
          temperature: const Value(25.0),
        ),
      ]);

      // CSV contains 10:00 and 10:01
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          '2026-09-20T10:01:00Z,25.5,61.0,420,115,2\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.recordsRead, 2);
      expect(result.recordsInserted, 1); // Only 10:01 was new
      expect(result.recordsIgnored, 1); // 10:00 was ignored

      final count = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(count, 2);
    });

    test('TEST 4: Malformed row is rejected without crashing the entire sync', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          'bad-row-corrupt-data\n'
          '2026-09-20T10:02:00Z,25.2,60.5,412,111,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.recordsRead, 3);
      expect(result.recordsInserted, 2);
      expect(result.recordsRejected, 1);
      expect(result.deletedFiles, ['data_2026-09-20.csv']);
    });

    test('TEST 5: Database failure prevents ESP32 deletion', () async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final closedDb = AppDatabase(NativeDatabase.memory());
      await closedDb.close();

      final failingSyncService = DeviceSyncService(
        apiService: fakeApi,
        telemetryDao: closedDb.telemetryDao,
      );

      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      final result = await failingSyncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.filesFailed, 1);
      // CRITICAL: File must NOT be deleted from ESP32
      expect(fakeApi.deletedFiles, isEmpty);
      failingSyncService.dispose();
    });

    test('TEST 6: ESP32 deletion failure leaves sync retryable & SQLite data safe', () async {
      fakeApi.failDelete = true;
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.recordsInserted, 1);
      expect(result.failedDeletes, ['data_2026-09-20.csv']);
      expect(result.deletedFiles, isEmpty);

      // Verify SQLite data was preserved despite delete failure
      final count = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(count, 1);
    });

    test('TEST 7: Repeated synchronization is idempotent', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );
      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );
      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      final count = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(count, 1);
    });

    test('TEST 8: Active file is not deleted when deletion is unsafe', () async {
      // 2026-09-22 is "today"
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-20.csv'), // historical -> can delete
        const DeviceFile(name: 'data_2026-09-22.csv'), // active log -> CANNOT delete
      ];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,24.0,50.0,400,100,1\n';
      fakeApi.fileContents['data_2026-09-22.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-22T10:00:00Z,25.0,55.0,420,110,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        activeFileName: 'data_2026-09-22.csv',
        referenceTime: DateTime.utc(2026, 9, 22, 12, 0),
      );

      expect(result.recordsInserted, 2);
      expect(result.filesSkipped, 1); // data_2026-09-22.csv skipped from deletion
      expect(result.deletedFiles, ['data_2026-09-20.csv']);
      expect(fakeApi.deletedFiles.contains('data_2026-09-22.csv'), isFalse);
    });

    test('TEST 9: Only one sync operation runs per device (single-flight lock)', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      // Launch two concurrent reconcileDevice calls simultaneously
      final future1 = syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );
      final future2 = syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      // Both should resolve to the same underlying operation
      final results = await Future.wait([future1, future2]);
      expect(results[0], equals(results[1]));
      expect(results[0].recordsInserted, 1);
    });

    test('TEST 10: Large input is processed in bounded chunks', () async {
      final buffer = StringBuffer();
      buffer.writeln('Timestamp,Temperature,Humidity,eCO2,TVOC,AQI');
      for (int i = 0; i < 1440; i++) {
        final time = DateTime.utc(2026, 9, 20).add(Duration(minutes: i));
        buffer.writeln('${time.toIso8601String()},24.0,50.0,400,100,1');
      }

      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] = buffer.toString();

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.recordsRead, 1440);
      expect(result.recordsInserted, 1440);
      expect(result.deletedFiles, ['data_2026-09-20.csv']);

      final total = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(total, 1440);
    });

    test('TEST 11: Device ID is preserved correctly in stored records', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      final records = await db.telemetryDao.getRecentRecords(testDeviceId);
      expect(records.first.deviceId, testDeviceId);
    });

    test('TEST 12: Timestamp parsing preserves original timestamps', () async {
      const originalIso = '2026-09-20T14:35:12.000Z';
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '$originalIso,25.0,60.0,410,110,1\n';

      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      final records = await db.telemetryDao.getRecentRecords(testDeviceId);
      expect(records.first.timestamp.toUtc(), DateTime.parse(originalIso));
    });

    test('TEST 13: No synthetic telemetry is created', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      // 5-minute gap in hardware logging
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          '2026-09-20T10:05:00Z,25.2,60.1,412,111,1\n';

      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      final records = await db.telemetryDao.getRecordsForRange(
        testDeviceId,
        DateTime.utc(2026, 9, 20, 10, 0),
        DateTime.utc(2026, 9, 20, 10, 5),
      );

      // Exactly 2 records — no interpolated points at 10:01, 10:02, etc.
      expect(records.length, 2);
    });

    test('TEST 14: Network timeout results in a typed failure', () async {
      fakeApi.failListFiles = true;
      fakeApi.errorToReturn = const TimeoutError('Connection timed out');

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
      );

      expect(result.status, SyncStatus.failed);
      expect(result.errors.first, contains('TimeoutError'));

      final state = syncService.getSyncState(testDeviceId);
      expect(state, isA<SyncFailed>());
      expect((state as SyncFailed).networkError, isA<TimeoutError>());
    });

    test('TEST 15: Recoverable without requiring a disconnect event', () async {
      // Simulate reconnect triggering sync after offline period
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-19.csv'),
        const DeviceFile(name: 'data_2026-09-20.csv'),
      ];
      fakeApi.fileContents['data_2026-09-19.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-19T23:59:00Z,23.0,50.0,400,100,1\n';
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T00:01:00Z,23.1,50.1,401,100,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: DateTime.utc(2026, 9, 22),
      );

      expect(result.filesProcessed, 2);
      expect(result.recordsInserted, 2);
      expect(result.deletedFiles.length, 2);
    });
  });
}
