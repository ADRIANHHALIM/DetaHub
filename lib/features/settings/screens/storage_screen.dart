// lib/features/settings/screens/storage_screen.dart
//
// Centralized Data Storage Dashboard for DetaHub.
// Displays aggregate database metrics, per-device telemetry inspection,
// and memory-safe chunked CSV export actions. Strictly local-first.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/export/csv_export_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_button.dart';
import '../providers/storage_provider.dart';

class StorageScreen extends ConsumerStatefulWidget {
  final String? initialDeviceId;

  const StorageScreen({
    super.key,
    this.initialDeviceId,
  });

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  bool _isExporting = false;
  String _exportLabel = '';
  String? _exportSuccessMessage;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '--';
    final local = dt.toLocal();
    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Future<void> _handleExportAll() async {
    setState(() {
      _isExporting = true;
      _exportLabel = 'Exporting all local telemetry records…';
      _exportSuccessMessage = null;
    });

    try {
      final exportService = ref.read(csvExportServiceProvider);
      await exportService.exportAllTelemetry(
        onProgress: (count) {
          if (mounted) {
            setState(() {
              _exportLabel = 'Exported $count records…';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _exportSuccessMessage =
              'All telemetry records exported successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.aqiPoor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleExportDevice(String deviceId, String deviceName) async {
    setState(() {
      _isExporting = true;
      _exportLabel = 'Exporting telemetry for $deviceName…';
      _exportSuccessMessage = null;
    });

    try {
      final exportService = ref.read(csvExportServiceProvider);
      await exportService.exportDeviceTelemetry(
        deviceId,
        onProgress: (count) {
          if (mounted) {
            setState(() {
              _exportLabel = 'Exported $count records for $deviceName…';
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _exportSuccessMessage =
              'Telemetry for $deviceName exported successfully.';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Device export failed: $e'),
            backgroundColor: AppColors.aqiPoor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.backgroundDark : AppColors.background;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final border = dark ? AppColors.borderDark : AppColors.border;
    final textPrimary =
        dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final textMuted = dark ? AppColors.textMutedDark : AppColors.textMuted;

    final overviewAsync = ref.watch(storageOverviewProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Data Storage',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh Storage',
            onPressed: () => ref.refresh(storageOverviewProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: overviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Error loading storage summary: $err'),
          ),
        ),
        data: (data) {
          final hasData = data.totalRecords > 0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 60),
            children: [
              Text(
                'Local database overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'All telemetry readings are stored in SQLite directly on this device.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: textSecondary,
                    ),
              ),
              const SizedBox(height: 20),

              if (_isExporting) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    border: Border.all(color: border, width: kBorderWidth),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _exportLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (_exportSuccessMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.aqiGood.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    border: Border.all(
                        color: AppColors.aqiGood.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.aqiGood),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _exportSuccessMessage!,
                          style: TextStyle(
                            color: dark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // DATA OVERVIEW CARD
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(kRadiusCard),
                  border: Border.all(color: border, width: kBorderWidth),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATA OVERVIEW',
                      style: AppTheme.monoStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ).copyWith(color: textMuted),
                    ),
                    const SizedBox(height: 16),
                    _buildOverviewStatRow(
                      'Devices',
                      '${data.totalDevices}',
                      textPrimary,
                      textSecondary,
                    ),
                    const Divider(height: 20),
                    _buildOverviewStatRow(
                      'Telemetry records',
                      '${data.totalRecords}',
                      textPrimary,
                      textSecondary,
                    ),
                    const Divider(height: 20),
                    _buildOverviewStatRow(
                      'Oldest reading',
                      _formatDate(data.oldestTimestamp),
                      textPrimary,
                      textSecondary,
                    ),
                    const Divider(height: 20),
                    _buildOverviewStatRow(
                      'Newest reading',
                      _formatDate(data.newestTimestamp),
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 20),
                    DetaHubButton(
                      label: 'Export All Data (CSV)',
                      icon: Icons.download_outlined,
                      expand: true,
                      outlined: true,
                      onPressed:
                          hasData && !_isExporting ? _handleExportAll : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // DEVICE DATA SECTION
              Text(
                'DEVICE DATA',
                style: AppTheme.monoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ).copyWith(color: textMuted),
              ),
              const SizedBox(height: 12),

              if (data.deviceSummaries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(kRadiusCard),
                    border: Border.all(color: border, width: kBorderWidth),
                  ),
                  child: Center(
                    child: Text(
                      'No devices registered yet.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  ),
                )
              else
                ...data.deviceSummaries.map((summary) {
                  final isFocused = widget.initialDeviceId == summary.device.id;
                  final hasDeviceData = summary.recordCount > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(kRadiusCard),
                      border: Border.all(
                        color: isFocused
                            ? (dark ? Colors.white : AppColors.accent)
                            : border,
                        width: isFocused ? 1.5 : kBorderWidth,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                summary.device.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: dark
                                    ? AppColors.surfaceVariantDark
                                    : AppColors.surfaceVariant,
                                borderRadius:
                                    BorderRadius.circular(kRadiusChip),
                              ),
                              child: Text(
                                summary.device.productType,
                                style: AppTheme.monoStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ).copyWith(color: textSecondary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${summary.device.id}',
                          style: AppTheme.monoStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                          ).copyWith(color: textMuted),
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Records stored',
                              style:
                                  TextStyle(fontSize: 13, color: textSecondary),
                            ),
                            Text(
                              '${summary.recordCount}',
                              style: AppTheme.monoStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ).copyWith(color: textPrimary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Date range',
                              style:
                                  TextStyle(fontSize: 13, color: textSecondary),
                            ),
                            Text(
                              summary.recordCount == 0
                                  ? 'No records yet'
                                  : '${_formatDate(summary.oldestTimestamp).split(' ').first} → ${_formatDate(summary.newestTimestamp).split(' ').first}',
                              style: AppTheme.monoStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ).copyWith(color: textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        DetaHubButton(
                          label: 'Export Device CSV',
                          icon: Icons.file_download_outlined,
                          outlined: true,
                          expand: true,
                          onPressed: hasDeviceData && !_isExporting
                              ? () => _handleExportDevice(
                                    summary.device.id,
                                    summary.device.name,
                                  )
                              : null,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildOverviewStatRow(
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, color: textSecondary),
        ),
        Text(
          value,
          style: AppTheme.monoStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ).copyWith(color: textPrimary),
        ),
      ],
    );
  }
}
