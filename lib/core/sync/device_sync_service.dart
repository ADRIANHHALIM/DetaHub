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
        .where((f) => DeviceFile.normalizeFileName(f.name).endsWith('.csv'))
        .toList();

    csvFiles.sort((a, b) {
      final da = DeviceFile.parseDateFromFileName(a.name) ?? a.date;
      final db = DeviceFile.parseDateFromFileName(b.name) ?? b.date;
      if (da != null && db != null) {
        return da.compareTo(db);
      }
      if (da != null) return -1;
      if (db != null) return 1;
      return DeviceFile.normalizeFileName(a.name)
          .compareTo(DeviceFile.normalizeFileName(b.name));
    });

    int filesProcessed = 0;
    int filesSkipped = 0;
    int filesFailed = 0;
    int totalRecordsRead = 0;
    int totalRecordsInserted = 0;
    int totalRecordsIgnored = 0;
    int totalRecordsRejected = 0;
    final preservedFiles = <String>[];
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
        preservedFiles.add(file.name);
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

      // 3c. Persist valid records in bounded transactional chunks (COUNT before/after optimization)
      bool persistenceFailed = false;
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

        try {
          final companions =
              validRecords.map((r) => r.toCompanion(deviceId)).toList();
          final inserted = await _telemetryDao.insertFileRecordsWithCount(
            deviceId,
            companions,
            chunkSize: 500,
          );
          totalRecordsInserted += inserted;
          totalRecordsIgnored += (validRecords.length - inserted);
        } catch (e) {
          persistenceFailed = true;
          filesFailed++;
          preservedFiles.add(file.name);
          errors.add('Database error persisting ${file.name}: $e');
          continue;
        }
      }

      filesProcessed++;

      // 3d. Safe acknowledgement check:
      // A file is eligible for deletion ONLY if ALL of the following are true:
      // 1. canDelete (historical, strictly before today, not activeFileName)
      // 2. Zero invalid records reported by parser (invalidCount == 0)
      // 3. SQLite persistence succeeded without error (!persistenceFailed)
      //
      // If ANY row is invalid: valid records are persisted, but source file MUST be preserved!
      final isSafeToDelete =
          canDelete && !persistenceFailed && parseResult.invalidCount == 0;

      if (isSafeToDelete) {
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
          // Deletion failed or unconfirmed (e.g. 404/500/timeout):
          // SQLite data is safe, mark delete failed, preserve source for retry
          failedDeletes.add(file.name);
          preservedFiles.add(file.name);
          errors.add(
              'Failed to delete ${file.name} from ESP32: ${deleteResult.error}');
        }
      } else {
        // File preserved for safety (e.g. active file, undated, or contained invalid records)
        preservedFiles.add(file.name);
        if (!canDelete) {
          filesSkipped++;
        }
      }
    }

    final completedAt = DateTime.now();
    final SyncStatus status;
    if (filesFailed > 0 && filesProcessed == 0 && totalRecordsInserted == 0) {
      status = SyncStatus.failed;
    } else if (filesFailed > 0 ||
        failedDeletes.isNotEmpty ||
        totalRecordsRejected > 0 ||
        preservedFiles.isNotEmpty) {
      status = SyncStatus.partial;
    } else {
      status = SyncStatus.success;
    }

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
      preservedFiles: preservedFiles,
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
