// lib/core/widgets/metric_card.dart
//
// Reusable card for displaying a single telemetry metric value.
// Follows DetaDesign: flat, 1px border, JetBrains Mono for the value,
// Inter for label and unit. No elevation, no shadow.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// A fixed-size instrument card for one telemetry metric.
///
/// Usage:
/// ```dart
/// MetricCard(
///   label: 'eCO₂',
///   value: '450',
///   unit: 'ppm',
///   valueColor: AppColors.metricEco2,
/// )
/// ```
class MetricCard extends StatelessWidget {
  /// Short metric label displayed above the value (e.g., "eCO₂", "Temp").
  final String label;

  /// Formatted numeric value as a string (e.g., "450", "24.5").
  final String value;

  /// Unit suffix displayed below/beside the value (e.g., "ppm", "°C", "%").
  final String unit;

  /// Optional override color for the value text. Defaults to [AppColors.textPrimary].
  final Color? valueColor;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final borderColor = isDark ? AppColors.borderDark : AppColors.border;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final unitColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final dataColor = valueColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surfaceColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(kRadiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label row
            Text(
              label.toUpperCase(),
              style: AppTheme.monoStyle(fontSize: 9, fontWeight: FontWeight.w500)
                  .copyWith(color: labelColor, letterSpacing: 0.8),
            ),
            const SizedBox(height: 6),

            // Value — primary emphasis, monospace
            Text(
              value,
              style: AppTheme.monoStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ).copyWith(color: dataColor, height: 1),
            ),

            const SizedBox(height: 2),

            // Unit
            Text(
              unit,
              style: AppTheme.monoStyle(fontSize: 11)
                  .copyWith(color: unitColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact variant of [MetricCard] for list rows and summary strips.
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color? valueColor;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final unitColor = isDark ? AppColors.textMutedDark : AppColors.textMuted;
    final dataColor = valueColor ??
        (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$label ',
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: labelColor),
        ),
        Text(
          value,
          style: AppTheme.monoStyle(fontSize: 13, fontWeight: FontWeight.w600)
              .copyWith(color: dataColor),
        ),
        Text(
          ' $unit',
          style: AppTheme.monoStyle(fontSize: 10).copyWith(color: unitColor),
        ),
      ],
    );
  }
}
