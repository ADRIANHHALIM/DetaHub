// lib/core/sync/device_sync_service.dart
//
// Production-grade local-first telemetry reconciliation engine.
// Implements safe offline sync between DetaHub mobile and ESP32 edge buffers:
//   - Single-flight guarantee per device (no concurrent sync races)
//   - Chronological sync order (oldest historical file first)
//   - Memory-safe chunked parsing & transactional persistence
//   - Idempotent duplicate rejection via UNIQUE(device_id, timestamp)
//   - Strict deletion safety: NEVER delete before persistence is verified
//   - Active log protection: NEVER delete today's or active write files

import 'dart:async';

import '../database/daos/telemetry_dao.dart';
import '../network/device_api_service.dart';
import '../network/models/device_file.dart';
import 'csv/telemetry_csv_parser.dart';
import 'models/sync_result.dart';
import 'models/sync_state.dart';

/// Service orchestrating offline historical telemetry synchronization for devices.
class DeviceSyncService {
  final DeviceApiService _apiService;
  final TelemetryDao _telemetryDao;
  final TelemetryCsvParser _csvParser;

  /// In-flight reconciliation futures mapped by deviceId (single-flight guarantee).
  final Map<String, Future<SyncResult>> _inFlightSyncs = {};

  /// Current sync states mapped by deviceId.
  final Map<String, SyncState> _currentStates = {};

  /// Reactive stream controllers for sync state updates.
  final Map<String, StreamController<SyncState>> _stateControllers = {};

  DeviceSyncService({
    required DeviceApiService apiService,
    required TelemetryDao telemetryDao,
    TelemetryCsvParser csvParser = const TelemetryCsvParser(),
  })  : _apiService = apiService,
        _telemetryDao = telemetryDao,
        _csvParser = csvParser;

  /// Current sync state for a device.
  SyncState getSyncState(String deviceId) =>
      _currentStates[deviceId] ?? const SyncIdle();

  /// Reactive stream of sync state changes for a device.
  Stream<SyncState> watchSyncState(String deviceId) {
    _stateControllers[deviceId] ??= StreamController<SyncState>.broadcast();
    return _stateControllers[deviceId]!.stream;
  }

  void _updateState(String deviceId, SyncState state) {
    _currentStates[deviceId] = state;
    if (_stateControllers.containsKey(deviceId)) {
      _stateControllers[deviceId]!.add(state);
    }
  }

  /// Reconciles all pending historical telemetry files from an ESP32 device.
  ///
  /// Guarantees that only ONE sync operation can execute for [deviceId] at any time.
  /// If an operation is already in flight, returns the existing future.
  Future<SyncResult> reconcileDevice({
    required String deviceId,
    required String baseUrl,
    String? activeFileName,
    DateTime? referenceTime,
  }) {
    if (_inFlightSyncs.containsKey(deviceId)) {
      return _inFlightSyncs[deviceId]!;
    }

    final future = _executeReconcile(
      deviceId: deviceId,
      baseUrl: baseUrl,
      activeFileName: activeFileName,
      referenceTime: referenceTime ?? DateTime.now(),
    );

    _inFlightSyncs[deviceId] = future;
    return future.whenComplete(() {
      _inFlightSyncs.remove(deviceId);
    });
  }

