// test/core/export/backup_restore_test.dart
//
// In-memory SQLite tests for database queries, backup structure, and restore logic.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:detahub/core/database/app_database.dart';
import 'package:detahub/core/export/restore_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('TelemetryDao Storage & Overview Queries', () {
    test('countAllTelemetry and device metrics on empty db', () async {
      expect(await db.telemetryDao.countAllTelemetry(), 0);
      expect(await db.telemetryDao.getOldestTimestamp(), isNull);
      expect(await db.telemetryDao.getNewestTimestamp(), isNull);
      expect(await db.telemetryDao.getRecentRecords('lat-01'), isEmpty);
    });

    test('counts and ranges with real records', () async {
      final t1 = DateTime(2026, 9, 1, 10, 0);
      final t2 = DateTime(2026, 9, 1, 11, 0);
      final t3 = DateTime(2026, 9, 2, 12, 0);

      // Setup hierarchy
      final sectorId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Office')),
      );
      final subSectorId = await db.sectorDao.insertSubSector(
        SubSectorsCompanion(
          sectorId: Value(sectorId),
          name: const Value('Lab A'),
        ),
      );
      await db.deviceDao.upsertDevice(
        DevicesCompanion(
          id: const Value('lat-01'),
          subSectorId: Value(subSectorId),
          name: const Value('Air Tester 1'),
          productType: const Value('LAT'),
          baseUrl: const Value('http://192.168.1.50'),
        ),
      );

      await db.telemetryDao.batchInsertRecords([
        TelemetryRecordsCompanion.insert(
          deviceId: 'lat-01',
          timestamp: t1,
          temperature: const Value(25.0),
          humidity: const Value(50.0),
          eco2: const Value(500),
          tvoc: const Value(100),
          aqi: const Value(1),
        ),
        TelemetryRecordsCompanion.insert(
          deviceId: 'lat-01',
          timestamp: t2,
          temperature: const Value(26.0),
          humidity: const Value(52.0),
          eco2: const Value(550),
          tvoc: const Value(120),
          aqi: const Value(2),
        ),
        TelemetryRecordsCompanion.insert(
          deviceId: 'lat-01',
          timestamp: t3,
          temperature: const Value(27.0),
          humidity: const Value(55.0),
          eco2: const Value(600),
          tvoc: const Value(150),
          aqi: const Value(2),
        ),
      ]);

      expect(await db.telemetryDao.countAllTelemetry(), 3);
      expect(await db.telemetryDao.countTelemetryForDevice('lat-01'), 3);
      expect(await db.telemetryDao.countTelemetryForDevice('unknown'), 0);
      expect(await db.telemetryDao.getOldestTimestamp(), t1);
      expect(await db.telemetryDao.getNewestTimestamp(), t3);

      final recent = await db.telemetryDao.getRecentRecords('lat-01', limit: 2);
      expect(recent.length, 2);
      expect(recent.first.timestamp, t3);
      expect(recent.last.timestamp, t2);

      final chunk1 = await db.telemetryDao.getTelemetryChunk(limit: 2);
      expect(chunk1.length, 2);
      expect(chunk1.first.timestamp, t1);

      final chunk2 = await db.telemetryDao.getTelemetryChunk(
        afterTimestamp: chunk1.last.timestamp,
        limit: 2,
      );
      expect(chunk2.length, 1);
      expect(chunk2.first.timestamp, t3);
    });
  });

  group('RestoreService', () {
    test('RestoreMode.merge inserts entities and ignores duplicates safely',
        () async {
      final restoreService = RestoreService(db);

      final backupJson = {
        'formatVersion': 1,
        'createdAt': '2026-09-21T10:00:00.000Z',
        'sectors': [
          {
            'id': 1,
            'name': 'Warehouse',
            'createdAt': '2026-09-20T08:00:00.000Z'
          }
        ],
        'subSectors': [
          {
            'id': 1,
            'sectorId': 1,
            'name': 'Section 1',
            'createdAt': '2026-09-20T08:05:00.000Z'
          }
        ],
        'devices': [
          {
            'id': 'lat-wh-1',
            'subSectorId': 1,
            'name': 'Warehouse Tester',
            'productType': 'LAT',
            'baseUrl': 'http://192.168.1.100',
            'createdAt': '2026-09-20T08:10:00.000Z',
          }
        ],
        'telemetry': [
          {
            'deviceId': 'lat-wh-1',
            'timestamp': '2026-09-21T09:00:00.000Z',
            'temperature': 24.5,
            'humidity': 60.0,
            'eco2': 450,
            'tvoc': 80,
            'aqi': 1
          },
          {
            'deviceId': 'lat-wh-1',
            'timestamp': '2026-09-21T09:01:00.000Z',
            'temperature': 24.6,
            'humidity': 60.1,
            'eco2': 455,
            'tvoc': 82,
            'aqi': 1
          }
        ]
      };

      final preview = BackupPreview(
        filePath: 'mock.json',
        formatVersion: 1,
        createdAt: DateTime.parse('2026-09-21T10:00:00.000Z'),
        sectorCount: 1,
        subSectorCount: 1,
        deviceCount: 1,
        telemetryCount: 2,
        rawJson: backupJson,
      );

      final inserted = await restoreService.executeRestore(
        preview: preview,
        mode: RestoreMode.merge,
      );

      expect(inserted, 2);
      expect(await db.deviceDao.countAllDevices(), 1);
      expect(await db.telemetryDao.countAllTelemetry(), 2);

      // Re-running merge with duplicate records must remain safe (idempotent)
      final secondRun = await restoreService.executeRestore(
        preview: preview,
        mode: RestoreMode.merge,
      );

      expect(secondRun, 2);
      expect(await db.telemetryDao.countAllTelemetry(), 2);
    });

    test('RestoreMode.replace wipes existing data before importing', () async {
      final restoreService = RestoreService(db);

      // Initial data
      final sId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Old Building')),
      );
      final subId = await db.sectorDao.insertSubSector(
        SubSectorsCompanion(
            sectorId: Value(sId), name: const Value('Old Room')),
      );
      await db.deviceDao.upsertDevice(
        DevicesCompanion(
          id: const Value('old-dev'),
          subSectorId: Value(subId),
          name: const Value('Old Device'),
          productType: const Value('LAT'),
          baseUrl: const Value('http://192.168.1.99'),
        ),
      );

      expect(await db.deviceDao.countAllDevices(), 1);

      final backupJson = {
        'formatVersion': 1,
        'createdAt': '2026-09-21T12:00:00.000Z',
        'sectors': [
          {
            'id': 10,
            'name': 'New Campus',
            'createdAt': '2026-09-21T12:00:00.000Z'
          }
        ],
        'subSectors': [
          {
            'id': 20,
            'sectorId': 10,
            'name': 'Lab 101',
            'createdAt': '2026-09-21T12:00:00.000Z'
          }
        ],
        'devices': [
          {
            'id': 'new-dev',
            'subSectorId': 20,
            'name': 'New Device',
            'productType': 'LAT',
            'baseUrl': 'http://192.168.1.200',
            'createdAt': '2026-09-21T12:00:00.000Z',
          }
        ],
        'telemetry': []
      };

      final preview = BackupPreview(
        filePath: 'mock.json',
        formatVersion: 1,
        createdAt: DateTime.parse('2026-09-21T12:00:00.000Z'),
        sectorCount: 1,
        subSectorCount: 1,
        deviceCount: 1,
        telemetryCount: 0,
        rawJson: backupJson,
      );

      await restoreService.executeRestore(
        preview: preview,
        mode: RestoreMode.replace,
      );

      final devices = await db.deviceDao.getAllDevices();
      expect(devices.length, 1);
      expect(devices.first.id, 'new-dev');
      expect(devices.first.name, 'New Device');

      final sectors = await db.sectorDao.getAllSectors();
      expect(sectors.length, 1);
      expect(sectors.first.name, 'New Campus');
    });
  });
}
