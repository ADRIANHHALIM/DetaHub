// lib/core/network/models/device_manifest.dart
//
// DTO for GET /api/manifest response from a DetaLab IoT device.
// The manifest is the first call made after a user enters a device URL —
// it auto-fills the device ID, product type, and available metrics.

import 'live_telemetry.dart';

/// Parsed response from a device's /api/manifest endpoint.
///
/// Example JSON:
/// ```json
/// {
///   "device_id":       "lat-lab-01",
///   "product_type":    "LAT_ENS160",
///   "firmware_version":"1.2.0",
///   "metrics":         ["temperature","humidity","eco2","tvoc","aqi"],
///   "uptime":          3600
/// }
/// ```
class DeviceManifest {
  final String deviceId;
  final String productType;
  final String firmwareVersion;
  final List<String> metrics;
  final int? uptime; // seconds since last boot, optional

  const DeviceManifest({
    required this.deviceId,
    required this.productType,
    required this.firmwareVersion,
    required this.metrics,
    this.uptime,
  });

  /// Parses a raw JSON map from Dio's response data.
  /// Throws [FormatException] if required fields are missing — caught by
  /// [DeviceApiService] and converted to a [ParseError].
  factory DeviceManifest.fromJson(Map<String, dynamic> json) {
    return DeviceManifest(
      deviceId: json['device_id'] as String? ??
          (throw const FormatException('Missing device_id in manifest')),
      productType: json['product_type'] as String? ??
          (throw const FormatException('Missing product_type in manifest')),
      firmwareVersion: json['firmware_version'] as String? ?? 'unknown',
      metrics: (json['metrics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      uptime: json['uptime'] as int?,
    );
  }

  /// Creates a local registration identity when a test firmware has no
  /// `/api/manifest`, but has confirmed itself through `/data`.
  factory DeviceManifest.fromLiveTelemetry(
    LiveTelemetry telemetry,
    String baseUrl,
  ) {
    final uri = Uri.tryParse(baseUrl);
    final address =
        uri?.hasPort == true ? '${uri!.host}-${uri.port}' : uri?.host;
    final stableAddress = (address == null || address.isEmpty)
        ? baseUrl.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        : address.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    final metrics = <String>[
      if (telemetry.temperature != null) 'temperature',
      if (telemetry.humidity != null) 'humidity',
      if (telemetry.eco2 != null) 'eco2',
      if (telemetry.tvoc != null) 'tvoc',
      if (telemetry.aqi != null) 'aqi',
    ];

    return DeviceManifest(
      deviceId: telemetry.deviceId?.trim().isNotEmpty == true
          ? telemetry.deviceId!.trim()
          : 'lat-$stableAddress',
      productType: telemetry.productType?.trim().isNotEmpty == true
          ? telemetry.productType!.trim()
          : 'LAT',
      firmwareVersion: 'unknown',
      metrics: metrics,
      uptime: telemetry.uptime,
    );
  }

  @override
  String toString() =>
      'DeviceManifest(id: $deviceId, type: $productType, fw: $firmwareVersion)';
}
