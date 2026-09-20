// lib/core/network/providers/network_providers.dart
//
// Riverpod providers for the network layer.
// Exposes singleton Dio and DeviceApiService instances.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../dio_client.dart';
import '../device_api_service.dart';

/// Singleton [Dio] client shared across all network calls in the app.
/// The instance is created once and lives for the app's lifetime.
final dioClientProvider = Provider<Dio>((ref) {
  final dio = createDioClient();
  // Dispose Dio when the provider scope is destroyed (app exit).
  ref.onDispose(dio.close);
  return dio;
});

/// Singleton [DeviceApiService] backed by the shared Dio instance.
final deviceApiServiceProvider = Provider<DeviceApiService>((ref) {
  return DeviceApiService(ref.watch(dioClientProvider));
});
