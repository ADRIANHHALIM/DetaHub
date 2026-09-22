/// Real-time telemetry returned by a LAT device's `/data` endpoint.
///
/// All sensor fields are nullable: a missing value means the hardware did not
/// provide it. Invalid supplied values are rejected as malformed data.
class LiveTelemetry {
  final DateTime timestamp;
  final bool hasHardwareTimestamp;
  final double? temperature;
  final double? humidity;
  final int? eco2;
  final int? tvoc;
  final int? aqi;
  final int? uptime;
  final int? totalRecords;
  final String? fileName;
  final String? deviceId;
  final String? productType;

  const LiveTelemetry({
    required this.timestamp,
    required this.hasHardwareTimestamp,
    this.temperature,
    this.humidity,
    this.eco2,
    this.tvoc,
    this.aqi,
    this.uptime,
    this.totalRecords,
    this.fileName,
    this.deviceId,
    this.productType,
  });

  /// Supports the field spelling used by current and older LAT firmware.
  ///
  /// A local receipt time is used only when firmware omits a timestamp or when
  /// the hardware timestamp is zero / unsynced NTP (pre-2020).
  factory LiveTelemetry.fromJson(
    Map<String, dynamic> json, {
    DateTime? receivedAt,
  }) {
    final timestampRaw = _firstValue(
      json,
      const [
        'timestamp',
        'ntp_time',
        'ntpTime',
        'time',
        'Timestamp',
        'NTP_TIME',
        'NtpTime',
        'Time'
      ],
    );
    final parsedTimestamp = _parseTimestamp(timestampRaw);
    final rawStr = timestampRaw?.toString().trim();
    if (timestampRaw != null &&
        rawStr != null &&
        rawStr.isNotEmpty &&
        rawStr != '0' &&
        parsedTimestamp == null) {
      throw const FormatException('Invalid telemetry timestamp');
    }

    final effectiveTimestamp = parsedTimestamp ?? receivedAt ?? DateTime.now();

    return LiveTelemetry(
      timestamp: effectiveTimestamp,
      hasHardwareTimestamp: parsedTimestamp != null,
      temperature: _asDouble(
        _firstValue(json, const [
          'temperature',
          'temp',
          'Temperature',
          'Temp',
          'TEMP',
        ]),
        'temperature',
      ),
      humidity: _asDouble(
        _firstValue(json, const [
          'humidity',
          'hum',
          'Humidity',
          'Hum',
          'HUM',
        ]),
        'humidity',
      ),
      eco2: _asInt(
        _firstValue(json, const [
          'eco2',
          'eCO2',
          'ECO2',
          'Eco2',
          'co2',
          'CO2',
        ]),
        'eco2',
      ),
      tvoc: _asInt(
        _firstValue(json, const [
          'tvoc',
          'TVOC',
          'Tvoc',
        ]),
        'tvoc',
      ),
      aqi: _asInt(
        _firstValue(json, const [
          'aqi',
          'AQI',
          'Aqi',
        ]),
        'aqi',
      ),
      uptime: _asInt(
        _firstValue(json, const ['uptime', 'Uptime']),
        'uptime',
      ),
      totalRecords: _asInt(
        _firstValue(json, const [
          'total_records',
          'totalRecords',
          'totalrecords',
          'TotalRecords',
          'records',
          'Records',
        ]),
        'total_records',
      ),
      fileName: _asString(
        _firstValue(json, const [
          'file_name',
          'fileName',
          'filename',
          'FileName',
          'Filename',
          'file',
        ]),
        'file_name',
      ),
      deviceId: _asString(
        _firstValue(json, const [
          'device_id',
          'deviceId',
          'id',
          'DeviceId',
          'ID',
        ]),
        'device_id',
      ),
      productType: _asString(
        _firstValue(json, const [
          'product_type',
          'productType',
          'model',
          'ProductType',
          'Model',
          'type',
        ]),
        'product_type',
      ),
    );
  }

  static dynamic _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) return json[key];
    }
    return null;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      final n = value.toInt();
      if (n <= 0) return null;
      if (n > 100000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(n, isUtc: true);
        return dt.year >= 2020 ? dt : null;
      }
      final dt = DateTime.fromMillisecondsSinceEpoch(n * 1000, isUtc: true);
      return dt.year >= 2020 ? dt : null;
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || trimmed == '0') return null;
      final numVal = int.tryParse(trimmed);
      if (numVal != null) {
        if (numVal <= 0) return null;
        if (numVal > 100000000000) {
          final dt = DateTime.fromMillisecondsSinceEpoch(numVal, isUtc: true);
          return dt.year >= 2020 ? dt : null;
        }
        final dt =
            DateTime.fromMillisecondsSinceEpoch(numVal * 1000, isUtc: true);
        return dt.year >= 2020 ? dt : null;
      }
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null && parsed.year >= 2020) {
        if (parsed.isUtc) return parsed;
        return DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
      }
    }
    return null;
  }

  static double? _asDouble(dynamic value, String field) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid $field value');
  }

  static int? _asInt(dynamic value, String field) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid $field value');
  }

  static String? _asString(dynamic value, String field) {
    if (value == null) return null;
    if (value is String) return value.trim();
    throw FormatException('Invalid $field value');
  }

  @override
  String toString() =>
      'LiveTelemetry(ts: $timestamp, temp: $temperature, aqi: $aqi)';
}
