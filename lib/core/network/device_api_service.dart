// lib/core/network/device_api_service.dart

import 'package:dio/dio.dart';

import 'network_error.dart';
import 'models/device_manifest.dart';
import 'models/live_telemetry.dart';

/// Local HTTP API client for DetaLab edge devices.
///
/// Current LAT firmware exposes /data for the live snapshot. The original
/// /api/live contract is retained as a fallback for compatibility.
class DeviceApiService {
  final Dio _dio;

  const DeviceApiService(this._dio);

  Future<Result<DeviceManifest, NetworkError>> fetchManifest(
      String baseUrl) async {
    try {
      try {
        final response = await _dio.get('$baseUrl/api/manifest');
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          return const Err(ParseError('Manifest response is not a JSON object'));
        }
        return Ok(DeviceManifest.fromJson(data));
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          return Err(_mapDioError(e, baseUrl));
        }
      }

      final response = await _dio.get('$baseUrl/data');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const Err(ParseError('Device data response is not a JSON object'));
      }

      return Ok(
        DeviceManifest.fromDataJson(
          data,
          fallbackDeviceId: _fallbackDeviceId(baseUrl),
        ),
      );
    } on DioException catch (e) {
      return Err(_mapDioError(e, baseUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  /// /data is the primary endpoint for the current LAT test firmware.
  /// /api/live remains supported for older firmware.
  Future<Result<LiveTelemetry, NetworkError>> fetchLive(
      String baseUrl) async {
    try {
      Response<dynamic> response;
      try {
        response = await _dio.get('$baseUrl/data');
      } on DioException catch (e) {
        if (e.response?.statusCode != 404) {
          return Err(_mapDioError(e, baseUrl));
        }
        response = await _dio.get('$baseUrl/api/live');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return const Err(ParseError('Live response is not a JSON object'));
      }

      return Ok(LiveTelemetry.fromJson(data));
    } on DioException catch (e) {
      return Err(_mapDioError(e, baseUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  String _fallbackDeviceId(String baseUrl) {
    final uri = Uri.tryParse(baseUrl);
    final host = uri?.host;
    if (host == null || host.isEmpty) {
      return 'lat-local';
    }
    return 'lat-' + host.replaceAll('.', '-');
  }

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
