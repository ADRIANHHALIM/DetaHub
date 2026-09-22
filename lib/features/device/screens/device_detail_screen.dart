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
import '../../../core/sync/models/sync_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/aqi_badge.dart';
import '../../../core/widgets/connection_pill.dart';
import '../../../core/widgets/detahub_button.dart';
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

  int _syncRetryAttempts = 0;
  DateTime? _nextSyncRetryTime;
  static const _retryCooldowns = [
    Duration(seconds: 30),
    Duration(seconds: 60),
    Duration(seconds: 120),
    Duration(seconds: 300),
  ];

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

  void _triggerSync(String deviceId, String baseUrl, String? activeFileName) {
    ref.read(deviceSyncControllerProvider(deviceId).notifier).syncDevice(
          deviceId: deviceId,
          baseUrl: baseUrl,
          activeFileName: activeFileName,
        );
  }

  void _triggerManualSync() {
    final deviceAsync =
        ref.read(watchDeviceWithLocationProvider(widget.deviceId));
    final deviceWithLoc = deviceAsync.value;
    if (deviceWithLoc == null) return;

    // Reset backoff on explicit user intent
    _syncRetryAttempts = 0;
    _nextSyncRetryTime = null;

    _triggerSync(
      deviceWithLoc.device.id,
      deviceWithLoc.device.baseUrl,
      _liveData?.fileName,
    );
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
        final wasOnline = _connectionStatus == ConnectionStatus.online;
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
          // Single honest sample per reading (no duplicates)
          if (value.temperature != null) {
            _tempHistory.add(value.temperature!);
            if (_tempHistory.length > 120) _tempHistory.removeAt(0);
          }
          if (value.humidity != null) {
            _humidityHistory.add(value.humidity!);
            if (_humidityHistory.length > 120) _humidityHistory.removeAt(0);
          }
          if (value.eco2 != null) {
            _eco2History.add(value.eco2!.toDouble());
            if (_eco2History.length > 120) _eco2History.removeAt(0);
          }
          if (value.tvoc != null) {
            _tvocHistory.add(value.tvoc!.toDouble());
            if (_tvocHistory.length > 120) _tvocHistory.removeAt(0);
          }
          _fetchingLive = false;
          _connectionStatus = ConnectionStatus.online;
        });

        // Bounded reconciliation trigger & retry schedule
        final currentSyncState = ref
            .read(deviceSyncStateProvider(deviceWithLoc.device.id))
            .valueOrNull;

        if (!wasOnline) {
          // Transition offline -> online: trigger reconciliation immediately
          _syncRetryAttempts = 0;
          _nextSyncRetryTime = null;
          _triggerSync(
            deviceWithLoc.device.id,
            deviceWithLoc.device.baseUrl,
            value.fileName,
          );
        } else {
          // Device remains online: evaluate bounded retry without spamming polls
          if (currentSyncState is SyncFailed) {
            final now = DateTime.now();
            if (_nextSyncRetryTime == null) {
              final cooldownIndex = _syncRetryAttempts < _retryCooldowns.length
                  ? _syncRetryAttempts
                  : _retryCooldowns.length - 1;
              _nextSyncRetryTime = now.add(_retryCooldowns[cooldownIndex]);
            } else if (now.isAfter(_nextSyncRetryTime!)) {
              _syncRetryAttempts++;
              _nextSyncRetryTime = null;
              _triggerSync(
                deviceWithLoc.device.id,
                deviceWithLoc.device.baseUrl,
                value.fileName,
              );
            }
          } else if (currentSyncState is SyncCompleted &&
              currentSyncState.result.isCleanSuccess) {
            // Clean reconciliation succeeded: reset retry state
            _syncRetryAttempts = 0;
            _nextSyncRetryTime = null;
          }
        }
      case Err(:final error):
        setState(() {
          _fetchingLive = false;
          _connectionStatus = ConnectionStatus.offline;
          _fetchError = _networkErrorMessage(error);
        });
    }
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
    final syncState =
        ref.watch(deviceSyncStateProvider(widget.deviceId)).valueOrNull;
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
              const SizedBox(height: 12),

              // Offline Historical Reconciliation Status
              _buildSyncBanner(syncState, context, borderColor, surfaceVariant),

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
                            color: switch (_connectionStatus) {
                              ConnectionStatus.online => AppColors.aqiGood,
                              ConnectionStatus.offline => AppColors.aqiPoor,
                              ConnectionStatus.checking =>
                                AppColors.aqiModerate,
                              ConnectionStatus.unknown => textMuted,
                            },
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          switch (_connectionStatus) {
                            ConnectionStatus.online => 'Live · 3s poll',
                            ConnectionStatus.offline => 'Offline · Last known',
                            ConnectionStatus.checking => 'Checking…',
                            ConnectionStatus.unknown => 'Unknown',
                          },
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ).copyWith(
                            color: _connectionStatus == ConnectionStatus.offline
                                ? AppColors.aqiPoor
                                : textSecondary,
                          ),
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

              // Local telemetry table preview & centralized storage management link
              _DeviceDataPreview(device: device),

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

  Widget _buildSyncBanner(
    SyncState? state,
    BuildContext context,
    Color borderColor,
    Color surfaceVariant,
  ) {
    if (state == null || state is SyncIdle) return const SizedBox.shrink();

    final (icon, message, isProgress) = switch (state) {
      SyncIdle() => (Icons.sync, '', false),
      SyncDiscovering() => (
          Icons.sync,
          'Mencari data riwayat offline di perangkat...',
          true,
        ),
      SyncDownloading(:final fileIndex, :final totalFiles, :final fileName) => (
          Icons.download_rounded,
          'Mengunduh log offline $fileIndex/$totalFiles ($fileName)...',
          true,
        ),
      SyncParsing(:final fileIndex, :final totalFiles) => (
          Icons.data_object_rounded,
          'Memproses log $fileIndex/$totalFiles...',
          true,
        ),
      SyncPersisting(:final recordsCount) => (
          Icons.save_rounded,
          'Menyimpan $recordsCount data riwayat ke database...',
          true,
        ),
      SyncDeleting(:final fileIndex, :final totalFiles) => (
          Icons.check_circle_outline_rounded,
          'Menyinkronkan file $fileIndex/$totalFiles...',
          true,
        ),
      SyncCompleted(:final result) => result.recordsInserted > 0
          ? (
              Icons.check_circle_rounded,
              result.isCleanSuccess
                  ? 'Sinkronisasi selesai: ${result.recordsInserted} data baru (${result.recordsIgnored} duplikat diabaikan).'
                  : 'Sinkronisasi sebagian: ${result.recordsInserted} tersimpan, ${result.filesPreserved} log dipertahankan.',
              false,
            )
          : (
              Icons.check_circle_outline_rounded,
              result.filesPreserved > 0
                  ? 'Sinkronisasi sebagian: ${result.filesPreserved} log dipertahankan untuk keamanan.'
                  : 'Data perangkat sudah mutakhir.',
              false,
            ),
      SyncFailed(:final message) => (
          Icons.info_outline_rounded,
          'Sinkronisasi riwayat tertunda: $message',
          false,
        ),
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceVariant,
          borderRadius: BorderRadius.circular(kRadiusCard),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            if (isProgress)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              const Icon(Icons.sync, size: 14, color: AppColors.aqiGood),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 11),
              ),
            ),
            if (state is SyncFailed ||
                (state is SyncCompleted && !state.result.isCleanSuccess)) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: _triggerManualSync,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Coba Lagi',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeviceDataPreview extends ConsumerWidget {
  final Device device;

  const _DeviceDataPreview({required this.device});

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final border = dark ? AppColors.borderDark : AppColors.border;
    final textPrimary =
        dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = dark ? AppColors.textMutedDark : AppColors.textMuted;

    final telemetryDao = ref.watch(telemetryDaoProvider);

    return StreamBuilder<List<TelemetryRecord>>(
      stream: telemetryDao.watchRecentRecords(device.id, limit: 7),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Local telemetry',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                FutureBuilder<int>(
                  future: telemetryDao.countTelemetryForDevice(device.id),
                  builder: (context, countSnap) {
                    final count = countSnap.data ?? records.length;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.surfaceVariantDark
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(kRadiusChip),
                        border: Border.all(color: border, width: 1),
                      ),
                      child: Text(
                        '$count records stored',
                        style: AppTheme.monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ).copyWith(color: textSecondary),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: border, width: 1),
              ),
              child: records.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty,
                                size: 22, color: textMuted),
                            const SizedBox(height: 8),
                            Text(
                              'Waiting for local telemetry.',
                              style:
                                  TextStyle(color: textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        // Table header
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('TIME',
                                  style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)
                                      .copyWith(color: textMuted)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('TEMP',
                                  style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)
                                      .copyWith(color: textMuted)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('HUM',
                                  style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)
                                      .copyWith(color: textMuted)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('eCO₂',
                                  style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)
                                      .copyWith(color: textMuted)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('AQI',
                                  style: AppTheme.monoStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700)
                                      .copyWith(color: textMuted)),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        ...records.map((r) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _formatTime(r.timestamp),
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ).copyWith(color: textSecondary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    r.temperature != null
                                        ? '${r.temperature!.toStringAsFixed(1)}°'
                                        : '--',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ).copyWith(color: textPrimary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    r.humidity != null
                                        ? '${r.humidity!.round()}%'
                                        : '--',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ).copyWith(color: textPrimary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    r.eco2 != null ? '${r.eco2}' : '--',
                                    style: AppTheme.monoStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ).copyWith(color: textPrimary),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    children: [
                                      if (r.aqi != null)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin:
                                              const EdgeInsets.only(right: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.forAqi(r.aqi!),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      Text(
                                        r.aqi != null ? '${r.aqi}' : '--',
                                        style: AppTheme.monoStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ).copyWith(
                                          color: r.aqi != null
                                              ? AppColors.forAqi(r.aqi!)
                                              : textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                        DetaHubButton(
                          label: 'Manage & Export Data',
                          icon: Icons.storage_outlined,
                          outlined: true,
                          expand: true,
                          onPressed: () => context.push(
                            '/settings/storage?deviceId=${device.id}',
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
