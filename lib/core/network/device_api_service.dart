// lib/core/network/device_api_service.dart
//
// Service layer for communicating with a DetaLab IoT device's local HTTP API.
//
// All public methods return Result<T, NetworkError> — they never throw.
// Dio exceptions are caught here and mapped to typed NetworkError subtypes,
// keeping the feature layer clean of HTTP-specific error handling.

import 'dart:convert';

import 'package:dio/dio.dart';

import 'network_error.dart';
import 'models/device_manifest.dart';
import 'models/live_telemetry.dart';

/// Provides typed access to a DetaLab device's local HTTP endpoints.
///
/// The [baseUrl] is passed per-call (not stored) because each device
/// has its own IP/URL and the service is shared across all devices.
class DeviceApiService {
  final Dio _dio;

  const DeviceApiService(this._dio);

  String _cleanUrl(String url) {
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  // ---------------------------------------------------------------------------
  // GET /api/manifest with /data fallback
  // ---------------------------------------------------------------------------

  /// Fetches device metadata, capabilities, and metric list.
  ///
  /// Used during device registration ("Test Connection") and on app startup
  /// to verify that a previously registered device is still reachable.
  /// If `/api/manifest` returns 404 (e.g. on LAT test firmware), falls back
  /// to querying `/data` and deriving a local registration identity.
  Future<Result<DeviceManifest, NetworkError>> fetchManifest(
      String baseUrl) async {
    final cleanUrl = _cleanUrl(baseUrl);
    try {
      final response = await _dio.get('$cleanUrl/api/manifest');
      final parsed = _decodeJsonMap(response.data);

      if (parsed == null) {
        return _fetchManifestFromLive(cleanUrl);
      }

      final manifest = DeviceManifest.fromJson(parsed);
      return Ok(manifest);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _fetchManifestFromLive(cleanUrl);
      }
      return Err(_mapDioError(e, cleanUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<DeviceManifest, NetworkError>> _fetchManifestFromLive(
      String cleanUrl) async {
    final result = await fetchLive(cleanUrl);
    return switch (result) {
      Ok(:final value) => Ok(DeviceManifest.fromLiveTelemetry(value, cleanUrl)),
      Err(:final error) => Err(error),
    };
  }

  // ---------------------------------------------------------------------------
  // GET /data, with GET /api/live as a legacy fallback
  // ---------------------------------------------------------------------------

  /// Fetches the latest real-time telemetry snapshot from the device.
  ///
  /// `/data` is the LAT firmware's primary endpoint. Older firmware may only
  /// expose `/api/live`, which is tried only when `/data` returns HTTP 404.
  Future<Result<LiveTelemetry, NetworkError>> fetchLive(String baseUrl) async {
    final cleanUrl = _cleanUrl(baseUrl);
    try {
      final response = await _dio.get('$cleanUrl/data');
      return _parseLiveResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return _fetchLegacyLive(cleanUrl);
      return Err(_mapDioError(e, cleanUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<LiveTelemetry, NetworkError>> _fetchLegacyLive(
      String cleanUrl) async {
    try {
      final response = await _dio.get('$cleanUrl/api/live');
      return _parseLiveResponse(response.data);
    } on DioException catch (e) {
      return Err(_mapDioError(e, cleanUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  // ---------------------------------------------------------------------------
  // GET /history (Placeholder for future follow-up integration)
  // ---------------------------------------------------------------------------

  /// Fetches raw historical records from `/history`.
  /// Note: Not invoked automatically on device detail to keep the app lightweight.
  Future<Result<dynamic, NetworkError>> fetchHistory(String baseUrl) async {
    final cleanUrl = _cleanUrl(baseUrl);
    try {
      final response = await _dio.get('$cleanUrl/history');
      return Ok(response.data);
    } on DioException catch (e) {
      return Err(_mapDioError(e, cleanUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Result<LiveTelemetry, NetworkError> _parseLiveResponse(dynamic data) {
    final parsed = _decodeJsonMap(data);
    if (parsed == null) {
      return const Err(ParseError('Live response is not a JSON object'));
    }
    return Ok(LiveTelemetry.fromJson(parsed, receivedAt: DateTime.now()));
  }

  Map<String, dynamic>? _decodeJsonMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) return null;
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Internal — Dio exception → NetworkError mapping
  // ---------------------------------------------------------------------------

  /// Maps a [DioException] to the appropriate [NetworkError] subtype.
  NetworkError _mapDioError(DioException e, String url) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const TimeoutError(),
      DioExceptionType.connectionError => UnreachableError(url),
      DioExceptionType.badResponse => e.response?.statusCode == 404
          ? NotFoundError(url)
          : UnknownNetworkError(e),
      _ => UnknownNetworkError(e),
    };
  }
}
