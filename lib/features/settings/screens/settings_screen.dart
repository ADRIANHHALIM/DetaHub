// lib/features/settings/screens/settings_screen.dart
//
// Settings menu for DetaHub.
// Controls appearance, local backup/restore, storage dashboard, and app info.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_brand.dart';
import '../providers/appearance_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showLocalByDesignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.aqiGood, size: 24),
              SizedBox(width: 10),
              Text('Local by Design'),
            ],
          ),
          content: const Text(
            'DetaHub is built on strict local-first principles:\n\n'
            '• Zero Cloud Dependency: No remote databases, relays, or SaaS.\n'
            '• Zero Login or Auth: No account creation or tracking.\n'
            '• Local SQLite: All telemetry is stored on your device.\n'
            '• Local Wi-Fi: Direct HTTP connection to your ESP32 hardware.\n\n'
            'Your environmental data belongs strictly to you.',
            style: TextStyle(height: 1.45, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDetaHubDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dark ? AppColors.surfaceDark : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          title: const Row(
            children: [
              DetaHubMark(size: 28),
              SizedBox(width: 10),
              Text('DetaHub'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local-First IoT Companion for DetaLab Hardware.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 12),
              _buildInfoRow('Version', '1.0.0 (Build 1)'),
              const Divider(height: 16),
              _buildInfoRow('Storage Engine', 'Drift / SQLite 3 (WAL)'),
              const Divider(height: 16),
              _buildInfoRow('Design System', 'DetaDesign / Lab Instrument'),
              const Divider(height: 16),
              _buildInfoRow('Hardware Target', 'ESP32-H2 Mini / LAT ENS160'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          value,
          style: AppTheme.monoStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final themeMode = ref.watch(appearanceProvider);

    final appearanceDesc = switch (themeMode) {
      ThemeMode.system => 'Follows your system setting',
      ThemeMode.light => 'Light (Crisp Paper)',
      ThemeMode.dark => 'Dark (OLED Obsidian)',
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
          children: [
            const DetaHubHeader(),
            const SizedBox(height: 32),
            Text('Settings', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text(
              'Keep DetaHub feeling right at home.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: secondary),
            ),
            const SizedBox(height: 30),
            _SettingGroup(
              title: 'Appearance',
              children: [
                _SettingRow(
                  icon: Icons.dark_mode_outlined,
                  label: 'Appearance',
                  description: appearanceDesc,
                  onTap: () => context.push('/settings/appearance'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SettingGroup(
              title: 'Your data',
              children: [
                _SettingRow(
                  icon: Icons.backup_outlined,
                  label: 'Backup data',
                  description: 'Save a copy of your local data',
                  onTap: () => context.push('/settings/backup'),
                ),
                _SettingRow(
                  icon: Icons.restore_outlined,
                  label: 'Restore data',
                  description: 'Bring back a previous backup',
                  onTap: () => context.push('/settings/restore'),
                ),
                _SettingRow(
                  icon: Icons.storage_outlined,
                  label: 'Storage',
                  description: 'Inspect database and export CSV',
                  onTap: () => context.push('/settings/storage'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _SettingGroup(
              title: 'About DetaHub',
              children: [
                _SettingRow(
                  icon: Icons.shield_outlined,
                  label: 'Local by design',
                  description: 'Your device data stays in your hands',
                  onTap: () => _showLocalByDesignDialog(context),
                ),
                _SettingRow(
                  leading: const DetaHubMark(size: 38),
                  label: 'DetaHub',
                  description: 'Local IoT Companion · v1.0.0',
                  onTap: () => _showAboutDetaHubDialog(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingGroup extends StatelessWidget {
  final String title;
  final List<_SettingRow> children;

  const _SettingGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String label;
  final String description;
  final VoidCallback? onTap;

  const _SettingRow({
    this.icon,
    this.leading,
    required this.label,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              leading ??
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, size: 19),
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: secondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 19, color: secondary),
            ],
          ),
        ),
      ),
    );
  }
}
