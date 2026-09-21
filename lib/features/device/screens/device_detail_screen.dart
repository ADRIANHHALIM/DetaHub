// lib/features/device/screens/device_detail_screen.dart
//
// Dedicated Device Detail Screen (GitHub Issue #2).
// Displays live telemetry, health status, location context, and device management.
// Follows "Neutral by default. Color only communicates meaning."

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/daos/device_dao.dart';
import '../../../core/database/daos/telemetry_dao.dart';
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
  ConnectionStatus _connectionStatus = ConnectionStatus.checking;

  final List<double> _tempHistory = [];
  final List<double> _humidityHistory = [];
  final List<double> _eco2History = [];
  final List<double> _tvocHistory = [];
  Timer? _periodicPollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollLive();
    });
    _periodicPollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_fetchingLive) {
        _pollLive();
      }
    });
  }

  @override
  void dispose() {
    _periodicPollTimer?.cancel();
    super.dispose();
  }

  Future<void> _pollLive() async {
    final deviceAsync =
        ref.read(watchDeviceWithLocationProvider(widget.deviceId));
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
        await ref.read(telemetryDaoProvider).batchInsertRecords([
          TelemetryRecordsCompanion.insert(
            deviceId: deviceWithLoc.device.id,
            timestamp: value.timestamp,
            temperature: Value(value.temperature),
            humidity: Value(value.humidity),
            eco2: Value(value.eco2),
            tvoc: Value(value.tvoc),
            aqi: Value(value.aqi),
          ),
        ]);
        await ref
            .read(deviceDaoProvider)
            .updateLastSeen(deviceWithLoc.device.id, DateTime.now());
        if (!mounted) return;
        setState(() {
          _liveData = value;
          _fetchingLive = false;
          _connectionStatus = ConnectionStatus.online;
          _appendRealReading(value);
        });
      case Err(:final error):
        setState(() {
          _fetchingLive = false;
          _connectionStatus = ConnectionStatus.offline;
          _fetchError = _networkErrorMessage(error);
        });
    }
  }

  void _appendRealReading(LiveTelemetry value) {
    void append(List<double> target, num? reading) {
      if (reading == null) return;
      target.add(reading.toDouble());
      if (target.length > 25) target.removeAt(0);
    }

    append(_tempHistory, value.temperature);
    append(_humidityHistory, value.humidity);
    append(_eco2History, value.eco2);
    append(_tvocHistory, value.tvoc);
  }

  String _networkErrorMessage(NetworkError error) => switch (error) {
        TimeoutError() ||
        UnreachableError() =>
          'Device tidak dapat dihubungi. Pastikan ponsel dan perangkat berada di jaringan Wi-Fi yang sama.',
        NotFoundError() => 'Endpoint data perangkat tidak tersedia.',
        ParseError() => 'Data dari perangkat tidak dapat dibaca.',
        UnknownNetworkError() => 'Koneksi perangkat gagal. Coba lagi.',
      };

  @override
  Widget build(BuildContext context) {
    final deviceAsync =
        ref.watch(watchDeviceWithLocationProvider(widget.deviceId));
    final latestRecord = ref
        .watch(watchLatestTelemetryRecordProvider(widget.deviceId))
        .valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final surfaceVariant =
        isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariant;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
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
        final temperature = _liveData?.temperature ?? latestRecord?.temperature;
        final humidity = _liveData?.humidity ?? latestRecord?.humidity;
        final eco2 = _liveData?.eco2 ?? latestRecord?.eco2;
        final tvoc = _liveData?.tvoc ?? latestRecord?.tvoc;
        final aqiValue = _liveData?.aqi ?? latestRecord?.aqi;
        final lastTimestamp = _liveData?.timestamp ?? latestRecord?.timestamp;
        final isLive =
            _connectionStatus == ConnectionStatus.online && _liveData != null;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
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
                    child: Text('Remove Device',
                        style: TextStyle(color: AppColors.aqiPoor)),
                  ),
                ],
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Product Hardware & Location Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Image.asset(
                        'assets/images/LAT.webp',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${deviceWithLoc.areaName} · ${deviceWithLoc.locationName}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ConnectionPill(status: _connectionStatus),
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
                          'Air quality',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (aqiValue != null) AqiBadge(aqi: aqiValue),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          aqiValue?.toString() ?? '--',
                          style: AppTheme.monoStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (aqiValue != null)
                          Text(
                            AppColors.labelForAqi(aqiValue),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: textMuted),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aqiValue == null
                          ? 'Waiting for an AQI reading from the device.'
                          : _aqiDescription(aqiValue),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Environmental telemetry — only values received from hardware.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current readings',
                      style: Theme.of(context).textTheme.headlineMedium),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: surfaceVariant,
                      borderRadius: BorderRadius.circular(kRadiusChip),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: _connectionStatus == ConnectionStatus.online
                                ? AppColors.aqiGood
                                : textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Live · 3s poll',
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ).copyWith(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      label: 'Temperature',
                      value: temperature?.toStringAsFixed(1) ?? '--',
                      unit: '°C',
                      history: _tempHistory.length >= 2 ? _tempHistory : null,
                      chartColor: AppColors.metricTemperature,
                      trendLabel: '3s',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(
                      label: 'Humidity',
                      value: humidity?.toStringAsFixed(1) ?? '--',
                      unit: '%',
                      history: _humidityHistory.length >= 2
                          ? _humidityHistory
                          : null,
                      chartColor: AppColors.metricHumidity,
                      trendLabel: '3s',
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
                      value: eco2?.toString() ?? '--',
                      unit: 'ppm',
                      history: _eco2History.length >= 2 ? _eco2History : null,
                      chartColor: AppColors.metricEco2,
                      trendLabel: '3s',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MetricCard(
                      label: 'TVOC',
                      value: tvoc?.toString() ?? '--',
                      unit: 'ppb',
                      history: _tvocHistory.length >= 2 ? _tvocHistory : null,
                      chartColor: AppColors.metricTvoc,
                      trendLabel: '3s',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Text(
                lastTimestamp == null
                    ? 'Waiting for the first reading.'
                    : '${isLive ? 'Last update' : 'Last received'}: ${_formatTimestamp(lastTimestamp)}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: textSecondary),
              ),
              if (_tempHistory.length < 2) ...[
                const SizedBox(height: 4),
                Text(
                  'Recent trend will appear after two real readings.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: textMuted),
                ),
              ],

              const SizedBox(height: 24),

              // Technical details stay out of the primary data story.
              Text('About this device',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text('Technical details',
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text('Device ID, local address, and storage',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: textSecondary)),
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    _detailRow('Model', device.productType, context),
                    const Divider(height: 16),
                    _detailRow('Identifier', device.id, context),
                    const Divider(height: 16),
                    _detailRow('Local address', device.baseUrl, context),
                    const Divider(height: 16),
                    _detailRow('Storage', 'Stored locally', context),
                    const SizedBox(height: 4),
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
                      const Icon(Icons.info_outline,
                          size: 16, color: AppColors.aqiPoor),
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
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: textSecondary)),
        Text(value,
            style:
                AppTheme.monoStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _aqiDescription(int aqi) => switch (aqi) {
        1 => 'Air quality is satisfactory. Little or no risk of pollution.',
        2 =>
          'Air quality is acceptable. Moderate health concern for very sensitive people.',
        3 => 'Members of sensitive groups may experience health effects.',
        4 => 'Everyone may begin to experience health effects.',
        5 => 'Health alert: risk of more serious health effects for everyone.',
        _ => 'Air quality reading available.',
      };

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}:${twoDigits(local.second)}';
  }

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
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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
        content: Text(
            'Remove "${device.name}"? Telemetry records will be permanently removed.'),
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
      if (context.mounted) context.pop();
    }
  }
}
