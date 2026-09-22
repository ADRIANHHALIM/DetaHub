// lib/core/database/daos/telemetry_dao.dart
//
// Data Access Object for TelemetryRecords — the hot path of the application.
// Optimized for:
//   1. High-throughput batch insert (CSV sync: up to 1440 rows at a time)
//      with ON CONFLICT IGNORE deduplication via the unique (device_id, timestamp)
//      composite index defined in TelemetryRecordsTable.
//   2. Reactive latest-value stream for the live dashboard.
//   3. Time-range queries for chart data (pre-downsampling by LTTB).
//   4. Daily aggregation queries (min/max/avg) for the summary view.

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_database.dart';
import '../tables/telemetry_records_table.dart';

part 'telemetry_dao.g.dart';

// ---------------------------------------------------------------------------
// Aggregate Result DTO
// ---------------------------------------------------------------------------

/// Holds daily min / max / avg values for a single metric.
class MetricAggregate {
  final double? min;
  final double? max;
  final double? avg;

  const MetricAggregate({this.min, this.max, this.avg});

  @override
  String toString() => 'MetricAggregate(min: $min, max: $max, avg: $avg)';
}

/// Complete daily aggregation result for all metrics of one device.
class DailyAggregate {
  final DateTime date;
  final MetricAggregate temperature;
  final MetricAggregate humidity;
  final MetricAggregate eco2;
  final MetricAggregate tvoc;
  final MetricAggregate aqi;
  final int sampleCount;

  const DailyAggregate({
    required this.date,
    required this.temperature,
    required this.humidity,
    required this.eco2,
    required this.tvoc,
    required this.aqi,
    required this.sampleCount,
  });
}

// ---------------------------------------------------------------------------
// DAO
// ---------------------------------------------------------------------------

