// test/core/network/device_api_service_delete_test.dart
//
// Regression tests for DeviceApiService.deleteFile() fallback and 404 safety (Group C).

import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:detahub/core/network/device_api_service.dart';
import 'package:detahub/core/network/network_error.dart';

void main() {
  const baseUrl = 'http://192.168.1.100';
  const testFile = 'data_2026-09-20.csv';

  group('Group C: DeviceApiService deleteFile Fallback & 404 Safety (19-25)', () {
    test('19. DELETE success returns Ok(true)', () async {
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE' && options.path.endsWith('/$testFile')) {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
            ));
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      expect(result.isOk, isTrue);
      expect(result.value, isTrue);
    });

    test('20. HTTP 405 triggers POST /delete fallback and succeeds', () async {
      bool postFallbackCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 405),
              type: DioExceptionType.badResponse,
            ));
          }
          if (options.method == 'POST' && options.path.endsWith('/delete')) {
            postFallbackCalled = true;
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
            ));
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      expect(postFallbackCalled, isTrue);
      expect(result.isOk, isTrue);
      expect(result.value, isTrue);
    });

    test('21. HTTP 501 triggers POST /delete fallback and succeeds', () async {
      bool postFallbackCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 501),
              type: DioExceptionType.badResponse,
            ));
          }
          if (options.method == 'POST' && options.path.endsWith('/delete')) {
            postFallbackCalled = true;
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
            ));
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      expect(postFallbackCalled, isTrue);
      expect(result.isOk, isTrue);
      expect(result.value, isTrue);
    });

    test('22. HTTP 400 does NOT trigger fallback and returns error', () async {
      bool postFallbackCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 400),
              type: DioExceptionType.badResponse,
            ));
          }
          if (options.method == 'POST') {
            postFallbackCalled = true;
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      expect(postFallbackCalled, isFalse);
      expect(result.isErr, isTrue);
    });

    test('23. HTTP 403 does NOT trigger fallback and returns error', () async {
      bool postFallbackCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 403),
              type: DioExceptionType.badResponse,
            ));
          }
          if (options.method == 'POST') {
            postFallbackCalled = true;
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      expect(postFallbackCalled, isFalse);
      expect(result.isErr, isTrue);
    });

    test('24. HTTP 404 does NOT report success and does NOT fallback (unconfirmed deletion)', () async {
      bool postFallbackCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 404),
              type: DioExceptionType.badResponse,
            ));
          }
          if (options.method == 'POST') {
            postFallbackCalled = true;
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      // CRITICAL: Must NOT be treated as success unless documented contract exists
      expect(postFallbackCalled, isFalse);
      expect(result.isErr, isTrue);
      expect(result.error, isA<NotFoundError>());
    });

    test('25. HTTP 500 does NOT trigger fallback and returns error', () async {
      bool postFallbackCalled = false;
      final dio = Dio();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.method == 'DELETE') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 500),
              type: DioExceptionType.badResponse,
            ));
          }
          if (options.method == 'POST') {
            postFallbackCalled = true;
          }
          return handler.next(options);
        },
      ));

      final api = DeviceApiService(dio);
      final result = await api.deleteFile(baseUrl, testFile);

      expect(postFallbackCalled, isFalse);
      expect(result.isErr, isTrue);
    });
  });
}
