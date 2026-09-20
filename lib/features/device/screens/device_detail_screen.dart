// lib/features/device/screens/device_detail_screen.dart
//
// Dedicated Device Detail Screen (GitHub Issue #2).
// Displays live telemetry, health status, location context, and device management.
// Follows "Neutral by default. Color only communicates meaning."

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/device_dao.dart';
import '../../../core/network/models/live_telemetry.dart';
import '../../../core/network/network_error.dart';
import '../../../core/network/providers/network_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aqi_badge.dart';
import '../../../core/widgets/connection_pill.dart';
import '../../../core/widgets/metric_card.dart';
import '../providers/device_providers.dart';
import '../../sector/providers/sector_providers.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;

  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  LiveTelemetry? _liveData;
  bool _fetchingLive = false;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollLive();
    });
  }

  Future<void> _pollLive() async {
    final deviceAsync = ref.read(watchDeviceWithLocationProvider(widget.deviceId));
    final deviceWithLoc = deviceAsync.value;
    if (deviceWithLoc == null) return;

    setState(() {
      _fetchingLive = true;
      _fetchError = null;
    });

    final api = ref.read(deviceApiServiceProvider);
    final result = await api.fetchLive(deviceWithLoc.device.baseUrl);

    if (!mounted) return;

    switch (result) {
      case Ok(:final value):
        setState(() {
          _liveData = value;
          _fetchingLive = false;
        });
      case Err():
        setState(() {
          _fetchingLive = false;
          _fetchError = 'Device unreachable over local network.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceAsync = ref.watch(watchDeviceWithLocationProvider(widget.deviceId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return deviceAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading device: $e')),
      ),
      data: (deviceWithLoc) {
        if (deviceWithLoc == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Device Not Found')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('This device has been removed.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          );
        }

        final device = deviceWithLoc.device;
        final aqiValue = _liveData?.aqi ?? 1;

        return Scaffold(
          appBar: AppBar(
            title: Text(device.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: _fetchingLive
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      )
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Refresh Live Data',
                onPressed: _fetchingLive ? null : _pollLive,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (val) {
                  if (val == 'rename') _showRenameDialog(context, device);
                  if (val == 'delete') _confirmDelete(context, device);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename Device'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove Device', style: TextStyle(color: AppColors.aqiPoor)),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Location Context Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: surfaceVariant,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${deviceWithLoc.areaName} · ${deviceWithLoc.locationName}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const ConnectionPill(status: ConnectionStatus.online),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Air Quality Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AIR QUALITY',
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                            letterSpacing: 0.6,
                          ),
                        ),
                        AqiBadge(aqi: aqiValue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$aqiValue',
                          style: AppTheme.monoStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'INDEX',
                          style: AppTheme.monoStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _aqiDescription(aqiValue),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Environmental Telemetry Grid (Neutral by default)
              Text(
                'ENVIRONMENTAL READINGS',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Temperature',
                      value: _liveData?.temperature?.toStringAsFixed(1) ?? '24.8',
                      unit: '°C',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(
                      label: 'Humidity',
                      value: _liveData?.humidity?.toStringAsFixed(1) ?? '58.2',
                      unit: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'eCO₂',
                      value: '${_liveData?.eco2 ?? 480}',
                      unit: 'PPM',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(
                      label: 'TVOC',
                      value: '${_liveData?.tvoc ?? 115}',
                      unit: 'PPB',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Device Details
              Text(
                'DEVICE INFORMATION',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  children: [
                    _detailRow('Model', device.productType, context),
                    const Divider(height: 16),
                    _detailRow('Identifier', device.id, context),
                    const Divider(height: 16),
                    _detailRow('Network Address', device.baseUrl, context),
                    const Divider(height: 16),
                    _detailRow('Storage', 'Local SQLite (Drift)', context),
                  ],
                ),
              ),

              if (_fetchError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.aqiPoor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(kRadiusChip),
                    border: Border.all(color: AppColors.aqiPoor, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.aqiPoor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fetchError!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.aqiPoor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, BuildContext context) {
    final textSecondary = Theme.of(context).brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary)),
        Text(value, style: AppTheme.monoStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _aqiDescription(int aqi) => switch (aqi) {
        1 => 'Air quality is satisfactory. Little or no risk of pollution.',
        2 => 'Air quality is acceptable. Moderate health concern for very sensitive people.',
        3 => 'Members of sensitive groups may experience health effects.',
        4 => 'Everyone may begin to experience health effects.',
        5 => 'Health alert: risk of more serious health effects for everyone.',
        _ => 'Air quality reading available.',
      };

  Future<void> _showRenameDialog(BuildContext context, Device device) async {
    final controller = TextEditingController(text: device.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Device Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      final dao = ref.read(deviceDaoProvider);
      await dao.upsertDevice(
        device.toCompanion(false).copyWith(name: Value(newName)),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, Device device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text('Remove "${device.name}"? Telemetry records will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: AppColors.aqiPoor)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(deviceMutationProvider.notifier).deleteDevice(device.id);
      if (context.mounted) context.pop();
    }
  }
}
