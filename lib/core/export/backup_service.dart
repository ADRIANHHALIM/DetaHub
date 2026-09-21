// lib/core/export/backup_service.dart
//
// Complete local DetaHub backup service.
// Generates a versioned, portable JSON archive of the entire local database.
// Uses streaming chunked writes to guarantee memory safety for large datasets.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/daos/device_dao.dart';
import '../database/daos/sector_dao.dart';
import '../database/daos/telemetry_dao.dart';

class BackupService {
  final SectorDao _sectorDao;
  final DeviceDao _deviceDao;
  final TelemetryDao _telemetryDao;

  BackupService({
    required SectorDao sectorDao,
    required DeviceDao deviceDao,
    required TelemetryDao telemetryDao,
  })  : _sectorDao = sectorDao,
        _deviceDao = deviceDao,
        _telemetryDao = telemetryDao;

  /// Creates a full local backup JSON file and opens the platform share sheet.
  Future<String> createBackup({
    void Function(int recordsProcessed)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final dateSlug =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final filePath = '${tempDir.path}/detahub_backup_$dateSlug.json';
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    final sink = file.openWrite(mode: FileMode.write);

    // 1. Write Header & Metadata
    sink.write('{\n');
    sink.write('  "formatVersion": 1,\n');
    sink.write('  "createdAt": "${now.toUtc().toIso8601String()}",\n');

    // 2. Write Sectors
    final sectors = await _sectorDao.getAllSectors();
    final sectorsJson = sectors
        .map((s) => {
              'id': s.id,
              'name': s.name,
              'createdAt': s.createdAt.toUtc().toIso8601String(),
            })
        .toList();
    sink.write('  "sectors": ${jsonEncode(sectorsJson)},\n');

    // 3. Write SubSectors
    final subSectors = await _sectorDao.getAllSubSectors();
    final subSectorsJson = subSectors
        .map((ss) => {
              'id': ss.id,
              'sectorId': ss.sectorId,
              'name': ss.name,
              'createdAt': ss.createdAt.toUtc().toIso8601String(),
            })
        .toList();
    sink.write('  "subSectors": ${jsonEncode(subSectorsJson)},\n');

    // 4. Write Devices
    final devices = await _deviceDao.getAllDevices();
    final devicesJson = devices
        .map((d) => {
              'id': d.id,
              'subSectorId': d.subSectorId,
              'name': d.name,
              'productType': d.productType,
              'baseUrl': d.baseUrl,
              'createdAt': d.createdAt.toUtc().toIso8601String(),
              'lastSeenAt': d.lastSeenAt?.toUtc().toIso8601String(),
            })
        .toList();
    sink.write('  "devices": ${jsonEncode(devicesJson)},\n');

    // 5. Stream Telemetry array chunk by chunk
    sink.write('  "telemetry": [\n');

    DateTime? lastTimestamp;
    int totalTelemetry = 0;
    bool isFirst = true;
    const chunkSize = 1000;

    while (true) {
      final chunk = await _telemetryDao.getTelemetryChunk(
        afterTimestamp: lastTimestamp,
        limit: chunkSize,
      );

      if (chunk.isEmpty) break;

      for (final record in chunk) {
        if (!isFirst) {
          sink.write(',\n');
        } else {
          isFirst = false;
        }

        final recordMap = {
          'deviceId': record.deviceId,
          'timestamp': record.timestamp.toUtc().toIso8601String(),
          'temperature': record.temperature,
          'humidity': record.humidity,
          'eco2': record.eco2,
          'tvoc': record.tvoc,
          'aqi': record.aqi,
        };
        sink.write('    ${jsonEncode(recordMap)}');
      }

      totalTelemetry += chunk.length;
      onProgress?.call(totalTelemetry);

      lastTimestamp = chunk.last.timestamp;
      if (chunk.length < chunkSize) break;
    }

    sink.write('\n  ]\n');
    sink.write('}\n');

    await sink.flush();
    await sink.close();

    // Trigger platform native save/share
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'application/json')],
      subject: 'DetaHub Backup ($dateSlug)',
      text:
          'DetaHub local backup: ${sectors.length} sectors, ${devices.length} devices, $totalTelemetry telemetry records.',
    );

    return filePath;
  }
}

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    sectorDao: ref.watch(sectorDaoProvider),
    deviceDao: ref.watch(deviceDaoProvider),
    telemetryDao: ref.watch(telemetryDaoProvider),
  );
});
