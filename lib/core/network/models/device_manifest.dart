// lib/core/network/models/device_manifest.dart

import 'live_telemetry.dart';

/// Parsed device metadata returned by a DetaLab device.
///
/// Accepts both the original /api/manifest contract and the current LAT
/// test firmware /data response.
class DeviceManifest {
  final String deviceId;
  final String productType;
  final String firmwareVersion;
  final List<String> metrics;
  final int? uptime;

  const DeviceManifest({
    required this.deviceId,
    required this.productType,
    required this.firmwareVersion,
    required this.metrics,
    this.uptime,
  });

  factory DeviceManifest.fromJson(Map<String, dynamic> json) {
    final deviceId = _string(json, const ['device_id', 'deviceId', 'id']);
    if (deviceId == null || deviceId.isEmpty) {
      throw const FormatException('Missing device_id in device response');
    }
    final productType = _string(json, const ['product_type', 'productType']);
    if (productType == null || productType.isEmpty) {
      throw const FormatException('Missing product_type in device response');
    }
    return DeviceManifest(
      deviceId: deviceId,
      productType: productType,
      firmwareVersion:
          _string(json, const ['firmware_version', 'firmwareVersion']) ??
              'unknown',
      metrics: _metrics(json),
      uptime: _int(json['uptime']),
    );
  }

  /// Creates a local registration identity when a test firmware has no
  /// `/api/manifest`, but has confirmed itself through `/data`.
  factory DeviceManifest.fromLiveTelemetry(
    LiveTelemetry telemetry,
    String baseUrl,
  ) {
    final stableAddress = deriveStableAddress(baseUrl);
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
      metrics: metrics.isNotEmpty
          ? metrics
          : const ['temperature', 'humidity', 'eco2', 'tvoc', 'aqi'],
      uptime: telemetry.uptime,
    );
  }

  factory DeviceManifest.fromDataJson(
    Map<String, dynamic> json, {
    required String fallbackDeviceId,
  }) {
    final data = _unwrap(json);
    return DeviceManifest(
      deviceId: _string(data, const ['device_id', 'deviceId', 'id']) ??
          fallbackDeviceId,
      productType:
          _string(data, const ['product_type', 'productType']) ?? 'LAT_ENS160',
      firmwareVersion:
          _string(data, const ['firmware_version', 'firmwareVersion']) ??
              'unknown',
      metrics: const ['temperature', 'humidity', 'eco2', 'tvoc', 'aqi'],
      uptime: _int(data['uptime']),
    );
  }

  /// Derives a deterministic address slug from [baseUrl] for local identification.
  static String deriveStableAddress(String baseUrl) {
    var raw = baseUrl.trim();
    raw = raw.replaceFirst(RegExp(r'^https?:\/\/'), '');
    raw = raw.split('/').first; // extract host and port only
    if (raw.endsWith(':80')) {
      raw = raw.substring(0, raw.length - 3);
    } else if (raw.endsWith(':443')) {
      raw = raw.substring(0, raw.length - 4);
    }
    final sanitized = raw
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return sanitized.isNotEmpty ? sanitized : 'device';
  }

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final nested = json['data'];
    return nested is Map<String, dynamic> ? nested : json;
  }

  static List<String> _metrics(Map<String, dynamic> json) {
    final raw = json['metrics'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const [];
  }

  static String? _string(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  static int? _int(dynamic value) => value is num ? value.toInt() : null;

  @override
  String toString() =>
      'DeviceManifest(id: $deviceId, type: $productType, fw: $firmwareVersion)';
}
