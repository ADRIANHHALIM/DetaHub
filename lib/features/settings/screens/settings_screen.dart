// lib/features/settings/screens/settings_screen.dart
//
// Settings screen — Phase 2 placeholder.
// Will contain: Backup/Restore SQLite, storage management, app info.
// Phase 5 will implement the full feature set.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _SettingsSection(
            title: 'DATA',
            children: [
              _SettingsTile(
                label: 'Backup Database',
                description: 'Export detahub.db via native share sheet',
                onTap: () {}, // TODO(fase-5)
              ),
              _SettingsTile(
                label: 'Restore Database',
                description: 'Import a previous detahub.db backup',
                onTap: () {}, // TODO(fase-5)
              ),
              _SettingsTile(
                label: 'Storage Usage',
                description: 'View telemetry record counts and DB size',
                onTap: () {}, // TODO(fase-5)
              ),
            ],
          ),
          const _SettingsSection(
            title: 'APPEARANCE',
            children: [
              _SettingsTile(
                label: 'Theme',
                description: 'Follows system preference (Light / OLED Dark)',
                onTap: null,
              ),
            ],
          ),
          const _SettingsSection(
            title: 'ABOUT',
            children: [
              _SettingsTile(
                label: 'DetaHub',
                description: 'Phase 2 — Local-first IoT companion',
                onTap: null,
              ),
              _SettingsTile(
                label: 'Philosophy',
                description: 'NO CLOUD. NO LOGIN. NO SHARE. SAVE YOUR OWN DATA.',
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: AppTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.w600)
                .copyWith(color: mutedColor, letterSpacing: 1.5),
          ),
        ),
        ...children,
        Divider(height: 1, color: borderColor),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: borderColor, width: 1)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: mutedColor),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, size: 16, color: mutedColor),
          ],
        ),
      ),
    );
  }
}
