// lib/core/sync/models/sync_result.dart
//
// Structured synchronization audit result tracking all reconciliation metrics.

enum SyncStatus {
  success,
  partial,
  failed,
  noFiles,
}

/// Comprehensive summary of a completed or partial reconciliation run.
class SyncResult {
  final String deviceId;
  final DateTime startedAt;
  final DateTime completedAt;
  final int filesDiscovered;
  final int filesProcessed;
  final int filesSkipped;
  final int filesFailed;
  final int recordsRead;
  final int recordsInserted;
  final int recordsIgnored;
  final int recordsRejected;
  final List<String> preservedFiles;
  final List<String> deletedFiles;
  final List<String> failedDeletes;
  final SyncStatus status;
  final List<String> errors;

  const SyncResult({
    required this.deviceId,
    required this.startedAt,
    required this.completedAt,
    this.filesDiscovered = 0,
    this.filesProcessed = 0,
    this.filesSkipped = 0,
    this.filesFailed = 0,
    this.recordsRead = 0,
    this.recordsInserted = 0,
    this.recordsIgnored = 0,
    this.recordsRejected = 0,
    this.preservedFiles = const [],
    this.deletedFiles = const [],
    this.failedDeletes = const [],
    this.status = SyncStatus.success,
    this.errors = const [],
  });

  int get filesPreserved => preservedFiles.length;
  Duration get duration => completedAt.difference(startedAt);

  bool get isCleanSuccess =>
      status == SyncStatus.success &&
      filesFailed == 0 &&
      failedDeletes.isEmpty &&
      recordsRejected == 0 &&
      preservedFiles.isEmpty;

  @override
  String toString() =>
      'SyncResult(device: $deviceId, status: $status, files: $filesProcessed/$filesDiscovered, '
      'inserted: $recordsInserted, ignored: $recordsIgnored, rejected: $recordsRejected, '
      'preserved: ${preservedFiles.length}, deleted: ${deletedFiles.length}, failedDeletes: ${failedDeletes.length})';
}
