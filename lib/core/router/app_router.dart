// lib/core/router/app_router.dart
//
// GoRouter configuration for DetaHub.
//
// Route tree:
//   /sectors                         → SectorListScreen (shell tab 0)
//   /sectors/:sectorId/sub/:subId    → DeviceListScreen
//   /sectors/:sId/sub/:ssId/add-device → DeviceFormScreen
//   /settings                        → SettingsScreen (shell tab 1)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/device/screens/add_device_wizard_screen.dart';
import '../../features/device/screens/device_detail_screen.dart';
import '../../features/device/screens/device_form_screen.dart';
import '../../features/device/screens/device_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/product/screens/lat_product_detail_screen.dart';
import '../../features/product/screens/products_screen.dart';
import '../../features/sector/screens/locations_screen.dart';
import '../../features/settings/screens/appearance_screen.dart';
import '../../features/settings/screens/backup_screen.dart';
import '../../features/settings/screens/restore_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/storage_screen.dart';
import '../widgets/floating_nav_bar.dart';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    routes: [
      // Global routes pushed on root navigator (full-screen modal/dedicated view)
      GoRoute(
        path: '/add-device',
        pageBuilder: (context, state) => const MaterialPage(
          fullscreenDialog: true,
          child: AddDeviceWizardScreen(),
        ),
      ),
      GoRoute(
        path: '/devices/:deviceId',
        pageBuilder: (context, state) {
          final deviceId = state.pathParameters['deviceId']!;
          return MaterialPage(
            child: DeviceDetailScreen(deviceId: deviceId),
          );
        },
      ),
      GoRoute(
        path: '/products/lat',
        pageBuilder: (context, state) => const MaterialPage(
          child: LatProductDetailScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/appearance',
        pageBuilder: (context, state) => const MaterialPage(
          child: AppearanceScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/backup',
        pageBuilder: (context, state) => const MaterialPage(
          child: BackupScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/restore',
        pageBuilder: (context, state) => const MaterialPage(
          child: RestoreScreen(),
        ),
      ),
      GoRoute(
        path: '/settings/storage',
        pageBuilder: (context, state) {
          final deviceId = state.uri.queryParameters['deviceId'];
          return MaterialPage(
            child: StorageScreen(initialDeviceId: deviceId),
          );
        },
      ),

      // Shell route provides the persistent bottom navigation bar.
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          // Tab 0: Home dashboard
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _smoothTabPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),

          // Tab 1: Product catalogue. Locations remain contextual navigation.
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => _smoothTabPage(
              key: state.pageKey,
              child: const ProductsScreen(),
            ),
          ),

          // Secondary hierarchy navigation.
          GoRoute(
            path: '/locations',
            pageBuilder: (context, state) => _smoothTabPage(
              key: state.pageKey,
              child: const LocationsScreen(),
            ),
            routes: [
              // Sub-Sector / Area → Device list drill-down
              GoRoute(
                path: ':sectorId/sub/:subSectorId',
                pageBuilder: (context, state) {
                  final subSectorId =
                      int.parse(state.pathParameters['subSectorId']!);
                  final name = state.uri.queryParameters['name'] ?? 'Devices';
                  return MaterialPage(
                    child: DeviceListScreen(
                      subSectorId: subSectorId,
                      subSectorName: name,
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'add-device',
                    pageBuilder: (context, state) {
                      final subSectorId =
                          int.parse(state.pathParameters['subSectorId']!);
                      return MaterialPage(
                        child: DeviceFormScreen(subSectorId: subSectorId),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Tab 2: Settings
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => _smoothTabPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

Page<dynamic> _smoothTabPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeIn = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      final fadeOut = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(fadeOut),
        child: FadeTransition(
          opacity: fadeIn,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.02),
              end: Offset.zero,
            ).animate(fadeIn),
            child: child,
          ),
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// App shell with bottom navigation bar
// ---------------------------------------------------------------------------

class _AppShell extends StatelessWidget {
  final Widget child;

  const _AppShell({required this.child});

  static const _tabs = ['/home', '/products', '/settings'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      extendBody: true, // Allow body to flow under the floating nav bar
      bottomNavigationBar: FloatingNavBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index != currentIndex) {
            context.go(_tabs[index]);
          }
        },
        destinations: const [
          FloatingNavDestination(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          FloatingNavDestination(
            icon: Icons.inventory_2_outlined,
            selectedIcon: Icons.inventory_2,
            label: 'Products',
          ),
          FloatingNavDestination(
            icon: Icons.tune_outlined,
            selectedIcon: Icons.tune,
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
