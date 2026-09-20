// lib/core/widgets/aqi_badge.dart
//
// AQI level badge using the official ENS160 5-level color palette.
// Background is the AQI color at 12% opacity; border is the AQI color solid.
// Text uses JetBrains Mono at 10px in the AQI color.

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Compact AQI level pill with ENS160-correct semantic color.
///
/// Usage:
/// ```dart
/// AqiBadge(aqi: 2)  // → "AQI 2 · Good" in green
/// AqiBadge(aqi: 4)  // → "AQI 4 · Poor" in red
/// ```
class AqiBadge extends StatelessWidget {
  /// ENS160 AQI level: integer 1 (Excellent) to 5 (Unhealthy).
  /// Values outside 1–5 render with the Moderate color as a safe fallback.
  final int aqi;

  /// If true, shows only the numeric level (e.g., "AQI 3") without the label.
  final bool compact;

  const AqiBadge({super.key, required this.aqi, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forAqi(aqi);
    final label = compact ? 'AQI $aqi' : 'AQI $aqi · ${AppColors.labelForAqi(aqi).toUpperCase()}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        label,
        style: AppTheme.monoStyle(fontSize: 10, fontWeight: FontWeight.w600)
            .copyWith(color: color, letterSpacing: 0.3),
      ),
    );
  }
}

/// Large AQI display for the dashboard hero section.
/// Shows the numeric AQI prominently with label below.
class AqiHero extends StatelessWidget {
  final int aqi;

  const AqiHero({super.key, required this.aqi});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forAqi(aqi);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          aqi.toString(),
          style: AppTheme.monoStyle(fontSize: 56, fontWeight: FontWeight.w700)
              .copyWith(color: color, height: 1),
        ),
        const SizedBox(height: 4),
        Text(
          AppColors.labelForAqi(aqi).toUpperCase(),
          style: AppTheme.monoStyle(fontSize: 11, fontWeight: FontWeight.w500)
              .copyWith(color: color, letterSpacing: 1.5),
        ),
      ],
    );
  }
}
