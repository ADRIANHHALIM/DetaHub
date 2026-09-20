// lib/features/sector/screens/locations_screen.dart
//
// Locations & Areas Screen (GitHub Issue #2).
// Implements the user mental model:
//   Location (Sector) → Area (Sub-Sector) → Device
// Clean, natural hierarchy without raw database terminology.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/sector_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_pill.dart';
import '../../device/providers/device_providers.dart';
import '../providers/sector_providers.dart';

class LocationsScreen extends ConsumerWidget {
  const LocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hierarchyAsync = ref.watch(watchFullHierarchyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined, size: 20),
            tooltip: 'Add Location',
            onPressed: () => _promptAddLocation(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: hierarchyAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
        error: (e, _) => Center(child: Text('Error loading locations: $e')),
        data: (hierarchy) {
          if (hierarchy.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.domain_outlined, size: 48, color: textMuted),
                    const SizedBox(height: 16),
                    Text(
                      'No locations yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Organize your devices by campus, office, building, or room.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => _promptAddLocation(context, ref),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Location'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: hierarchy.length,
            itemBuilder: (context, index) {
              final item = hierarchy[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: const Icon(Icons.apartment_outlined, size: 20, color: AppColors.textPrimary),
                    title: Text(
                      item.sector.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Text(
                      '${item.subSectors.length} area${item.subSectors.length == 1 ? '' : 's'}',
                      style: AppTheme.monoStyle(fontSize: 11, color: textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.add, size: 18, color: textSecondary),
                          tooltip: 'Add Area',
                          onPressed: () => _promptAddArea(context, ref, item.sector.id),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: textSecondary),
                          tooltip: 'Delete Location',
                          onPressed: () => _confirmDeleteLocation(context, ref, item.sector.id, item.sector.name),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(height: 1),
                      if (item.subSectors.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No areas added yet. Tap + to add an area (e.g. Lab IoT, Server Room).',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textMuted),
                          ),
                        )
                      else
                        ...item.subSectors.map((ss) => _AreaCard(subSector: ss)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _promptAddLocation(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Location'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Universitas Trisakti, Head Office'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(sectorMutationProvider.notifier).addSector(name);
    }
  }

  Future<void> _promptAddArea(BuildContext context, WidgetRef ref, int sectorId) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Area'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Lab IoT, Ruang Server, Lt. 3'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await ref.read(subSectorMutationProvider.notifier).addSubSector(sectorId, name);
    }
  }

  Future<void> _confirmDeleteLocation(BuildContext context, WidgetRef ref, int sectorId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Location'),
        content: Text('Delete "$name"? All areas and device associations will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.aqiPoor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(sectorMutationProvider.notifier).deleteSector(sectorId);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Area Item with its Devices
// ─────────────────────────────────────────────────────────────────────────
class _AreaCard extends ConsumerWidget {
  final SubSectorWithDeviceCount subSector;

  const _AreaCard({required this.subSector});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(watchDevicesProvider(subSector.subSector.id));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: surfaceVariant.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subSector.subSector.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Text(
                '${subSector.deviceCount} device${subSector.deviceCount == 1 ? '' : 's'}',
                style: AppTheme.monoStyle(fontSize: 10, color: textSecondary),
              ),
            ],
          ),

          // Devices within this area
          devicesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (devices) {
              if (devices.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.only(left: 24, top: 6, bottom: 4),
                  child: Text(
                    'No devices assigned to this area.',
                    style: AppTheme.monoStyle(fontSize: 10, color: textMuted),
                  ),
                );
              }

              return Column(
                children: devices.map((d) {
                  return InkWell(
                    onTap: () => context.push('/devices/${d.id}'),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 8, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.air, size: 14, color: AppColors.aqiGood),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              d.name,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const ConnectionPill(status: ConnectionStatus.online),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
