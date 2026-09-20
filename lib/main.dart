// lib/main.dart
//
// DetaHub application entry point.
//
// Architecture notes:
//   - ProviderScope is the root — wraps the entire widget tree so all
//     Riverpod providers are accessible everywhere.
//   - AppDatabase is initialized lazily via [appDatabaseProvider] on first
//     access; the connection is closed when the scope is disposed.
//   - GoRouter is provided via [appRouterProvider] and wired into
//     MaterialApp.router — no Navigator 1.0 usage.
//   - Theme is supplied here; features read colors via Theme.of(context)
//     or directly from AppColors static constants.
//   - No logic lives here — it is a wiring file only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Ensure Flutter engine is initialized before any platform channel call
  // (required for path_provider and sqlite3 on startup).
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is the Riverpod dependency injection container.
    // All providers (AppDatabase, DAOs, Dio, Router) are scoped here.
    const ProviderScope(
      child: DetaHubApp(),
    ),
  );
}

class DetaHubApp extends ConsumerWidget {
  const DetaHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DetaHub',
      debugShowCheckedModeBanner: false,

      // Light mode (default: Crisp Light) / Dark OLED mode.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // Respects device OS preference.

      // GoRouter wiring — replaces home/routes/onGenerateRoute.
      routerConfig: router,
    );
  }
}
