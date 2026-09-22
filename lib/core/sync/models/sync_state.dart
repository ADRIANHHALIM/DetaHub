// lib/core/sync/models/sync_state.dart
//
// Typed synchronization state machine for DetaHub offline reconciliation.
// Cleanly maps every phase of discovery, transfer, parsing, persistence,
// and safe edge deletion.

import '../../network/network_error.dart';
import 'sync_result.dart';

/// Sealed hierarchy representing the current phase of a device reconciliation job.
sealed class SyncState {
  const SyncState();

  bool get isRunning =>
      this is SyncDiscovering ||
      this is SyncDownloading ||
      this is SyncParsing ||
      this is SyncPersisting ||
      this is SyncDeleting;
}

/// No active synchronization in progress.
class SyncIdle extends SyncState {
  const SyncIdle();
}

/// Querying ESP32 `/listfiles` to identify historical logs.
class SyncDiscovering extends SyncState {
  const SyncDiscovering();
}

/// Downloading a specific CSV file from ESP32 flash memory.
class SyncDownloading extends SyncState {
  final String fileName;
  final int fileIndex;
  final int totalFiles;

  const SyncDownloading({
    required this.fileName,
    required this.fileIndex,
    required this.totalFiles,
  });
}

/// Parsing CSV rows and validating telemetry fields.
class SyncParsing extends SyncState {
  final String fileName;
  final int fileIndex;
  final int totalFiles;

  const SyncParsing({
    required this.fileName,
    required this.fileIndex,
    required this.totalFiles,
  });
}

/// Persisting valid telemetry records into Drift SQLite in transaction chunks.
class SyncPersisting extends SyncState {
  final String fileName;
  final int recordsCount;
  final int fileIndex;
  final int totalFiles;

  const SyncPersisting({
    required this.fileName,
    required this.recordsCount,
    required this.fileIndex,
    required this.totalFiles,
  });
}

/// Sending delete request to ESP32 after SQLite persistence was verified.
class SyncDeleting extends SyncState {
  final String fileName;
  final int fileIndex;
  final int totalFiles;

  const SyncDeleting({
    required this.fileName,
    required this.fileIndex,
    required this.totalFiles,
  });
}

/// Reconciliation finished successfully (or partially with safe completion).
class SyncCompleted extends SyncState {
  final SyncResult result;
  const SyncCompleted(this.result);
}

/// Reconciliation encountered an unrecoverable failure.
class SyncFailed extends SyncState {
  final String message;
  final NetworkError? networkError;
  final SyncResult? partialResult;

  const SyncFailed({
    required this.message,
    this.networkError,
    this.partialResult,
  });
}
