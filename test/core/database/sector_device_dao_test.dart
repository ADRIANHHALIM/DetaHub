// test/core/database/sector_device_dao_test.dart
//
// In-memory SQLite tests for SectorDao and DeviceDao.
// Verifies hierarchical CRUD, foreign key cascading, and reactive queries.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:detahub/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SectorDao', () {
    test('insertSector and watchAllSectors', () async {
      final sectorId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Gedung Utama')),
      );

      expect(sectorId, isPositive);

      final sectors = await db.sectorDao.watchAllSectors().first;
      expect(sectors.length, 1);
      expect(sectors.first.name, 'Gedung Utama');
    });

    test('insertSubSector and watchSubSectorsForSector', () async {
      final sectorId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Gedung A')),
      );

      final subId = await db.sectorDao.insertSubSector(
        SubSectorsCompanion(
          name: const Value('Lantai 1'),
          sectorId: Value(sectorId),
        ),
      );

      expect(subId, isPositive);

      final subs =
          await db.sectorDao.watchSubSectorsForSector(sectorId).first;
      expect(subs.length, 1);
      expect(subs.first.name, 'Lantai 1');
      expect(subs.first.sectorId, sectorId);
    });

    test('deleteSector cascades to sub-sectors', () async {
      final sectorId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Gedung B')),
      );

      await db.sectorDao.insertSubSector(
        SubSectorsCompanion(
          name: const Value('Lab IoT'),
          sectorId: Value(sectorId),
        ),
      );

      // Foreign keys are enabled in migration beforeOpen
      await db.sectorDao.deleteSector(sectorId);

      final sectors = await db.sectorDao.watchAllSectors().first;
      expect(sectors, isEmpty);

      final subs =
          await db.sectorDao.watchSubSectorsForSector(sectorId).first;
      expect(subs, isEmpty);
    });

    test('watchFullHierarchy aggregates sectors and sub-sectors with device counts',
        () async {
      final sectorId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Pabrik')),
      );

      final subId = await db.sectorDao.insertSubSector(
        SubSectorsCompanion(
          name: const Value('Line Produksi 1'),
          sectorId: Value(sectorId),
        ),
      );

      // Add a device
      await db.deviceDao.upsertDevice(
        DevicesCompanion(
          id: const Value('lat-prod-01'),
          name: const Value('Sensor Udara 1'),
          baseUrl: const Value('http://192.168.1.100'),
          productType: const Value('LAT'),
          subSectorId: Value(subId),
        ),
      );

      final hierarchy = await db.sectorDao.watchFullHierarchy().first;
      expect(hierarchy.length, 1);
      expect(hierarchy.first.sector.name, 'Pabrik');
      expect(hierarchy.first.subSectors.length, 1);
      expect(hierarchy.first.subSectors.first.subSector.name, 'Line Produksi 1');
      expect(hierarchy.first.subSectors.first.deviceCount, 1);
    });
  });

  group('DeviceDao', () {
    test('upsertDevice, getDeviceById, and deleteDevice', () async {
      final sectorId = await db.sectorDao.insertSector(
        const SectorsCompanion(name: Value('Kampus')),
      );

      final subId = await db.sectorDao.insertSubSector(
        SubSectorsCompanion(
          name: const Value('Ruang Server'),
          sectorId: Value(sectorId),
        ),
      );

      await db.deviceDao.upsertDevice(
        DevicesCompanion(
          id: const Value('lat-srv-01'),
          name: const Value('LAT Server Room'),
          baseUrl: const Value('http://192.168.1.55'),
          productType: const Value('LAT'),
          subSectorId: Value(subId),
        ),
      );

      final device = await db.deviceDao.getDeviceById('lat-srv-01');
      expect(device, isNotNull);
      expect(device!.name, 'LAT Server Room');
      expect(device.baseUrl, 'http://192.168.1.55');

      // Update URL via upsert
      await db.deviceDao.upsertDevice(
        DevicesCompanion(
          id: const Value('lat-srv-01'),
          name: const Value('LAT Server Room'),
          baseUrl: const Value('http://192.168.1.99'),
          productType: const Value('LAT'),
          subSectorId: Value(subId),
        ),
      );

      final updated = await db.deviceDao.getDeviceById('lat-srv-01');
      expect(updated!.baseUrl, 'http://192.168.1.99');

      // Delete device
      final deletedCount = await db.deviceDao.deleteDevice('lat-srv-01');
      expect(deletedCount, 1);

      final afterDelete = await db.deviceDao.getDeviceById('lat-srv-01');
      expect(afterDelete, isNull);
    });
  });
}
