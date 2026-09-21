// lib/core/export/csv_export_service.dart
//
// Centralized, memory-safe CSV export service for DetaHub.
// Streams data in chunks (LIMIT 1000) directly to disk to prevent OOM
// on large hardware telemetry datasets. Strictly local-first.

import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/daos/device_dao.dart';
import '../database/daos/sector_dao.dart';
import '../database/daos/telemetry_dao.dart';

class CsvExportService {
  final TelemetryDao _telemetryDao;
  final DeviceDao _deviceDao;
  final SectorDao _sectorDao;

  CsvExportService({
    required TelemetryDao telemetryDao,
    required DeviceDao deviceDao,
    required SectorDao sectorDao,
  })  : _telemetryDao = telemetryDao,
        _deviceDao = deviceDao,
        _sectorDao = sectorDao;

  /// Exports all telemetry records across all devices to a single CSV file.
  /// Uses streaming chunked reads (1000 rows at a time) to guarantee memory safety.
  Future<String> exportAllTelemetry({
    void Function(int rowsExported)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final dateSlug =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final filePath = '${tempDir.path}/detahub_export_all_$dateSlug.csv';
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    final sink = file.openWrite(mode: FileMode.write);

    // Build device lookup map to enrich rows with hierarchy data
    final devices = await _deviceDao.getAllDevices();
    final deviceMap = {for (final d in devices) d.id: d};

    final sectors = await _sectorDao.getAllSectors();
    final sectorMap = {for (final s in sectors) s.id: s.name};

    final subSectors = await _sectorDao.getAllSubSectors();
    final subSectorMap = {for (final ss in subSectors) ss.id: ss};

    // Header row
    const converter = ListToCsvConverter();
    final header = [
      'Sector',
      'SubSector',
      'DeviceId',
      'DeviceName',
      'ProductType',
      'Timestamp',
      'Temperature',
      'Humidity',
      'eCO2',
      'TVOC',
      'AQI',
    ];
    sink.writeln(converter.convert([header]));

    DateTime? lastTimestamp;
    int totalExported = 0;
    const chunkSize = 1000;

    while (true) {
      final chunk = await _telemetryDao.getTelemetryChunk(
        afterTimestamp: lastTimestamp,
        limit: chunkSize,
      );

      if (chunk.isEmpty) break;

      final rows = <List<dynamic>>[];
      for (final record in chunk) {
        final device = deviceMap[record.deviceId];
        final subSector =
            device != null ? subSectorMap[device.subSectorId] : null;
        final sectorName =
            subSector != null ? sectorMap[subSector.sectorId] ?? '' : '';
        final subSectorName = subSector?.name ?? '';

        rows.add([
          sectorName,
          subSectorName,
          record.deviceId,
          device?.name ?? record.deviceId,
          device?.productType ?? 'LAT',
          record.timestamp.toIso8601String(),
          record.temperature ?? '',
          record.humidity ?? '',
          record.eco2 ?? '',
          record.tvoc ?? '',
          record.aqi ?? '',
        ]);
      }

      sink.writeln(converter.convert(rows));
      totalExported += chunk.length;
      onProgress?.call(totalExported);

      lastTimestamp = chunk.last.timestamp;
      if (chunk.length < chunkSize) break;
    }

    await sink.flush();
    await sink.close();

    // Trigger platform native share
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv')],
      subject: 'DetaHub Telemetry Export (All Data)',
      text: 'Export of $totalExported local telemetry records from DetaHub.',
    );

    return filePath;
  }

  /// Exports telemetry for a specific [deviceId] into a targeted CSV file.
  /// Uses streaming chunked reads to prevent memory spikes.
  Future<String> exportDeviceTelemetry(
    String deviceId, {
    void Function(int rowsExported)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final now = DateTime.now();
    final dateSlug =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final sanitizedId = deviceId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final filePath =
        '${tempDir.path}/detahub_export_${sanitizedId}_$dateSlug.csv';
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    final sink = file.openWrite(mode: FileMode.write);

    final device = await _deviceDao.getDeviceById(deviceId);
    final deviceName = device?.name ?? deviceId;
    final productType = device?.productType ?? 'LAT';

    const converter = ListToCsvConverter();
    final header = [
      'DeviceId',
      'DeviceName',
      'ProductType',
      'Timestamp',
      'Temperature',
      'Humidity',
      'eCO2',
      'TVOC',
      'AQI',
    ];
    sink.writeln(converter.convert([header]));

    DateTime? lastTimestamp;
    int totalExported = 0;
    const chunkSize = 1000;

    while (true) {
      final chunk = await _telemetryDao.getTelemetryChunk(
        deviceId: deviceId,
        afterTimestamp: lastTimestamp,
        limit: chunkSize,
      );

      if (chunk.isEmpty) break;

      final rows = <List<dynamic>>[];
      for (final record in chunk) {
        rows.add([
          record.deviceId,
          deviceName,
          productType,
          record.timestamp.toIso8601String(),
          record.temperature ?? '',
          record.humidity ?? '',
          record.eco2 ?? '',
          record.tvoc ?? '',
          record.aqi ?? '',
        ]);
      }

      sink.writeln(converter.convert(rows));
      totalExported += chunk.length;
      onProgress?.call(totalExported);

      lastTimestamp = chunk.last.timestamp;
      if (chunk.length < chunkSize) break;
    }

    await sink.flush();
    await sink.close();

    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv')],
      subject: 'DetaHub Telemetry — $deviceName',
      text: 'Export of $totalExported local telemetry records for $deviceName.',
    );

    return filePath;
  }
}

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService(
    telemetryDao: ref.watch(telemetryDaoProvider),
    deviceDao: ref.watch(deviceDaoProvider),
    sectorDao: ref.watch(sectorDaoProvider),
  );
});
