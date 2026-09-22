// lib/core/sync/csv/telemetry_csv_parser.dart
//
// Memory-safe, robust CSV parser for DetaLab ESP32 telemetry logs.
// Strictly local-first: preserves original timestamps without interpolation,
// handles line endings (CRLF/LF), extra whitespace, malformed rows,
// and rejects invalid numeric values (NaN / Infinity).

import 'package:csv/csv.dart';

import 'telemetry_csv_record.dart';

/// Result summary of parsing a CSV string.
class TelemetryCsvParseResult {
  final List<TelemetryCsvRecord> validRecords;
  final List<TelemetryCsvRecord> invalidRecords;
  final int totalRowsRead;
  final List<String> headers;

  const TelemetryCsvParseResult({
    required this.validRecords,
    required this.invalidRecords,
    required this.totalRowsRead,
    required this.headers,
  });

  int get validCount => validRecords.length;
  int get invalidCount => invalidRecords.length;
}

/// Parser for DetaLab ESP32 historical CSV logs.
class TelemetryCsvParser {
  const TelemetryCsvParser();

  /// Parses raw CSV content into typed [TelemetryCsvRecord]s.
  ///
  /// Column mapping is derived dynamically from the header row if present,
  /// with fallback to standard DetaLab positional order:
  /// `[Timestamp, Temperature(C), Humidity(%), eCO2(ppm), TVOC(ppb), AQI]`
  TelemetryCsvParseResult parseString(String csvContent) {
    if (csvContent.trim().isEmpty) {
      return const TelemetryCsvParseResult(
        validRecords: [],
        invalidRecords: [],
        totalRowsRead: 0,
        headers: [],
      );
    }

    // Use standard csv package converter configured for tolerant line ends
    const converter = CsvToListConverter(
      shouldParseNumbers: false,
      allowInvalid: true,
      eol: '\n',
    );

    // Normalize CRLF to LF
    final normalized = csvContent.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final rows = converter.convert(normalized);

    if (rows.isEmpty) {
      return const TelemetryCsvParseResult(
        validRecords: [],
        invalidRecords: [],
        totalRowsRead: 0,
        headers: [],
      );
    }

    // Determine header mapping
    final firstRow = rows.first;
    int dataStartIndex = 0;
    Map<String, int> columnMap = {};
    List<String> headers = [];

    if (_isHeaderRow(firstRow)) {
      headers = firstRow.map((e) => e.toString().trim()).toList();
      columnMap = _buildColumnMap(headers);
      dataStartIndex = 1;
    } else {
      // Fallback to default positional schema
      headers = const [
        'Timestamp',
        'Temperature',
        'Humidity',
        'eCO2',
        'TVOC',
        'AQI',
      ];
      columnMap = {
        'timestamp': 0,
        'temperature': 1,
        'humidity': 2,
        'eco2': 3,
        'tvoc': 4,
        'aqi': 5,
      };
      dataStartIndex = 0;
    }

    final validRecords = <TelemetryCsvRecord>[];
    final invalidRecords = <TelemetryCsvRecord>[];
    int totalRowsRead = 0;

    for (int i = dataStartIndex; i < rows.length; i++) {
      final rawRow = rows[i];
      final lineNumber = i + 1;

      // Skip completely empty lines
      if (rawRow.isEmpty || (rawRow.length == 1 && rawRow.first.toString().trim().isEmpty)) {
        continue;
      }

      totalRowsRead++;

      final record = _parseRow(rawRow, columnMap, lineNumber);
      if (record.isValid) {
        validRecords.add(record);
      } else {
        invalidRecords.add(record);
      }
    }

    return TelemetryCsvParseResult(
      validRecords: validRecords,
      invalidRecords: invalidRecords,
      totalRowsRead: totalRowsRead,
      headers: headers,
    );
  }

  /// Splits [records] into bounded slices to ensure memory-safe database transactions.
  static List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    if (list.isEmpty) return [];
    if (chunkSize <= 0) return [list];

    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      final end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  // ---------------------------------------------------------------------------
  // Internal Helpers
  // ---------------------------------------------------------------------------

  bool _isHeaderRow(List<dynamic> row) {
    if (row.isEmpty) return false;
    final first = row.first.toString().trim().toLowerCase();
    return first.contains('time') ||
        first.contains('timestamp') ||
        first.contains('date');
  }

