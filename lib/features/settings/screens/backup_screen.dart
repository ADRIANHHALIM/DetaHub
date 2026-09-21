// lib/features/settings/screens/backup_screen.dart
//
// Screen for creating full local DetaHub backups.
// Generates a versioned JSON file and triggers the platform native save/share sheet.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/export/backup_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_button.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isBackingUp = false;
  int _recordsCount = 0;
  String? _errorMessage;

  Future<void> _handleCreateBackup() async {
    setState(() {
      _isBackingUp = true;
      _errorMessage = null;
      _recordsCount = 0;
    });

    try {
      final service = ref.read(backupServiceProvider);
      await service.createBackup(
        onProgress: (count) {
          if (mounted) {
            setState(() => _recordsCount = count);
          }
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backup archive created successfully.'),
            backgroundColor: AppColors.aqiGood,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to generate backup: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isBackingUp = false);
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
          'Backup Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Local backup archive',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Create a portable snapshot of all your local hardware telemetry, registered devices, and location hierarchies.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),

          // Information Card
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
                  'WHAT IS INCLUDED IN THIS BACKUP',
                  style: AppTheme.monoStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ).copyWith(color: textMuted),
                ),
                const SizedBox(height: 14),
                _buildIncludedRow(
                  Icons.map_outlined,
                  'Locations & Areas',
                  'All Sectors and Sub-Sectors you created.',
                  textPrimary,
                  textSecondary,
                ),
                const Divider(height: 20),
                _buildIncludedRow(
                  Icons.memory_outlined,
                  'Connected Devices',
                  'Hardware identifiers, names, and local addresses.',
                  textPrimary,
                  textSecondary,
                ),
                const Divider(height: 20),
                _buildIncludedRow(
                  Icons.analytics_outlined,
                  'Sensor Telemetry Records',
                  'Every stored temperature, humidity, eCO₂, TVOC, and AQI point.',
                  textPrimary,
                  textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Privacy Assurance Note
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.aqiGood.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kRadiusCard),
              border: Border.all(
                  color: AppColors.aqiGood.withValues(alpha: 0.25), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 18, color: AppColors.aqiGood),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '100% offline. The backup file is generated locally and never uploaded to any remote server.',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.aqiPoor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(kRadiusCard),
                border:
                    Border.all(color: AppColors.aqiPoor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.aqiPoor, fontSize: 13),
              ),
            ),
          ],

          const SizedBox(height: 32),

          if (_isBackingUp)
            Column(
              children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 12),
                Text(
                  _recordsCount > 0
                      ? 'Archiving telemetry: $_recordsCount records processed…'
                      : 'Preparing local backup…',
                  style: AppTheme.monoStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ).copyWith(color: textSecondary),
                ),
              ],
            )
          else
            DetaHubButton(
              label: 'Generate & Export Backup',
              icon: Icons.file_upload_outlined,
              expand: true,
              onPressed: _handleCreateBackup,
            ),
        ],
      ),
    );
  }

  static Widget _buildIncludedRow(
    IconData icon,
    String title,
    String description,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: textPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
