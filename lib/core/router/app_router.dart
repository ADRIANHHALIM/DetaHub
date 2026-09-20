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
import '../../features/sector/screens/sector_list_screen.dart';
import '../../features/settings/screens/settings_screen.dart';

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/sectors',
    debugLogDiagnostics: false,
    routes: [
      // Shell route provides the persistent bottom navigation bar.
      ShellRoute(
        builder: (context, state, child) {
          return _AppShell(child: child);
        },
        routes: [
          // Tab 0: Sector hierarchy
          GoRoute(
            path: '/sectors',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SectorListScreen(),
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

  static const _tabs = ['/sectors', '/settings'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/settings')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        // 1px top border — DetaDesign: no elevation, explicit border instead.
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: currentIndex,
          elevation: 0,
          height: 60,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index != currentIndex) {
              context.go(_tabs[index]);
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.device_hub_outlined),
              selectedIcon: Icon(Icons.device_hub),
              label: 'Devices',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
