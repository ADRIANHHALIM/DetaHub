import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/detahub_brand.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Scaffold(
        body: SafeArea(
            bottom: false,
            child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
                children: [
                  const DetaHubHeader(),
                  const SizedBox(height: 32),
                  Text('Settings',
                      style: Theme.of(context).textTheme.displayMedium),
                  const SizedBox(height: 6),
                  Text('Keep DetaHub feeling right at home.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: secondary)),
                  const SizedBox(height: 30),
                  const _SettingGroup(title: 'Appearance', children: [
                    _SettingRow(
                        icon: Icons.dark_mode_outlined,
                        label: 'Appearance',
                        description: 'Follows your system setting')
                  ]),
                  const SizedBox(height: 22),
                  const _SettingGroup(title: 'Your data', children: [
                    _SettingRow(
                        icon: Icons.backup_outlined,
                        label: 'Backup data',
                        description: 'Save a copy of your local data'),
                    _SettingRow(
                        icon: Icons.restore_outlined,
                        label: 'Restore data',
                        description: 'Bring back a previous backup'),
                    _SettingRow(
                        icon: Icons.storage_outlined,
                        label: 'Storage',
                        description: 'See what DetaHub is storing')
                  ]),
                  const SizedBox(height: 22),
                  const _SettingGroup(title: 'About DetaHub', children: [
                    _SettingRow(
                        icon: Icons.shield_outlined,
                        label: 'Local by design',
                        description: 'Your device data stays in your hands'),
                    _SettingRow(
                        icon: Icons.info_outline,
                        label: 'DetaHub',
                        description: 'Local IoT Companion')
                  ]),
                ])));
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
    final border = dark ? AppColors.borderDark : AppColors.borderSubtle;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: secondary, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Container(
          decoration: BoxDecoration(
              color: surface,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(kRadiusCard)),
          child: Column(children: children))
    ]);
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label, description;
  const _SettingRow(
      {required this.icon, required this.label, required this.description});
  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    return Semantics(
        button: true,
        label: label,
        child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: dark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(13)),
                      child: Icon(icon, size: 19)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(label,
                            style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 3),
                        Text(description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: secondary))
                      ])),
                  Icon(Icons.chevron_right, size: 19, color: secondary)
                ]))));
  }
}
