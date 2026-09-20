// lib/core/network/dio_client.dart
//
// Singleton Dio HTTP client configured for DetaHub's local-LAN use case.
//
// Key design decisions:
//   - Aggressive 5s connect timeout: LAN devices should respond near-instantly.
//     A 5s timeout surfaces "device offline" errors quickly without blocking the UI.
//   - No retry interceptor: retries are owned by the caller (e.g., a "Retry" button).
//   - LogInterceptor is only attached in debug builds (kDebugMode guard) so
//     sensitive local network addresses are never logged in release builds.
//   - Base URL is NOT set here — each device has a different IP/URL, so the
//     full URL is passed per-request in DeviceApiService.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Creates and configures the shared Dio instance for DetaHub.
///
/// Do not call directly — use [DioClientProvider] to access the singleton.
Dio createDioClient() {
  final dio = Dio(
    BaseOptions(
      // Aggressive timeouts for local LAN IoT devices.
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 5),

      // Expect JSON from /api/manifest and /api/live.
      // CSV is fetched with responseType: ResponseType.plain per-request.
      responseType: ResponseType.json,

      // Standard headers for all requests.
      headers: const {
        'Accept': 'application/json',
        'User-Agent': 'DetaHub/2.0 (flutter)',
      },
    ),
  );

  // Attach logging only in debug mode.
  // This prevents IP addresses from appearing in release logs.
  if (kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
        error: true,
      ),
    );
  }

  return dio;
}
