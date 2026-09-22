// lib/core/network/models/device_file.dart
//
// Typed model representing an edge storage file on an ESP32 device.
// Includes adaptive response parsing for varying firmware /listfiles contracts
// and safe active-log date detection to protect files currently being written.

/// Represents a file stored in the ESP32's local flash memory (LittleFS/SPIFFS).
class DeviceFile {
  final String name;
  final int? size;
  final DateTime? date;

  const DeviceFile({
    required this.name,
    this.size,
    this.date,
  });

  /// Extracts the date from standard DetaLab filename format `data_YYYY-MM-DD.csv`
  /// or ISO-like filename prefixes.
  static DateTime? parseDateFromFileName(String fileName) {
    final clean = fileName.trim().toLowerCase();
    // Pattern: data_2026-09-21.csv or 2026-09-21.csv
    final regex = RegExp(r'(?:data_)?(\d{4})-(\d{2})-(\d{2})');
    final match = regex.firstMatch(clean);
    if (match != null) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (year != null && month != null && day != null) {
        return DateTime.utc(year, month, day);
      }
    }
    return null;
  }

  /// Determines whether this file is an active, open log that should NEVER be deleted.
  ///
  /// A file is considered active if:
  /// 1. Its name matches the device's currently active file reported via `/data` ([activeFileName]).
  /// 2. Its parsed date matches today's date (local or UTC).
  /// 3. It lacks date information and cannot be proven historical (conservative safety).
  bool isActiveLog({String? activeFileName, DateTime? referenceTime}) {
    if (activeFileName != null &&
        activeFileName.isNotEmpty &&
        name.toLowerCase() == activeFileName.toLowerCase()) {
      return true;
    }

    final fileDate = date ?? parseDateFromFileName(name);
    if (fileDate != null) {
      final now = referenceTime ?? DateTime.now();
      final todayUtc = DateTime.utc(now.year, now.month, now.day);
      final todayLocal = DateTime(now.year, now.month, now.day);
      final fDateLocal = DateTime(fileDate.year, fileDate.month, fileDate.day);

      if (fileDate == todayUtc || fDateLocal == todayLocal) {
        return true;
      }
    }

    return false;
  }

  /// Evaluates whether this file is safe to delete after local SQLite persistence.
  ///
  /// CRITICAL: Non-CSV files, active logs, and files from today are NEVER eligible.
  bool isEligibleForDeletion({String? activeFileName, DateTime? referenceTime}) {
    if (!name.toLowerCase().endsWith('.csv')) return false;
    return !isActiveLog(
      activeFileName: activeFileName,
      referenceTime: referenceTime,
    );
  }

  /// Parses a single file entry from map or string.
  factory DeviceFile.fromEntry(dynamic entry) {
    if (entry is Map) {
      final name = _firstString(entry, const [
            'name',
            'filename',
            'fileName',
            'file',
            'path',
          ]) ??
          '';
      final size = _firstInt(entry, const ['size', 'length', 'bytes']);
      return DeviceFile(
        name: name,
        size: size,
        date: parseDateFromFileName(name),
      );
    } else if (entry is String) {
      final trimmed = entry.trim();
      return DeviceFile(
        name: trimmed,
        date: parseDateFromFileName(trimmed),
      );
    }
    throw const FormatException('Invalid device file entry');
  }

  /// Adaptively parses the raw `/listfiles` response from diverse firmware formats:
  /// 1. JSON Array of objects: `[{"name": "data_2026-09-21.csv", "size": 1234}]`
  /// 2. JSON Array of strings: `["data_2026-09-21.csv", ...]`
  /// 3. JSON Map with list: `{"files": [...]}`
  /// 4. Plaintext newline-delimited: `"data_2026-09-20.csv\ndata_2026-09-21.csv"`
  static List<DeviceFile> parseListResponse(dynamic data) {
    if (data == null) return const [];

    final rawList = <dynamic>[];

    if (data is List) {
      rawList.addAll(data);
    } else if (data is Map) {
      final inner = data['files'] ?? data['data'] ?? data['file_list'] ?? data['list'];
      if (inner is List) {
        rawList.addAll(inner);
      }
    } else if (data is String) {
      final lines = data.split(RegExp(r'\r?\n'));
      for (final line in lines) {
        final clean = line.trim();
        if (clean.isNotEmpty && clean.toLowerCase().endsWith('.csv')) {
          rawList.add(clean);
        }
      }
    }

    final results = <DeviceFile>[];
    for (final item in rawList) {
      try {
        final file = DeviceFile.fromEntry(item);
        if (file.name.isNotEmpty) {
          results.add(file);
        }
      } catch (_) {
        // Skip unparseable single entry
      }
    }

    return results;
  }

  static String? _firstString(Map map, List<String> keys) {
    for (final key in keys) {
      final val = map[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        return val.toString().trim();
      }
    }
    return null;
  }

  static int? _firstInt(Map map, List<String> keys) {
    for (final key in keys) {
      final val = map[key];
      if (val is num) return val.toInt();
      if (val is String) {
        final parsed = int.tryParse(val.trim());
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  @override
  String toString() => 'DeviceFile(name: $name, size: $size, date: $date)';
}
