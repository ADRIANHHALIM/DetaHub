// lib/core/network/device_api_service.dart
//
// Service layer for communicating with a DetaLab IoT device's local HTTP API.
//
// All public methods return Result<T, NetworkError> — they never throw.
// Dio exceptions are caught here and mapped to typed NetworkError subtypes,
// keeping the feature layer clean of HTTP-specific error handling.

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

  // ---------------------------------------------------------------------------
  // GET /api/manifest
  // ---------------------------------------------------------------------------

  /// Fetches device metadata, capabilities, and metric list.
  ///
  /// Used during device registration ("Test Connection") and on app startup
  /// to verify that a previously registered device is still reachable.
  Future<Result<DeviceManifest, NetworkError>> fetchManifest(
      String baseUrl) async {
    try {
      final response = await _dio.get('$baseUrl/api/manifest');
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        return const Err(ParseError('Manifest response is not a JSON object'));
      }

      final manifest = DeviceManifest.fromJson(data);
      return Ok(manifest);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return _fetchManifestFromLive(baseUrl);
      }
      return Err(_mapDioError(e, baseUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<DeviceManifest, NetworkError>> _fetchManifestFromLive(
      String baseUrl) async {
    final result = await fetchLive(baseUrl);
    return switch (result) {
      Ok(:final value) => Ok(DeviceManifest.fromLiveTelemetry(value, baseUrl)),
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
    try {
      final response = await _dio.get('$baseUrl/data');
      return _parseLiveResponse(response.data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return _fetchLegacyLive(baseUrl);
      return Err(_mapDioError(e, baseUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<LiveTelemetry, NetworkError>> _fetchLegacyLive(
      String baseUrl) async {
    try {
      final response = await _dio.get('$baseUrl/api/live');
      return _parseLiveResponse(response.data);
    } on DioException catch (e) {
      return Err(_mapDioError(e, baseUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Result<LiveTelemetry, NetworkError> _parseLiveResponse(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const Err(ParseError('Live response is not a JSON object'));
    }
    return Ok(LiveTelemetry.fromJson(data, receivedAt: DateTime.now()));
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