@DriftAccessor(tables: [TelemetryRecords])
class TelemetryDao extends DatabaseAccessor<AppDatabase>
    with _$TelemetryDaoMixin {
  TelemetryDao(super.db);

  // --- Batch Insert (CSV Sync) ---

  /// Inserts a batch of telemetry records, silently ignoring duplicates.
  ///
  /// Duplicate detection is based on the UNIQUE(device_id, timestamp) index
  /// defined in [TelemetryRecords]. Using [InsertMode.insertOrIgnore] maps
  /// directly to SQLite's `INSERT OR IGNORE`, which skips conflicting rows
  /// without failing the entire batch — critical for CSV re-sync idempotency.
  ///
  /// Wrapped in a transaction for atomic commit and ~10× batch write speedup
  /// compared to individual inserts.
  Future<void> batchInsertRecords(
      List<TelemetryRecordsCompanion> records) async {
    if (records.isEmpty) return;

    await transaction(() async {
      await batch((b) {
        b.insertAll(
          telemetryRecords,
          records,
          mode: InsertMode.insertOrIgnore,
        );
      });
    });
  }

  /// Inserts a batch of telemetry records with [InsertMode.insertOrIgnore] inside
  /// an atomic transaction and returns the exact count of newly inserted records.
  Future<int> batchInsertRecordsWithCount(
    String deviceId,
    List<TelemetryRecordsCompanion> records,
  ) async {
    if (records.isEmpty) return 0;

    return await transaction(() async {
      final beforeCount = await countTelemetryForDevice(deviceId);
      await batch((b) {
        b.insertAll(
          telemetryRecords,
          records,
          mode: InsertMode.insertOrIgnore,
        );
      });
      final afterCount = await countTelemetryForDevice(deviceId);
      return afterCount - beforeCount;
    });
  }

  /// Inserts an entire file's telemetry records in bounded chunks inside a single
  /// atomic transaction, executing only ONE count before and ONE count after all
  /// chunks are inserted (Section 11 optimization).
  Future<int> insertFileRecordsWithCount(
    String deviceId,
    List<TelemetryRecordsCompanion> records, {
    int chunkSize = 500,
  }) async {
    if (records.isEmpty) return 0;

    return await transaction(() async {
      final beforeCount = await countTelemetryForDevice(deviceId);
      for (int i = 0; i < records.length; i += chunkSize) {
        final end =
            (i + chunkSize < records.length) ? i + chunkSize : records.length;
        final chunk = records.sublist(i, end);
        await batch((b) {
          b.insertAll(
            telemetryRecords,
            chunk,
            mode: InsertMode.insertOrIgnore,
          );
        });
      }
      final afterCount = await countTelemetryForDevice(deviceId);
      return afterCount - beforeCount;
    });
  }

  // --- Live Dashboard ---

  /// Reactive stream that emits the most recent telemetry record for a device.
  ///
  /// Emits null if no records exist yet. Reacts to any INSERT into
  /// [telemetryRecords], making the dashboard update automatically after sync.
  Stream<TelemetryRecord?> watchLatestRecord(String deviceId) =>
      (select(telemetryRecords)
            ..where((t) => t.deviceId.equals(deviceId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.timestamp),
            ])
            ..limit(1))
          .watchSingleOrNull();

  // --- Time-Range Query (for Chart / LTTB input) ---

  /// Returns raw telemetry records for a device within [from]..[to] (inclusive),
  /// ordered by ascending timestamp.
  ///
  /// This is the primary input for the LTTB downsampler. For a single day,
  /// expect ~1440 rows. Pass these to [LttbDownsampler.downsample] before
  /// rendering to keep the chart at ≤150 points.
  Future<List<TelemetryRecord>> getRecordsForRange(
    String deviceId,
    DateTime from,
    DateTime to,
  ) async {
    return (select(telemetryRecords)
          ..where(
            (t) =>
                t.deviceId.equals(deviceId) &
                t.timestamp.isBetweenValues(from, to),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
        .get();
  }

  // --- Daily Aggregation ---

  /// Computes min / max / avg for all metrics on a given [date] for a device.
  ///
  /// Uses raw SQL expressions via [CustomExpression] because Drift's high-level
  /// API does not yet expose SQLite's strftime() for date truncation.
  /// The date boundary is computed in Dart and passed as range values to
  /// the query, keeping the logic transparent and testable.
  Future<DailyAggregate> getDailyAggregates(
      String deviceId, DateTime date) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    // Define aggregate expressions for each numeric column.
    final minTemp = telemetryRecords.temperature.min();
    final maxTemp = telemetryRecords.temperature.max();
    final avgTemp = telemetryRecords.temperature.avg();

    final minHum = telemetryRecords.humidity.min();
    final maxHum = telemetryRecords.humidity.max();
    final avgHum = telemetryRecords.humidity.avg();

    // For INTEGER columns, Drift exposes min/max/avg directly on the column
    // expression via .dartCast<double?>() for avg, but we read them as num?.
    final minEco2 = telemetryRecords.eco2.min();
    final maxEco2 = telemetryRecords.eco2.max();
    final avgEco2 = telemetryRecords.eco2.avg();

    final minTvoc = telemetryRecords.tvoc.min();
    final maxTvoc = telemetryRecords.tvoc.max();
    final avgTvoc = telemetryRecords.tvoc.avg();

    final minAqi = telemetryRecords.aqi.min();
    final maxAqi = telemetryRecords.aqi.max();
    final avgAqi = telemetryRecords.aqi.avg();

    final countExpr = telemetryRecords.id.count();

    final query = selectOnly(telemetryRecords)
      ..addColumns([
        minTemp,
        maxTemp,
        avgTemp,
        minHum,
        maxHum,
        avgHum,
        minEco2,
        maxEco2,
        avgEco2,
        minTvoc,
        maxTvoc,
        avgTvoc,
        minAqi,
        maxAqi,
        avgAqi,
        countExpr,
      ])
      ..where(
        telemetryRecords.deviceId.equals(deviceId) &
            telemetryRecords.timestamp.isBetweenValues(dayStart, dayEnd),
      );

    final row = await query.getSingleOrNull();
    if (row == null) {
      return DailyAggregate(
        date: dayStart,
        temperature: const MetricAggregate(),
        humidity: const MetricAggregate(),
        eco2: const MetricAggregate(),
        tvoc: const MetricAggregate(),
        aqi: const MetricAggregate(),
        sampleCount: 0,
      );
    }

    double? toDouble(num? v) => v?.toDouble();

    return DailyAggregate(
      date: dayStart,
      temperature: MetricAggregate(
        min: toDouble(row.read(minTemp)),
        max: toDouble(row.read(maxTemp)),
        avg: toDouble(row.read(avgTemp)),
      ),
      humidity: MetricAggregate(
        min: toDouble(row.read(minHum)),
        max: toDouble(row.read(maxHum)),
        avg: toDouble(row.read(avgHum)),
      ),
      eco2: MetricAggregate(
        min: toDouble(row.read(minEco2)),
        max: toDouble(row.read(maxEco2)),
        avg: toDouble(row.read(avgEco2)),
      ),
      tvoc: MetricAggregate(
        min: toDouble(row.read(minTvoc)),
        max: toDouble(row.read(maxTvoc)),
        avg: toDouble(row.read(avgTvoc)),
      ),
      aqi: MetricAggregate(
        min: toDouble(row.read(minAqi)),
        max: toDouble(row.read(maxAqi)),
        avg: toDouble(row.read(avgAqi)),
      ),
      sampleCount: row.read(countExpr) ?? 0,
    );
  }

  // --- Cleanup ---

  /// Deletes all records for a device older than [before].
  /// Used in storage management to prune old telemetry.
  Future<int> deleteRecordsBefore(String deviceId, DateTime before) =>
      (delete(telemetryRecords)
            ..where(
              (t) =>
                  t.deviceId.equals(deviceId) &
                  t.timestamp.isSmallerThanValue(before),
            ))
          .go();

  // --- Storage & Overview Metrics ---

  /// Counts the total number of telemetry records stored across all devices.
  Future<int> countAllTelemetry() async {
    final countExpr = telemetryRecords.id.count();
    final row = await (selectOnly(telemetryRecords)..addColumns([countExpr]))
        .getSingleOrNull();
    return row?.read(countExpr) ?? 0;
  }

  /// Counts the total number of telemetry records stored for [deviceId].
  Future<int> countTelemetryForDevice(String deviceId) async {
    final countExpr = telemetryRecords.id.count();
    final row = await (selectOnly(telemetryRecords)
          ..addColumns([countExpr])
          ..where(telemetryRecords.deviceId.equals(deviceId)))
        .getSingleOrNull();
    return row?.read(countExpr) ?? 0;
  }

  /// Returns the earliest telemetry timestamp across all devices.
  Future<DateTime?> getOldestTimestamp() async {
    final minTime = telemetryRecords.timestamp.min();
    final row = await (selectOnly(telemetryRecords)..addColumns([minTime]))
        .getSingleOrNull();
    return row?.read(minTime);
  }

  /// Returns the latest telemetry timestamp across all devices.
  Future<DateTime?> getNewestTimestamp() async {
    final maxTime = telemetryRecords.timestamp.max();
    final row = await (selectOnly(telemetryRecords)..addColumns([maxTime]))
        .getSingleOrNull();
    return row?.read(maxTime);
  }

  /// Returns the earliest telemetry timestamp for [deviceId].
  Future<DateTime?> getOldestTimestampForDevice(String deviceId) async {
    final minTime = telemetryRecords.timestamp.min();
    final row = await (selectOnly(telemetryRecords)
          ..addColumns([minTime])
          ..where(telemetryRecords.deviceId.equals(deviceId)))
        .getSingleOrNull();
    return row?.read(minTime);
  }

  /// Returns the latest telemetry timestamp for [deviceId].
  Future<DateTime?> getNewestTimestampForDevice(String deviceId) async {
    final maxTime = telemetryRecords.timestamp.max();
    final row = await (selectOnly(telemetryRecords)
          ..addColumns([maxTime])
          ..where(telemetryRecords.deviceId.equals(deviceId)))
        .getSingleOrNull();
    return row?.read(maxTime);
  }

  /// One-shot fetch of the [limit] most recent records for [deviceId].
  Future<List<TelemetryRecord>> getRecentRecords(
    String deviceId, {
    int limit = 10,
  }) =>
      (select(telemetryRecords)
            ..where((t) => t.deviceId.equals(deviceId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .get();

  /// Reactive stream of the [limit] most recent records for [deviceId].
  Stream<List<TelemetryRecord>> watchRecentRecords(
    String deviceId, {
    int limit = 10,
  }) =>
      (select(telemetryRecords)
            ..where((t) => t.deviceId.equals(deviceId))
            ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
            ..limit(limit))
          .watch();

  /// Memory-safe chunked retrieval for exports and backups.
  ///
  /// Retrieves up to [limit] records ordered by ascending timestamp,
  /// strictly after [afterTimestamp] to allow streaming pagination.
  Future<List<TelemetryRecord>> getTelemetryChunk({
    String? deviceId,
    DateTime? afterTimestamp,
    int limit = 1000,
  }) async {
    return (select(telemetryRecords)
          ..where((t) {
            Expression<bool> predicate = const Constant(true);
            if (deviceId != null) {
              predicate = predicate & t.deviceId.equals(deviceId);
            }
            if (afterTimestamp != null) {
              predicate =
                  predicate & t.timestamp.isBiggerThanValue(afterTimestamp);
            }
            return predicate;
          })
          ..orderBy([(t) => OrderingTerm.asc(t.timestamp)])
          ..limit(limit))
        .get();
  }

  /// Deletes all telemetry records.
  Future<int> clearAllTelemetry() => delete(telemetryRecords).go();
}

// ---------------------------------------------------------------------------
// Riverpod Provider
// ---------------------------------------------------------------------------

final telemetryDaoProvider = Provider<TelemetryDao>((ref) {
  return ref.watch(appDatabaseProvider).telemetryDao;
});
