// lib/core/export/restore_service.dart
//
// Local database restore service for DetaHub.
// Validates backup JSON integrity, provides pre-restore entity counts,
// and supports both Merge (safe, additive) and Replace (destructive) modes.

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';

enum RestoreMode {
  merge,
  replace,
}

class BackupPreview {
  final String filePath;
  final int formatVersion;
  final DateTime createdAt;
  final int sectorCount;
  final int subSectorCount;
  final int deviceCount;
  final int telemetryCount;
  final Map<String, dynamic> rawJson;

  const BackupPreview({
    required this.filePath,
    required this.formatVersion,
    required this.createdAt,
    required this.sectorCount,
    required this.subSectorCount,
    required this.deviceCount,
    required this.telemetryCount,
    required this.rawJson,
  });
}

class RestoreService {
  final AppDatabase _db;

  RestoreService(this._db);

  /// Opens native file picker to select a backup JSON file and returns a validated preview.
  /// Throws a human-readable [FormatException] if the file is invalid or corrupted.
  Future<BackupPreview?> pickAndValidateBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) return null;

    final path = result.files.single.path;
    if (path == null) {
      throw const FormatException('Selected file path is inaccessible.');
    }

    final file = File(path);
    if (!await file.exists()) {
      throw const FormatException('Selected file does not exist on disk.');
    }

    final content = await file.readAsString();
    dynamic decoded;
    try {
      decoded = jsonDecode(content);
    } catch (_) {
      throw const FormatException(
          'The selected file is not a valid JSON document.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Invalid backup structure. Expected root JSON object.');
    }

    final formatVersion = decoded['formatVersion'];
    if (formatVersion == null || formatVersion != 1) {
      throw FormatException(
        'Unsupported backup format version (${formatVersion ?? 'unknown'}). Expected version 1.',
      );
    }

    final createdAtRaw = decoded['createdAt'];
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(createdAtRaw.toString());
    } catch (_) {
      createdAt = DateTime.now();
    }

    final sectorsRaw = decoded['sectors'];
    final subSectorsRaw = decoded['subSectors'];
    final devicesRaw = decoded['devices'];
    final telemetryRaw = decoded['telemetry'];

    final sectorCount = sectorsRaw is List ? sectorsRaw.length : 0;
    final subSectorCount = subSectorsRaw is List ? subSectorsRaw.length : 0;
    final deviceCount = devicesRaw is List ? devicesRaw.length : 0;
    final telemetryCount = telemetryRaw is List ? telemetryRaw.length : 0;

    return BackupPreview(
      filePath: path,
      formatVersion: formatVersion as int,
      createdAt: createdAt,
      sectorCount: sectorCount,
      subSectorCount: subSectorCount,
      deviceCount: deviceCount,
      telemetryCount: telemetryCount,
      rawJson: decoded,
    );
  }

  /// Executes restore using either [RestoreMode.merge] or [RestoreMode.replace].
  Future<int> executeRestore({
    required BackupPreview preview,
    required RestoreMode mode,
    void Function(String step, double progress)? onProgress,
  }) async {
    final raw = preview.rawJson;
    final sectorsList = (raw['sectors'] as List? ?? []);
    final subSectorsList = (raw['subSectors'] as List? ?? []);
    final devicesList = (raw['devices'] as List? ?? []);
    final telemetryList = (raw['telemetry'] as List? ?? []);

    return await _db.transaction(() async {
      // 1. If REPLACE mode, clear all existing data
      if (mode == RestoreMode.replace) {
        onProgress?.call('Clearing existing local database…', 0.05);
        await _db.clearAllData();
      }

      // 2. Restore Sectors
      onProgress?.call('Restoring locations…', 0.15);
      for (final item in sectorsList) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'] as int?;
        final name = item['name'] as String? ?? 'Unnamed Sector';
        final createdAt = item['createdAt'] != null
            ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now();

        await _db.into(_db.sectors).insert(
              SectorsCompanion(
                id: id != null ? Value(id) : const Value.absent(),
                name: Value(name),
                createdAt: Value(createdAt),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      // 3. Restore SubSectors
      onProgress?.call('Restoring areas…', 0.30);
      for (final item in subSectorsList) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'] as int?;
        final sectorId = item['sectorId'] as int? ?? 1;
        final name = item['name'] as String? ?? 'Unnamed Area';
        final createdAt = item['createdAt'] != null
            ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now();

        await _db.into(_db.subSectors).insert(
              SubSectorsCompanion(
                id: id != null ? Value(id) : const Value.absent(),
                sectorId: Value(sectorId),
                name: Value(name),
                createdAt: Value(createdAt),
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }

      // 4. Restore Devices
      onProgress?.call('Restoring devices…', 0.45);
      for (final item in devicesList) {
        if (item is! Map<String, dynamic>) continue;
        final id = item['id'] as String?;
        if (id == null || id.isEmpty) continue;
        final subSectorId = item['subSectorId'] as int? ?? 1;
        final name = item['name'] as String? ?? id;
        final productType = item['productType'] as String? ?? 'LAT';
        final baseUrl = item['baseUrl'] as String? ?? 'http://localhost';
        final createdAt = item['createdAt'] != null
            ? DateTime.tryParse(item['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now();
        final lastSeenAt = item['lastSeenAt'] != null
            ? DateTime.tryParse(item['lastSeenAt'].toString())
            : null;

        await _db.into(_db.devices).insert(
              DevicesCompanion(
                id: Value(id),
                subSectorId: Value(subSectorId),
                name: Value(name),
                productType: Value(productType),
                baseUrl: Value(baseUrl),
                createdAt: Value(createdAt),
                lastSeenAt: Value(lastSeenAt),
              ),
              mode: InsertMode.insertOrReplace,
            );
      }

      // 5. Restore Telemetry in batches of 500
      onProgress?.call('Restoring telemetry records…', 0.60);
      var insertedTelemetry = 0;
      final batchCompanions = <TelemetryRecordsCompanion>[];

      for (var i = 0; i < telemetryList.length; i++) {
        final item = telemetryList[i];
        if (item is! Map<String, dynamic>) continue;

        final deviceId = item['deviceId'] as String?;
        final timestampRaw = item['timestamp'];
        if (deviceId == null || timestampRaw == null) continue;

        final timestamp = DateTime.tryParse(timestampRaw.toString());
        if (timestamp == null) continue;

        double? toDouble(dynamic val) => val is num
            ? val.toDouble()
            : double.tryParse(val?.toString() ?? '');
        int? toInt(dynamic val) =>
            val is num ? val.toInt() : int.tryParse(val?.toString() ?? '');

        batchCompanions.add(
          TelemetryRecordsCompanion.insert(
            deviceId: deviceId,
            timestamp: timestamp,
            temperature: Value(toDouble(item['temperature'])),
            humidity: Value(toDouble(item['humidity'])),
            eco2: Value(toInt(item['eco2'])),
            tvoc: Value(toInt(item['tvoc'])),
            aqi: Value(toInt(item['aqi'])),
          ),
        );

        if (batchCompanions.length >= 500) {
          await _db.telemetryDao.batchInsertRecords(batchCompanions);
          insertedTelemetry += batchCompanions.length;
          batchCompanions.clear();

          final progress = 0.60 +
              (0.38 * (i / telemetryList.length.clamp(1, double.infinity)));
          onProgress?.call(
            'Importing telemetry ($insertedTelemetry / ${telemetryList.length})…',
            progress,
          );
        }
      }

      if (batchCompanions.isNotEmpty) {
        await _db.telemetryDao.batchInsertRecords(batchCompanions);
        insertedTelemetry += batchCompanions.length;
      }

      onProgress?.call('Restore complete', 1.0);
      return insertedTelemetry;
    });
  }
}

final restoreServiceProvider = Provider<RestoreService>((ref) {
  return RestoreService(ref.watch(appDatabaseProvider));
});