  Future<SyncResult> _executeReconcile({
    required String deviceId,
    required String baseUrl,
    required String? activeFileName,
    required DateTime referenceTime,
  }) async {
    final startedAt = DateTime.now();
    _updateState(deviceId, const SyncDiscovering());

    // 1. Discover files on ESP32
    final listResult = await _apiService.listFiles(baseUrl);
    if (listResult.isErr) {
      final error = listResult.error;
      final failedResult = SyncResult(
        deviceId: deviceId,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        status: SyncStatus.failed,
        errors: [error.toString()],
      );
      _updateState(
        deviceId,
        SyncFailed(
          message: 'Failed to list files from device',
          networkError: error,
          partialResult: failedResult,
        ),
      );
      return failedResult;
    }

    final allFiles = listResult.value;
    if (allFiles.isEmpty) {
      final emptyResult = SyncResult(
        deviceId: deviceId,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        status: SyncStatus.noFiles,
      );
      _updateState(deviceId, SyncCompleted(emptyResult));
      return emptyResult;
    }

    // 2. Filter CSV files and sort chronologically (oldest first)
    final csvFiles = allFiles
        .where((f) => f.name.toLowerCase().endsWith('.csv'))
        .toList();

    csvFiles.sort((a, b) {
      final da = a.date ?? DeviceFile.parseDateFromFileName(a.name);
      final db = b.date ?? DeviceFile.parseDateFromFileName(b.name);
      if (da != null && db != null) {
        return da.compareTo(db);
      }
      return a.name.compareTo(b.name);
    });

    int filesProcessed = 0;
    int filesSkipped = 0;
    int filesFailed = 0;
    int totalRecordsRead = 0;
    int totalRecordsInserted = 0;
    int totalRecordsIgnored = 0;
    int totalRecordsRejected = 0;
    final deletedFiles = <String>[];
    final failedDeletes = <String>[];
    final errors = <String>[];

    final totalFiles = csvFiles.length;

    // 3. Process each file sequentially
    for (int i = 0; i < totalFiles; i++) {
      final file = csvFiles[i];
      final fileIndex = i + 1;

      // Check if file is safe to delete after sync (closed historical vs active)
      final canDelete = file.isEligibleForDeletion(
        activeFileName: activeFileName,
        referenceTime: referenceTime,
      );

      // 3a. Download file
      _updateState(
        deviceId,
        SyncDownloading(
          fileName: file.name,
          fileIndex: fileIndex,
          totalFiles: totalFiles,
        ),
      );

      final downloadResult = await _apiService.downloadFile(baseUrl, file.name);
      if (downloadResult.isErr) {
        filesFailed++;
        errors.add('Failed to download ${file.name}: ${downloadResult.error}');
        continue;
      }

      final csvContent = downloadResult.value;

      // 3b. Parse and validate CSV rows
      _updateState(
        deviceId,
        SyncParsing(
          fileName: file.name,
          fileIndex: fileIndex,
          totalFiles: totalFiles,
        ),
      );

      final parseResult = _csvParser.parseString(csvContent);
      totalRecordsRead += parseResult.totalRowsRead;
      totalRecordsRejected += parseResult.invalidCount;

      final validRecords = parseResult.validRecords;

      // 3c. Persist in bounded transactional chunks
      if (validRecords.isNotEmpty) {
        _updateState(
          deviceId,
          SyncPersisting(
            fileName: file.name,
            recordsCount: validRecords.length,
            fileIndex: fileIndex,
            totalFiles: totalFiles,
          ),
        );

        bool persistenceFailed = false;
        const chunkSize = 500;
        final chunks = TelemetryCsvParser.chunkList(validRecords, chunkSize);

        for (final chunk in chunks) {
          try {
            final companions = chunk.map((r) => r.toCompanion(deviceId)).toList();
            final inserted = await _telemetryDao.batchInsertRecordsWithCount(
              deviceId,
              companions,
            );
            totalRecordsInserted += inserted;
            totalRecordsIgnored += (chunk.length - inserted);
          } catch (e) {
            persistenceFailed = true;
            errors.add('Database error persisting ${file.name}: $e');
            break;
          }
        }

        // CRITICAL DATA-SAFETY RULE:
        // If SQLite persistence fails, DO NOT delete the ESP32 file!
        if (persistenceFailed) {
          filesFailed++;
          continue;
        }
      }

      filesProcessed++;

      // 3d. Delete acknowledged file ONLY if eligible (historical & not active)
      if (canDelete) {
        _updateState(
          deviceId,
          SyncDeleting(
            fileName: file.name,
            fileIndex: fileIndex,
            totalFiles: totalFiles,
          ),
        );

        final deleteResult = await _apiService.deleteFile(baseUrl, file.name);
        if (deleteResult.isOk) {
          deletedFiles.add(file.name);
        } else {
          // Deletion failed on ESP32, but SQLite data is safe!
          // Next reconciliation will simply re-sync and ignore duplicates.
          failedDeletes.add(file.name);
          errors.add('Failed to delete ${file.name} from ESP32: ${deleteResult.error}');
        }
      } else {
        filesSkipped++;
      }
    }

    final completedAt = DateTime.now();
    final status = filesFailed > 0
        ? SyncStatus.partial
        : SyncStatus.success;

    final result = SyncResult(
      deviceId: deviceId,
      startedAt: startedAt,
      completedAt: completedAt,
      filesDiscovered: totalFiles,
      filesProcessed: filesProcessed,
      filesSkipped: filesSkipped,
      filesFailed: filesFailed,
      recordsRead: totalRecordsRead,
      recordsInserted: totalRecordsInserted,
      recordsIgnored: totalRecordsIgnored,
      recordsRejected: totalRecordsRejected,
      deletedFiles: deletedFiles,
      failedDeletes: failedDeletes,
      status: status,
      errors: errors,
    );

    _updateState(deviceId, SyncCompleted(result));
    return result;
  }

  void dispose() {
    for (final controller in _stateControllers.values) {
      controller.close();
    }
    _stateControllers.clear();
  }
}
