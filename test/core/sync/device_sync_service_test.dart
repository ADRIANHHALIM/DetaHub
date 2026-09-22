// test/core/sync/device_sync_service_test.dart
//
// Regression tests for DeviceSyncService offline reconciliation pipeline (Group D: 26-40).

import 'package:detahub/core/database/app_database.dart';
import 'package:detahub/core/network/device_api_service.dart';
import 'package:detahub/core/network/models/device_file.dart';
import 'package:detahub/core/network/network_error.dart';
import 'package:detahub/core/sync/csv/telemetry_csv_parser.dart';
import 'package:detahub/core/sync/device_sync_service.dart';
import 'package:detahub/core/sync/models/sync_result.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeDeviceApiService extends DeviceApiService {
  FakeDeviceApiService() : super(Dio());

  List<DeviceFile> filesToReturn = [];
  Map<String, String> fileContents = {};
  List<String> deletedFiles = [];
  List<String> downloadOrder = [];
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
    downloadOrder.add(fileName);
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
  const testDeviceId2 = 'lat-test-node-02';
  const testBaseUrl = 'http://192.168.1.100';
  const testBaseUrl2 = 'http://192.168.1.101';
  final refDate = DateTime.utc(2026, 9, 22);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    fakeApi = FakeDeviceApiService();
    syncService = DeviceSyncService(
      apiService: fakeApi,
      telemetryDao: db.telemetryDao,
      csvParser: const TelemetryCsvParser(),
    );

    // Seed parent Sector, SubSector, and Devices
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
        name: const Value('Lab Air Tester 1'),
        productType: const Value('LAT_ENS160'),
        baseUrl: const Value(testBaseUrl),
      ),
    );
    await db.deviceDao.upsertDevice(
      DevicesCompanion(
        id: const Value(testDeviceId2),
        subSectorId: Value(subSectorId),
        name: const Value('Lab Air Tester 2'),
        productType: const Value('LAT_ENS160'),
        baseUrl: const Value(testBaseUrl2),
      ),
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('Group D: DeviceSyncService Hardening (26-40)', () {
    test('26. clean sync deletes historical source and reports clean success', () async {
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
        referenceTime: refDate,
      );

      expect(result.status, SyncStatus.success);
      expect(result.isCleanSuccess, isTrue);
      expect(result.recordsRead, 2);
      expect(result.recordsInserted, 2);
      expect(result.recordsRejected, 0);
      expect(result.preservedFiles, isEmpty);
      expect(result.deletedFiles, ['data_2026-09-20.csv']);
      expect(fakeApi.deletedFiles, ['data_2026-09-20.csv']);
    });

    test('27. invalid row preserves source file (DO NOT delete)', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          'corrupted-bad-row-garbage\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      // CRITICAL DATA LOSS PREVENTION:
      expect(result.recordsRejected, 1);
      expect(result.deletedFiles, isEmpty);
      expect(result.preservedFiles, ['data_2026-09-20.csv']);
      expect(fakeApi.deletedFiles, isEmpty);
      expect(result.isCleanSuccess, isFalse);
      expect(result.status, SyncStatus.partial);
    });

    test('28. valid rows are still persisted when another row is invalid', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          'corrupted-bad-row\n'
          '2026-09-20T10:02:00Z,25.2,60.5,412,111,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      // Valid records are saved
      expect(result.recordsInserted, 2);
      expect(result.recordsRejected, 1);
      final stored = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(stored, 2);

      // But source file remains preserved
      expect(result.deletedFiles, isEmpty);
      expect(result.preservedFiles, ['data_2026-09-20.csv']);
    });

    test('29. DB failure preserves source file', () async {
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
        referenceTime: refDate,
      );

      expect(result.filesFailed, 1);
      expect(result.preservedFiles, ['data_2026-09-20.csv']);
      expect(fakeApi.deletedFiles, isEmpty);
      failingSyncService.dispose();
    });

    test('30. delete failure preserves source file in audit', () async {
      fakeApi.failDelete = true;
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      expect(result.recordsInserted, 1);
      expect(result.failedDeletes, ['data_2026-09-20.csv']);
      expect(result.preservedFiles, ['data_2026-09-20.csv']);
      expect(result.deletedFiles, isEmpty);
      expect(result.isCleanSuccess, isFalse);
    });

    test('31. repeated sync is idempotent', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );
      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );
      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      final count = await db.telemetryDao.countTelemetryForDevice(testDeviceId);
      expect(count, 1);
    });

    test('32. duplicate telemetry is ignored without error', () async {
      const csv =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] = csv;

      final r1 = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );
      expect(r1.recordsInserted, 1);
      expect(r1.recordsIgnored, 0);

      final r2 = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );
      expect(r2.recordsInserted, 0);
      expect(r2.recordsIgnored, 1);
    });

    test('33. chronological file order (oldest historical file first)', () async {
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-21.csv'),
        const DeviceFile(name: 'data_2026-09-19.csv'),
        const DeviceFile(name: 'data_2026-09-20.csv'),
      ];
      fakeApi.fileContents['data_2026-09-19.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-19T10:00:00Z,24.0,50.0,400,100,1\n';
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,24.5,50.0,400,100,1\n';
      fakeApi.fileContents['data_2026-09-21.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-21T10:00:00Z,25.0,50.0,400,100,1\n';

      await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      expect(fakeApi.downloadOrder, [
        'data_2026-09-19.csv',
        'data_2026-09-20.csv',
        'data_2026-09-21.csv',
      ]);
    });

    test("34. today's active file is preserved", () async {
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-22.csv'), // today
      ];
      fakeApi.fileContents['data_2026-09-22.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-22T10:00:00Z,25.0,55.0,420,110,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      expect(result.recordsInserted, 1);
      expect(result.filesSkipped, 1);
      expect(result.preservedFiles, ['data_2026-09-22.csv']);
      expect(fakeApi.deletedFiles, isEmpty);
    });

    test('35. undated file is preserved', () async {
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'log.csv'),
        const DeviceFile(name: 'backup.csv'),
      ];
      fakeApi.fileContents['log.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,55.0,420,110,1\n';
      fakeApi.fileContents['backup.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T11:00:00Z,25.1,55.1,421,111,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      expect(result.recordsInserted, 2);
      expect(result.preservedFiles, containsAll(['log.csv', 'backup.csv']));
      expect(fakeApi.deletedFiles, isEmpty);
    });

    test('36. one sync per device (single-flight lock)', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      final f1 = syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );
      final f2 = syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      final results = await Future.wait([f1, f2]);
      expect(identical(results[0], results[1]), isTrue);
    });

    test('37. another device can sync independently in parallel', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n';

      final f1 = syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );
      final f2 = syncService.reconcileDevice(
        deviceId: testDeviceId2,
        baseUrl: testBaseUrl2,
        referenceTime: refDate,
      );

      final results = await Future.wait([f1, f2]);
      expect(results[0].deviceId, testDeviceId);
      expect(results[1].deviceId, testDeviceId2);
      expect(identical(results[0], results[1]), isFalse);
    });

    test('38. partial result reports preserved files', () async {
      // File A: valid -> deleted
      // File B: invalid row -> preserved
      // File C: valid -> deleted
      fakeApi.filesToReturn = [
        const DeviceFile(name: 'data_2026-09-19.csv'),
        const DeviceFile(name: 'data_2026-09-20.csv'),
        const DeviceFile(name: 'data_2026-09-21.csv'),
      ];
      fakeApi.fileContents['data_2026-09-19.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-19T10:00:00Z,24.0,50.0,400,100,1\n';
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-20T10:00:00Z,24.0,50.0,400,100,1\ninvalid-corrupted-row\n';
      fakeApi.fileContents['data_2026-09-21.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n2026-09-21T10:00:00Z,25.0,50.0,400,100,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      expect(result.deletedFiles, ['data_2026-09-19.csv', 'data_2026-09-21.csv']);
      expect(result.preservedFiles, ['data_2026-09-20.csv']);
      expect(result.filesPreserved, 1);
      expect(result.status, SyncStatus.partial);
    });

    test('39. partial result reports rejected rows', () async {
      fakeApi.filesToReturn = [const DeviceFile(name: 'data_2026-09-20.csv')];
      fakeApi.fileContents['data_2026-09-20.csv'] =
          'Timestamp,Temperature,Humidity,eCO2,TVOC,AQI\n'
          '2026-09-20T10:00:00Z,25.0,60.0,410,110,1\n'
          'bad-row-1\n'
          'bad-row-2\n'
          '2026-09-20T10:03:00Z,25.3,60.3,413,113,1\n';

      final result = await syncService.reconcileDevice(
        deviceId: testDeviceId,
        baseUrl: testBaseUrl,
        referenceTime: refDate,
      );

      expect(result.recordsRead, 4);
      expect(result.recordsInserted, 2);
      expect(result.recordsRejected, 2);
      expect(result.status, SyncStatus.partial);
    });

    test('40. clean success requires zero rejected, zero preserved, and zero failed deletes', () {
      final now = DateTime.now();

      final clean = SyncResult(
        deviceId: testDeviceId,
        startedAt: now,
        completedAt: now,
        status: SyncStatus.success,
        recordsInserted: 10,
        recordsRejected: 0,
        preservedFiles: const [],
        deletedFiles: const ['data_2026-09-20.csv'],
        failedDeletes: const [],
      );
      expect(clean.isCleanSuccess, isTrue);

      final withRejected = SyncResult(
        deviceId: testDeviceId,
        startedAt: now,
        completedAt: now,
        status: SyncStatus.success,
        recordsInserted: 10,
        recordsRejected: 1,
      );
      expect(withRejected.isCleanSuccess, isFalse);

      final withPreserved = SyncResult(
        deviceId: testDeviceId,
        startedAt: now,
        completedAt: now,
        status: SyncStatus.success,
        recordsInserted: 10,
        preservedFiles: const ['data_2026-09-20.csv'],
      );
      expect(withPreserved.isCleanSuccess, isFalse);

      final withFailedDeletes = SyncResult(
        deviceId: testDeviceId,
        startedAt: now,
        completedAt: now,
        status: SyncStatus.success,
        recordsInserted: 10,
        failedDeletes: const ['data_2026-09-20.csv'],
      );
      expect(withFailedDeletes.isCleanSuccess, isFalse);

      final withFailedFiles = SyncResult(
        deviceId: testDeviceId,
        startedAt: now,
        completedAt: now,
        status: SyncStatus.success,
        filesFailed: 1,
      );
      expect(withFailedFiles.isCleanSuccess, isFalse);
    });
  });
}
