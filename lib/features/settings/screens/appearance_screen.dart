// lib/features/settings/screens/appearance_screen.dart
//
// Appearance theme mode selection screen for DetaHub.
// Supports System, Light (Crisp Paper), and Dark (OLED Native).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/appearance_provider.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(appearanceProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.backgroundDark : AppColors.background;
    final surface = dark ? AppColors.surfaceDark : AppColors.surface;
    final border = dark ? AppColors.borderDark : AppColors.border;
    final textPrimary =
        dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final textSecondary =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondary;

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
          'Appearance',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Text(
            'Theme preference',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose how DetaHub renders across your devices. Preference is saved locally.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textSecondary,
                ),
          ),
          const SizedBox(height: 24),
          _ThemeOptionTile(
            mode: ThemeMode.system,
            currentMode: currentMode,
            title: 'System default',
            description:
                'Automatically adapts to your device operating system dark/light setting.',
            icon: Icons.brightness_auto_outlined,
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onSelect: () => ref
                .read(appearanceProvider.notifier)
                .setThemeMode(ThemeMode.system),
          ),
          const SizedBox(height: 12),
          _ThemeOptionTile(
            mode: ThemeMode.light,
            currentMode: currentMode,
            title: 'Light (Crisp Paper)',
            description:
                'Calm, high-contrast off-white lab aesthetic with sharp borders.',
            icon: Icons.light_mode_outlined,
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onSelect: () => ref
                .read(appearanceProvider.notifier)
                .setThemeMode(ThemeMode.light),
          ),
          const SizedBox(height: 12),
          _ThemeOptionTile(
            mode: ThemeMode.dark,
            currentMode: currentMode,
            title: 'Dark (OLED Obsidian)',
            description:
                'Deep black technical instrument palette, optimized for low-light environments.',
            icon: Icons.dark_mode_outlined,
            surface: surface,
            border: border,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onSelect: () => ref
                .read(appearanceProvider.notifier)
                .setThemeMode(ThemeMode.dark),
          ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final ThemeMode mode;
  final ThemeMode currentMode;
  final String title;
  final String description;
  final IconData icon;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onSelect;

  const _ThemeOptionTile({
    required this.mode,
    required this.currentMode,
    required this.title,
    required this.description,
    required this.icon,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == currentMode;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final activeBorderColor = dark ? Colors.white : AppColors.accent;

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(kRadiusCard),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusCard),
            border: Border.all(
              color: isSelected ? activeBorderColor : border,
              width: isSelected ? 1.5 : kBorderWidth,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (dark ? Colors.white12 : AppColors.accentSoft)
                      : (dark
                          ? AppColors.surfaceVariantDark
                          : AppColors.surfaceVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? activeBorderColor : textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Radio<ThemeMode>(
                value: mode,
                groupValue: currentMode,
                onChanged: (_) => onSelect(),
                activeColor: activeBorderColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
