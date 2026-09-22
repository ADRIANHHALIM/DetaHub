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

  /// Normalizes a filename to a canonical representation by trimming whitespace,
  /// stripping leading slashes/backslashes, and converting to lowercase.
  /// Example: " /data_2026-09-21.csv " -> "data_2026-09-21.csv"
  static String normalizeFileName(String fileName) {
    return fileName.trim().replaceAll(RegExp(r'^[\\\/]+'), '').toLowerCase();
  }

  /// Extracts the date from standard DetaLab filename format `data_YYYY-MM-DD.csv`
  /// or ISO-like filename prefixes. Returns null if date cannot be strictly proven.
  static DateTime? parseDateFromFileName(String fileName) {
    final clean = normalizeFileName(fileName);
    // Pattern: data_YYYY-MM-DD.csv or YYYY-MM-DD.csv
    final regex = RegExp(r'^(?:data_)?(\d{4})-(\d{2})-(\d{2})(?:\.csv)?$');
    final match = regex.firstMatch(clean);
    if (match != null) {
      final year = int.tryParse(match.group(1)!);
      final month = int.tryParse(match.group(2)!);
      final day = int.tryParse(match.group(3)!);
      if (year != null && month != null && day != null) {
        if (month < 1 || month > 12 || day < 1 || day > 31) return null;
        if (year < 2020 || year > 2100) return null;
        final parsed = DateTime.utc(year, month, day);
        // Strict calendar check (prevents leap/month overflow e.g. Feb 30)
        if (parsed.year == year && parsed.month == month && parsed.day == day) {
          return parsed;
        }
      }
    }
    return null;
  }

  /// Determines whether this file is an active, open log that should NEVER be deleted.
  ///
  /// A file is considered active if:
  /// 1. Its name matches the device's currently active file reported via `/data` ([activeFileName]).
  /// 2. Its parsed date matches today's date (local or UTC) or is in the future.
  /// 3. It lacks date information and cannot be proven historical (conservative safety).
  bool isActiveLog({String? activeFileName, DateTime? referenceTime}) {
    final normName = normalizeFileName(name);

    if (activeFileName != null && activeFileName.trim().isNotEmpty) {
      if (normName == normalizeFileName(activeFileName)) {
        return true;
      }
    }

    final fileDate = parseDateFromFileName(name) ?? date;
    if (fileDate == null) {
      // Conservative safety: undated files are treated as potentially active/uncertain
      return true;
    }

    final now = referenceTime ?? DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final fDateUtc = DateTime.utc(fileDate.year, fileDate.month, fileDate.day);

    // If file date is today or future, it is active
    if (!fDateUtc.isBefore(todayUtc)) {
      return true;
    }

    return false;
  }

  /// Evaluates whether this file is safe to delete after local SQLite persistence.
  ///
  /// CRITICAL: A file is eligible for deletion ONLY if ALL of the following are true:
  /// 1. Filename ends with .csv
  /// 2. Filename contains a valid, parseable historical date
  /// 3. File date is strictly before reference/current day
  /// 4. Filename does NOT match activeFileName
  ///
  /// If the date cannot be proven (e.g. log.csv, backup.csv, malformed-date.csv): NEVER DELETE.
  bool isEligibleForDeletion({String? activeFileName, DateTime? referenceTime}) {
    if (!normalizeFileName(name).endsWith('.csv')) return false;

    // Rule 2: Filename MUST contain a valid, parseable historical date.
    // Do not infer date from secondary sources if filename itself cannot prove it.
    final fileDate = parseDateFromFileName(name);
    if (fileDate == null) {
      // Cannot prove date -> NEVER DELETE
      return false;
    }

    final now = referenceTime ?? DateTime.now();
    final todayUtc = DateTime.utc(now.year, now.month, now.day);
    final fDateUtc = DateTime.utc(fileDate.year, fileDate.month, fileDate.day);

    // Rule 3: Must be strictly before reference/current day
    if (!fDateUtc.isBefore(todayUtc)) {
      return false;
    }

    // Rule 4: Must not match active file
    if (activeFileName != null && activeFileName.trim().isNotEmpty) {
      if (normalizeFileName(name) == normalizeFileName(activeFileName)) {
        return false;
      }
    }

    return true;
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
