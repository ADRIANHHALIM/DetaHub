// lib/core/network/device_api_service.dart
//
// Service layer for communicating with a DetaLab IoT device's local HTTP API.
//
// All public methods return Result<T, NetworkError> — they never throw.
// Dio exceptions are caught here and mapped to typed NetworkError subtypes,
// keeping the feature layer clean of HTTP-specific error handling.

import 'dart:convert';

import 'package:dio/dio.dart';

import 'models/device_file.dart';
import 'models/device_manifest.dart';
import 'models/live_telemetry.dart';
import 'network_error.dart';

/// Provides typed access to a DetaLab device's local HTTP endpoints.
///
/// Current LAT firmware exposes /data for the live snapshot. The original
/// /api/live contract is retained as a fallback for compatibility.
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

  // ---------------------------------------------------------------------------
  // Edge Storage File Operations (/listfiles, download, delete)
  // ---------------------------------------------------------------------------

  /// Queries GET /listfiles to discover historical logs stored on the ESP32.
  ///
  /// Uses [DeviceFile.parseListResponse] to adaptively parse JSON or plaintext lists.
  Future<Result<List<DeviceFile>, NetworkError>> listFiles(String baseUrl) async {
    final cleanUrl = _cleanUrl(baseUrl);
    try {
      final response = await _dio.get(
        '$cleanUrl/listfiles',
        options: Options(
          responseType: ResponseType.json,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final files = DeviceFile.parseListResponse(response.data);
      return Ok(files);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Test firmware may serve plaintext with text/plain
        return _listFilesPlaintextFallback(cleanUrl);
      }
      return Err(_mapDioError(e, cleanUrl));
    } on FormatException catch (e) {
      return Err(ParseError(e.message));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<List<DeviceFile>, NetworkError>> _listFilesPlaintextFallback(
    String cleanUrl,
  ) async {
    try {
      final response = await _dio.get(
        '$cleanUrl/listfiles',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      final files = DeviceFile.parseListResponse(response.data);
      return Ok(files);
    } on DioException catch (e) {
      return Err(_mapDioError(e, cleanUrl));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  /// Downloads raw CSV file contents from the device's flash storage.
  ///
  /// Requests as [ResponseType.plain] to avoid unnecessary JSON parsing.
  Future<Result<String, NetworkError>> downloadFile(
    String baseUrl,
    String fileName,
  ) async {
    final cleanUrl = _cleanUrl(baseUrl);
    final cleanFile = fileName.trim().replaceAll(RegExp(r'^\/+'), '');
    try {
      final response = await _dio.get<String>(
        '$cleanUrl/$cleanFile',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      final body = response.data ?? '';
      return Ok(body);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Fallback: try GET /files/<fileName>
        return _downloadFileFallback(cleanUrl, cleanFile);
      }
      return Err(_mapDioError(e, cleanUrl));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<String, NetworkError>> _downloadFileFallback(
    String cleanUrl,
    String cleanFile,
  ) async {
    try {
      final response = await _dio.get<String>(
        '$cleanUrl/files/$cleanFile',
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
      );
      return Ok(response.data ?? '');
    } on DioException catch (e) {
      return Err(_mapDioError(e, cleanUrl));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  /// Deletes an acknowledged historical file from the ESP32's flash storage.
  ///
  /// CRITICAL: Must ONLY be called after verified persistence in Drift SQLite.
  /// Treats HTTP 404 as already deleted (Ok(true)).
  Future<Result<bool, NetworkError>> deleteFile(
    String baseUrl,
    String fileName,
  ) async {
    final cleanUrl = _cleanUrl(baseUrl);
    final cleanFile = fileName.trim().replaceAll(RegExp(r'^\/+'), '');
    try {
      await _dio.delete(
        '$cleanUrl/$cleanFile',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      return const Ok(true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Already removed from flash — safely considered deleted
        return const Ok(true);
      }
      if (e.response?.statusCode == 405 || e.type == DioExceptionType.badResponse) {
        // Fallback: try POST /delete with payload
        return _deleteFileFallback(cleanUrl, cleanFile);
      }
      return Err(_mapDioError(e, cleanUrl));
    } catch (e) {
      return Err(UnknownNetworkError(e));
    }
  }

  Future<Result<bool, NetworkError>> _deleteFileFallback(
    String cleanUrl,
    String cleanFile,
  ) async {
    try {
      await _dio.post(
        '$cleanUrl/delete',
        data: {'file': cleanFile},
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );
      return const Ok(true);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Ok(true);
      }
      return Err(_mapDioError(e, cleanUrl));
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
