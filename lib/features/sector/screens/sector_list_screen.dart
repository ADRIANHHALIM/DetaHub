// lib/features/sector/screens/sector_list_screen.dart
//
// Primary home screen: Sector hierarchy tree.
// Displays all Sectors as expandable tiles with their Sub-Sectors.
// Tapping a Sub-Sector navigates to its Device list.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/daos/sector_dao.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/sector_providers.dart';
import 'sector_form_bottom_sheet.dart';

class SectorListScreen extends ConsumerWidget {
  const SectorListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hierarchyAsync = ref.watch(watchFullHierarchyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DetaHub'),
        actions: [
          // Add Sector button
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            tooltip: 'Add Sector',
            onPressed: () => _showAddSectorSheet(context, ref),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: hierarchyAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: Theme.of(context).textTheme.bodySmall),
        ),
        data: (hierarchy) {
          if (hierarchy.isEmpty) {
            return _EmptyState(onAdd: () => _showAddSectorSheet(context, ref));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: hierarchy.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: borderColor),
            itemBuilder: (context, index) {
              final item = hierarchy[index];
              return _SectorTile(
                item: item,
                onAddSubSector: () =>
                    _showAddSubSectorSheet(context, ref, item.sector.id),
                onDeleteSector: () =>
                    _confirmDeleteSector(context, ref, item.sector.id, item.sector.name),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddSectorSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => SectorFormBottomSheet(
        title: 'Add Sector',
        hint: 'e.g. Universitas Trisakti',
        onSave: (name) async {
          await ref.read(sectorMutationProvider.notifier).addSector(name);
        },
      ),
    );
  }

  void _showAddSubSectorSheet(
      BuildContext context, WidgetRef ref, int sectorId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
        side: BorderSide(color: AppColors.border),
      ),
      builder: (_) => SectorFormBottomSheet(
        title: 'Add Sub-Sector',
        hint: 'e.g. Lab IoT Lt.3',
        onSave: (name) async {
          await ref
              .read(subSectorMutationProvider.notifier)
              .addSubSector(sectorId, name);
        },
      ),
    );
  }

  Future<void> _confirmDeleteSector(
      BuildContext context, WidgetRef ref, int id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sector'),
        content: Text(
          'Delete "$name"? All sub-sectors, devices, and telemetry data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.aqiPoor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(sectorMutationProvider.notifier).deleteSector(id);
    }
  }
}

// ---------------------------------------------------------------------------
// Sector expansion tile
// ---------------------------------------------------------------------------

class _SectorTile extends ConsumerWidget {
  final SectorWithSubSectors item;
  final VoidCallback onAddSubSector;
  final VoidCallback onDeleteSector;

  const _SectorTile({
    required this.item,
    required this.onAddSubSector,
    required this.onDeleteSector,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      childrenPadding: EdgeInsets.zero,
      expandedAlignment: Alignment.topLeft,
      shape: const Border(),          // No rounded decoration on expand
      collapsedShape: const Border(),
      title: Row(
        children: [
          Expanded(
            child: Text(
              item.sector.name,
              style: textTheme.titleMedium,
            ),
          ),
          // Sub-sector count chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              '${item.subSectors.length}',
              style: AppTheme.monoStyle(fontSize: 10).copyWith(color: mutedColor),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.add, size: 16, color: mutedColor),
            tooltip: 'Add Sub-Sector',
            onPressed: onAddSubSector,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 16, color: mutedColor),
            tooltip: 'Delete Sector',
            onPressed: onDeleteSector,
          ),
        ],
      ),
      children: [
        if (item.subSectors.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 8, 16, 12),
            child: Text(
              'No sub-sectors. Tap + to add one.',
              style: textTheme.bodySmall?.copyWith(color: mutedColor),
            ),
          )
        else
          ...item.subSectors.map((ss) => _SubSectorRow(ss: ss)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-sector row within expansion
// ---------------------------------------------------------------------------

class _SubSectorRow extends ConsumerWidget {
  final SubSectorWithDeviceCount ss;

  const _SubSectorRow({required this.ss});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => context.push('/sectors/${ss.subSector.sectorId}/sub/${ss.subSector.id}'),
      onLongPress: () => _confirmDelete(context, ref),
      child: Container(
        padding: const EdgeInsets.fromLTRB(32, 10, 16, 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(ss.subSector.name, style: textTheme.bodyMedium),
            ),
            // Device count
            Text(
              '${ss.deviceCount} device${ss.deviceCount == 1 ? '' : 's'}',
              style: AppTheme.monoStyle(fontSize: 10).copyWith(color: mutedColor),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sub-Sector'),
        content: Text(
            'Delete "${ss.subSector.name}"? All devices and telemetry data will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.aqiPoor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref
          .read(subSectorMutationProvider.notifier)
          .deleteSubSector(ss.subSector.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO SECTORS',
            style: AppTheme.monoStyle(fontSize: 11, fontWeight: FontWeight.w600)
                .copyWith(color: mutedColor, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first location.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onAdd,
            child: const Text('Add Sector'),
          ),
        ],
      ),
    );
  }
}
