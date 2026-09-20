// lib/main.dart
//
// DetaHub application entry point.
//
// Architecture notes:
//   - ProviderScope is the root — wraps the entire widget tree so all
//     Riverpod providers are accessible everywhere.
//   - AppDatabase is initialized lazily via [appDatabaseProvider] on first
//     access; the connection is closed when the scope is disposed.
//   - Theme is supplied here; features read colors via Theme.of(context)
//     or directly from AppColors static constants.
//   - No logic lives here — it is a wiring file only.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';

void main() {
  // Ensure Flutter engine is initialized before any platform channel call
  // (required for path_provider and sqlite3 on startup).
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    // ProviderScope is the Riverpod dependency injection container.
    // All providers (AppDatabase, DAOs, etc.) are scoped here.
    const ProviderScope(
      child: DetaHubApp(),
    ),
  );
}

class DetaHubApp extends StatelessWidget {
  const DetaHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DetaHub',
      debugShowCheckedModeBanner: false,

      // Light mode (default: Crisp Light) / Dark OLED mode.
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // Respects device OS preference.

      // TODO(fase-2): Replace with GoRouter when navigation is implemented.
      home: const _PlaceholderHome(),
    );
  }
}

/// Temporary placeholder home screen.
/// Will be replaced in Fase 2 when the navigation shell is implemented.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('DetaHub')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FASE 1 COMPLETE',
              style: AppTheme.monoStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Core Foundation & Database',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
