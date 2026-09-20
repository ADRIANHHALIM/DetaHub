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

import '../../features/device/screens/device_form_screen.dart';
import '../../features/device/screens/device_list_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/sector/screens/products_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../widgets/floating_nav_bar.dart';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    routes: [
      // Shell route provides the persistent bottom navigation bar.
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          // Tab 0: Home dashboard
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),

          // Tab 1: Products (Sector hierarchy)
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductsScreen(),
            ),
            routes: [
              // Sub-Sector → Device list
              GoRoute(
                path: ':sectorId/sub/:subSectorId',
                pageBuilder: (context, state) {
                  final subSectorId =
                      int.parse(state.pathParameters['subSectorId']!);
                  // Sub-sector name is passed as a query param for the AppBar title.
                  final name =
                      state.uri.queryParameters['name'] ?? 'Devices';
                  return MaterialPage(
                    child: DeviceListScreen(
                      subSectorId: subSectorId,
                      subSectorName: name,
                    ),
                  );
                },
                routes: [
                  // Add device form
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

          // Tab 1: Settings
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

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
            icon: Icons.dashboard_outlined,
            selectedIcon: Icons.dashboard,
            label: 'Home',
          ),
          FloatingNavDestination(
            icon: Icons.device_hub_outlined,
            selectedIcon: Icons.device_hub,
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