  Map<String, int> _buildColumnMap(List<String> headers) {
    final map = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase();
      if (h.contains('time') || h.contains('date')) {
        map['timestamp'] = i;
      } else if (h.contains('temp')) {
        map['temperature'] = i;
      } else if (h.contains('hum')) {
        map['humidity'] = i;
      } else if (h.contains('eco2') || h.contains('co2')) {
        map['eco2'] = i;
      } else if (h.contains('tvoc') || h.contains('voc')) {
        map['tvoc'] = i;
      } else if (h.contains('aqi')) {
        map['aqi'] = i;
      }
    }
    return map;
  }

  TelemetryCsvRecord _parseRow(
    List<dynamic> row,
    Map<String, int> columnMap,
    int lineNumber,
  ) {
    // 1. Timestamp (MANDATORY)
    final timeIndex = columnMap['timestamp'] ?? 0;
    if (timeIndex >= row.length) {
      return TelemetryCsvRecord.invalid(
        lineNumber: lineNumber,
        reason: 'Missing timestamp column in row',
      );
    }

    final rawTime = row[timeIndex]?.toString().trim();
    if (rawTime == null || rawTime.isEmpty) {
      return TelemetryCsvRecord.invalid(
        lineNumber: lineNumber,
        reason: 'Empty timestamp value',
      );
    }

    final parsedTimestamp = _parseTimestamp(rawTime);
    if (parsedTimestamp == null) {
      return TelemetryCsvRecord.invalid(
        lineNumber: lineNumber,
        reason: 'Unparseable or impossible timestamp: "$rawTime"',
      );
    }

    // 2. Temperature
    double? temperature;
    final tempIndex = columnMap['temperature'];
    if (tempIndex != null && tempIndex < row.length) {
      final val = _parseDouble(row[tempIndex]);
      if (val != null && (val.isNaN || val.isInfinite)) {
        return TelemetryCsvRecord.invalid(
          lineNumber: lineNumber,
          reason: 'Invalid temperature: NaN or Infinite',
          fallbackTimestamp: parsedTimestamp,
        );
      }
      temperature = val;
    }

    // 3. Humidity
    double? humidity;
    final humIndex = columnMap['humidity'];
    if (humIndex != null && humIndex < row.length) {
      final val = _parseDouble(row[humIndex]);
      if (val != null && (val.isNaN || val.isInfinite)) {
        return TelemetryCsvRecord.invalid(
          lineNumber: lineNumber,
          reason: 'Invalid humidity: NaN or Infinite',
          fallbackTimestamp: parsedTimestamp,
        );
      }
      humidity = val;
    }

    // 4. eCO2
    int? eco2;
    final eco2Index = columnMap['eco2'];
    if (eco2Index != null && eco2Index < row.length) {
      eco2 = _parseInt(row[eco2Index]);
    }

    // 5. TVOC
    int? tvoc;
    final tvocIndex = columnMap['tvoc'];
    if (tvocIndex != null && tvocIndex < row.length) {
      tvoc = _parseInt(row[tvocIndex]);
    }

    // 6. AQI
    int? aqi;
    final aqiIndex = columnMap['aqi'];
    if (aqiIndex != null && aqiIndex < row.length) {
      aqi = _parseInt(row[aqiIndex]);
    }

    return TelemetryCsvRecord(
      timestamp: parsedTimestamp,
      temperature: temperature,
      humidity: humidity,
      eco2: eco2,
      tvoc: tvoc,
      aqi: aqi,
      lineNumber: lineNumber,
      isValid: true,
    );
  }

  DateTime? _parseTimestamp(String raw) {
    // 1. Try numeric epoch first (avoids DateTime.tryParse interpreting numbers as years)
    final numVal = int.tryParse(raw);
    if (numVal != null) {
      if (numVal <= 0) return null;
      // Milliseconds vs Seconds
      if (numVal > 100000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(numVal, isUtc: true);
        return (dt.year >= 2020 && dt.year <= 2100) ? dt : null;
      } else {
        final dt = DateTime.fromMillisecondsSinceEpoch(numVal * 1000, isUtc: true);
        return (dt.year >= 2020 && dt.year <= 2100) ? dt : null;
      }
    }

    // 2. Try ISO-8601 (e.g. 2026-09-21T20:15:00Z or 2026-09-21 20:15:00)
    final iso = DateTime.tryParse(raw);
    if (iso != null && iso.year >= 2020 && iso.year <= 2100) {
      return iso.toUtc();
    }

    return null;
  }

  double? _parseDouble(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str == '-' || str.toLowerCase() == 'null') return null;
    return double.tryParse(str);
  }

  int? _parseInt(dynamic raw) {
    if (raw == null) return null;
    final str = raw.toString().trim();
    if (str.isEmpty || str == '-' || str.toLowerCase() == 'null') return null;
    final d = double.tryParse(str);
    return d?.toInt();
  }
}
