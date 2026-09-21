// lib/features/settings/screens/restore_screen.dart
//
// Screen for restoring local DetaHub database from JSON backups.
// Validates file integrity, shows pre-restore counts, and supports Merge and Replace modes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/export/restore_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_button.dart';

class RestoreScreen extends ConsumerStatefulWidget {
  const RestoreScreen({super.key});

  @override
  ConsumerState<RestoreScreen> createState() => _RestoreScreenState();
}

class _RestoreScreenState extends ConsumerState<RestoreScreen> {
  BackupPreview? _preview;
  bool _isLoadingFile = false;
  bool _isRestoring = false;
  String _restoreStep = '';
  double _restoreProgress = 0.0;
  String? _errorMessage;
  RestoreMode _selectedMode = RestoreMode.merge;

  Future<void> _handlePickFile() async {
    setState(() {
      _isLoadingFile = true;
      _errorMessage = null;
      _preview = null;
    });

    try {
      final service = ref.read(restoreServiceProvider);
      final preview = await service.pickAndValidateBackup();
      if (mounted) {
        setState(() {
          _preview = preview;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('FormatException: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingFile = false);
      }
    }
  }

  Future<void> _handleExecuteRestore() async {
    if (_preview == null) return;

    if (_selectedMode == RestoreMode.replace) {
      final confirmed = await _showReplaceConfirmDialog();
      if (!confirmed) return;
    }

    setState(() {
      _isRestoring = true;
      _restoreStep = 'Starting restore…';
      _restoreProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final service = ref.read(restoreServiceProvider);
      final inserted = await service.executeRestore(
        preview: _preview!,
        mode: _selectedMode,
        onProgress: (step, progress) {
          if (mounted) {
            setState(() {
              _restoreStep = step;
              _restoreProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusCard),
            ),
            title: const Text('Restore Successful'),
            content: Text(
              'Successfully imported ${_preview!.deviceCount} devices and $inserted telemetry records.\nYour local database is fully restored.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/home');
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Restore failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
      }
    }
  }

  Future<bool> _showReplaceConfirmDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadiusCard),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.aqiPoor, size: 24),
                SizedBox(width: 8),
                Text('Replace Local Data?'),
              ],
            ),
            content: const Text(
              'This will completely wipe all current locations, devices, and historical telemetry stored on this phone before importing the backup.\n\nThis action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.aqiPoor,
                ),
                child: const Text('Wipe & Replace'),
              ),
            ],
          ),
        ) ??
        false;
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
          'Restore Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Import local backup',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Restore a previous DetaHub backup file. You can choose to merge new records with your existing data or completely replace it.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 24),

          // File Picker Button
          DetaHubButton(
            label: _preview == null
                ? 'Select Backup File (.json)'
                : 'Change Selected File',
            icon: Icons.folder_open_outlined,
            outlined: _preview != null,
            expand: true,
            onPressed: _isLoadingFile || _isRestoring ? null : _handlePickFile,
          ),

          if (_isLoadingFile) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.aqiPoor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(kRadiusCard),
                border:
                    Border.all(color: AppColors.aqiPoor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.aqiPoor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.aqiPoor,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Preview Section
          if (_preview != null && !_isRestoring) ...[
            const SizedBox(height: 24),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'BACKUP ARCHIVE PREVIEW',
                        style: AppTheme.monoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ).copyWith(color: textMuted),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.aqiGood.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(kRadiusChip),
                        ),
                        child: Text(
                          'Format v${_preview!.formatVersion}',
                          style: AppTheme.monoStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ).copyWith(color: AppColors.aqiGood),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Created on: ${_preview!.createdAt.toLocal().toString().split('.').first}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                  const Divider(height: 24),
                  _buildPreviewStatRow('Locations (Sectors)',
                      '${_preview!.sectorCount}', textPrimary, textSecondary),
                  const Divider(height: 16),
                  _buildPreviewStatRow(
                      'Areas (Sub-Sectors)',
                      '${_preview!.subSectorCount}',
                      textPrimary,
                      textSecondary),
                  const Divider(height: 16),
                  _buildPreviewStatRow('Devices', '${_preview!.deviceCount}',
                      textPrimary, textSecondary),
                  const Divider(height: 16),
                  _buildPreviewStatRow(
                      'Telemetry Records',
                      '${_preview!.telemetryCount}',
                      textPrimary,
                      textSecondary),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Mode Selection
            Text(
              'Restore strategy',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),

            _buildModeTile(
              mode: RestoreMode.merge,
              title: 'Merge with existing data (Recommended)',
              description:
                  'Keep all your current data intact. Add missing devices and telemetry without overwriting existing readings.',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),
            _buildModeTile(
              mode: RestoreMode.replace,
              title: 'Replace entire database',
              description:
                  'Wipes all current local data and replaces it with the contents of this backup archive.',
              surface: surface,
              border: border,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
              isDestructive: true,
            ),

            const SizedBox(height: 28),

            DetaHubButton(
              label: _selectedMode == RestoreMode.merge
                  ? 'Confirm and Merge Data'
                  : 'Confirm and Replace Data',
              icon: Icons.restore_outlined,
              expand: true,
              onPressed: _handleExecuteRestore,
            ),
          ],

          if (_isRestoring) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(kRadiusCard),
                border: Border.all(color: border, width: kBorderWidth),
              ),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _restoreProgress > 0 ? _restoreProgress : null,
                    backgroundColor: border,
                    valueColor: AlwaysStoppedAnimation(
                      dark ? AppColors.accentDark : AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _restoreStep,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Do not close DetaHub during the database restore process.',
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeTile({
    required RestoreMode mode,
    required String title,
    required String description,
    required Color surface,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required bool dark,
    bool isDestructive = false,
  }) {
    final isSelected = _selectedMode == mode;
    final activeBorder = isDestructive
        ? AppColors.aqiPoor
        : (dark ? Colors.white : AppColors.accent);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        onTap: () => setState(() => _selectedMode = mode),
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(
              color: isSelected ? activeBorder : border,
              width: isSelected ? 1.5 : kBorderWidth,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Radio<RestoreMode>(
                value: mode,
                groupValue: _selectedMode,
                onChanged: (val) {
                  if (val != null) setState(() => _selectedMode = val);
                },
                activeColor: activeBorder,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDestructive && isSelected
                            ? AppColors.aqiPoor
                            : textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildPreviewStatRow(
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
