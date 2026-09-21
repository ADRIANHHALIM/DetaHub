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
  /// A local receipt time is used only when firmware omits a timestamp. A
  /// supplied, invalid timestamp is rejected instead of being replaced.
  factory LiveTelemetry.fromJson(
    Map<String, dynamic> json, {
    DateTime? receivedAt,
  }) {
    final timestampRaw = _firstValue(
      json,
      const ['timestamp', 'ntp_time', 'ntpTime', 'time'],
    );
    final parsedTimestamp = _parseTimestamp(timestampRaw);
    if (timestampRaw != null && parsedTimestamp == null) {
      throw const FormatException('Invalid telemetry timestamp');
    }

    return LiveTelemetry(
      timestamp: parsedTimestamp ?? receivedAt ?? DateTime.now(),
      hasHardwareTimestamp: parsedTimestamp != null,
      temperature: _asDouble(
        _firstValue(json, const ['temperature', 'temp']),
        'temperature',
      ),
      humidity: _asDouble(
        _firstValue(json, const ['humidity', 'hum']),
        'humidity',
      ),
      eco2: _asInt(_firstValue(json, const ['eco2', 'eCO2']), 'eco2'),
      tvoc: _asInt(_firstValue(json, const ['tvoc', 'TVOC']), 'tvoc'),
      aqi: _asInt(_firstValue(json, const ['aqi', 'AQI']), 'aqi'),
      uptime: _asInt(json['uptime'], 'uptime'),
      totalRecords: _asInt(
        _firstValue(json, const ['total_records', 'totalRecords']),
        'total_records',
      ),
      fileName: _asString(
        _firstValue(json, const ['file_name', 'fileName', 'filename']),
        'file_name',
      ),
      deviceId: _asString(
        _firstValue(json, const ['device_id', 'deviceId', 'id']),
        'device_id',
      ),
      productType: _asString(
        _firstValue(json, const ['product_type', 'productType', 'model']),
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
      return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000,
          isUtc: true);
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  static double? _asDouble(dynamic value, String field) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid $field value');
  }

  static int? _asInt(dynamic value, String field) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num && value == value.roundToDouble()) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid $field value');
  }

  static String? _asString(dynamic value, String field) {
    if (value == null) return null;
    if (value is String) return value;
    throw FormatException('Invalid $field value');
  }

  @override
  String toString() =>
      'LiveTelemetry(ts: $timestamp, temp: $temperature, aqi: $aqi)';
}
