// lib/features/device/screens/device_list_screen.dart
//
// Lists all Device Nodes within a Sub-Sector.
// Each device card shows: ID, product type, base URL, and ConnectionPill.
// FAB navigates to DeviceFormScreen to add a new device.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_pill.dart';
import '../providers/device_providers.dart';

class DeviceListScreen extends ConsumerWidget {
  final int subSectorId;
  final String subSectorName;

  const DeviceListScreen({
    super.key,
    required this.subSectorId,
    required this.subSectorName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(watchDevicesProvider(subSectorId));
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return Scaffold(
      appBar: AppBar(
        title: Text(subSectorName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: devicesAsync.when(
        loading: () => const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (devices) {
          if (devices.isEmpty) {
            return _EmptyDeviceState(
              onAdd: () => context.push(
                  '/products/0/sub/$subSectorId/add-device'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: devices.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: borderColor),
            itemBuilder: (_, i) => _DeviceCard(
              device: devices[i],
              onDelete: () => _confirmDelete(context, ref, devices[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        elevation: 0,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: borderColor),
        ),
        onPressed: () =>
            context.push('/products/0/sub/$subSectorId/add-device'),
        child: Icon(Icons.add,
            size: 20,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
            'Remove "${device.name}"? All telemetry records will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.aqiPoor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(deviceMutationProvider.notifier).deleteDevice(device.id);
    }
  }
}

// ---------------------------------------------------------------------------
// Device card
// ---------------------------------------------------------------------------

class _DeviceCard extends ConsumerWidget {
  final Device device;
  final VoidCallback onDelete;

  const _DeviceCard({required this.device, required this.onDelete});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final textTheme = Theme.of(context).textTheme;

    // Passive connection check via handshake on render.
    // The FutureProvider.family caches by baseUrl so this is cheap.
    final handshake = ref.watch(deviceHandshakeProvider(device.baseUrl));
    final status = handshake.when(
      loading: () => ConnectionStatus.checking,
      error: (_, __) => ConnectionStatus.offline,
      data: (result) =>
          result.isOk ? ConnectionStatus.online : ConnectionStatus.offline,
    );

    return InkWell(
      onTap: () {}, // TODO(fase-3): navigate to device detail
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(device.name, style: textTheme.titleMedium),
                      const SizedBox(width: 8),
                      ConnectionPill(status: status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.id,
                    style: AppTheme.monoStyle(fontSize: 11)
                        .copyWith(color: mutedColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${device.productType}  ·  ${device.baseUrl}',
                    style: textTheme.bodySmall?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyDeviceState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyDeviceState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'NO DEVICES',
            style: AppTheme.monoStyle(fontSize: 11, fontWeight: FontWeight.w600)
                .copyWith(color: mutedColor, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to register your first device.',
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: mutedColor),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onAdd, child: const Text('Add Device')),
        ],
      ),
    );
  }
}
