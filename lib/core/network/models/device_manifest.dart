// lib/core/network/models/device_manifest.dart

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
    return DeviceManifest(
      deviceId: deviceId,
      productType:
          _string(json, const ['product_type', 'productType']) ?? 'LAT_ENS160',
      firmwareVersion:
          _string(json, const ['firmware_version', 'firmwareVersion']) ??
              'unknown',
      metrics: _metrics(json),
      uptime: _int(json['uptime']),
    );
  }

  factory DeviceManifest.fromDataJson(
    Map<String, dynamic> json, {
    required String fallbackDeviceId,
  }) {
    final data = _unwrap(json);
    return DeviceManifest(
      deviceId:
          _string(data, const ['device_id', 'deviceId', 'id']) ??
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

  static Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
    final nested = json['data'];
    return nested is Map<String, dynamic> ? nested : json;
  }

  static List<String> _metrics(Map<String, dynamic> json) {
    final raw = json['metrics'];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return const ['temperature', 'humidity', 'eco2', 'tvoc', 'aqi'];
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
