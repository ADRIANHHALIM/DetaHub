// lib/core/network/models/live_telemetry.dart
//
// DTO for GET /api/live response from a DetaLab IoT device.
// All sensor fields are nullable — the device may omit values if
// the sensor is not warmed up or if the metric is not supported.

/// Parsed real-time telemetry snapshot from a device's /api/live endpoint.
///
/// Example JSON:
/// ```json
/// {
///   "timestamp":   "2024-01-15T08:30:00",
///   "temperature": 24.5,
///   "humidity":    62.3,
///   "eco2":        450,
///   "tvoc":        120,
///   "aqi":         1,
///   "uptime":      7200
/// }
/// ```
class LiveTelemetry {
  final DateTime timestamp;
  final double? temperature;
  final double? humidity;
  final int? eco2;
  final int? tvoc;
  final int? aqi;
  final int? uptime; // seconds

  const LiveTelemetry({
    required this.timestamp,
    this.temperature,
    this.humidity,
    this.eco2,
    this.tvoc,
    this.aqi,
    this.uptime,
  });

  /// Parses a raw JSON map from Dio's response.
  /// Timestamp is parsed from ISO-8601 string; falls back to [DateTime.now]
  /// if the field is absent (should not happen in production firmware).
  factory LiveTelemetry.fromJson(Map<String, dynamic> json) {
    final tsRaw = json['timestamp'];
    final timestamp = tsRaw is String
        ? DateTime.tryParse(tsRaw) ?? DateTime.now()
        : DateTime.now();

    return LiveTelemetry(
      timestamp: timestamp,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      eco2: json['eco2'] as int?,
      tvoc: json['tvoc'] as int?,
      aqi: json['aqi'] as int?,
      uptime: json['uptime'] as int?,
    );
  }

  @override
  String toString() =>
      'LiveTelemetry(ts: $timestamp, temp: $temperature, aqi: $aqi)';
}
