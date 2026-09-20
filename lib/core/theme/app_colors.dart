// lib/core/theme/app_colors.dart
//
// DetaDesign color system for DetaHub.
//
// Design philosophy:
//   - Industrial Instrument Minimalist: precise, data-centric, no decorative gradients.
//   - Default: Crisp Light Mode (white surface, stone neutrals for hierarchy).
//   - Alternative: Dark OLED Mode (true black, minimal chroma).
//   - AQI palette strictly follows ENS160 standard 5-level scale.
//
// All color constants use the exact hex values from the design spec.
// No opacity modifiers are applied here — use .withOpacity() at call site.

import 'package:flutter/material.dart';

/// Central color registry for the DetaDesign system.
///
/// Access via static constants, e.g., [AppColors.aqiExcellent] or
/// the helper [AppColors.forAqi].
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────────
  // AQI Semantic Colors (ENS160, 5-level scale)
  // Source: ENS160 Application Note, ams-OSRAM AG
  // ─────────────────────────────────────────────────────────────────────────

  /// AQI 1 — Excellent air quality. Emerald 500.
  static const Color aqiExcellent = Color(0xFF10B981);

  /// AQI 2 — Good air quality. Emerald 300 (lighter tint for distinction).
  static const Color aqiGood = Color(0xFF6EE7B7);

  /// AQI 3 — Moderate air quality. Amber 500 (caution signal).
  static const Color aqiModerate = Color(0xFFF59E0B);

  /// AQI 4 — Poor air quality. Red 500 (active warning).
  static const Color aqiPoor = Color(0xFFEF4444);

  /// AQI 5 — Unhealthy air quality. Red 800 (critical / danger).
  static const Color aqiUnhealthy = Color(0xFF991B1B);

  /// Returns the official DetaDesign AQI color for a given [aqi] level (1–5).
  ///
  /// Values outside the 1–5 range return [aqiModerate] as a safe fallback.
  static Color forAqi(int aqi) {
    switch (aqi) {
      case 1:
        return aqiExcellent;
      case 2:
        return aqiGood;
      case 3:
        return aqiModerate;
      case 4:
        return aqiPoor;
      case 5:
        return aqiUnhealthy;
      default:
        return aqiModerate;
    }
  }

  /// Human-readable label for each AQI level (used in tooltips / legend).
  static String labelForAqi(int aqi) {
    switch (aqi) {
      case 1:
        return 'Excellent';
      case 2:
        return 'Good';
      case 3:
        return 'Moderate';
      case 4:
        return 'Poor';
      case 5:
        return 'Unhealthy';
      default:
        return 'Unknown';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Neutral Palette — Light Mode (default)
  // Based on Tailwind CSS Stone scale for warm-neutral industrial feel.
  // ─────────────────────────────────────────────────────────────────────────

  /// Card / widget surface. Pure white.
  static const Color surface = Color(0xFFFFFFFF);

  /// Page background. Stone-100 — slightly off-white, reduces eye strain.
  static const Color background = Color(0xFFF5F5F4);

  /// Primary 1px border color. Stone-300.
  static const Color border = Color(0xFFD6D3D1);

  /// Subtle divider / secondary border. Stone-200.
  static const Color borderSubtle = Color(0xFFE7E5E4);

  /// Primary body text. Stone-900 — near black, high contrast.
  static const Color textPrimary = Color(0xFF1C1917);

  /// Secondary label text. Stone-500 — mid-gray for metadata.
  static const Color textSecondary = Color(0xFF78716C);

  /// Muted / placeholder text. Stone-400.
  static const Color textMuted = Color(0xFFA8A29E);

  /// Interactive accent (links, active states, primary buttons). Stone-800.
  static const Color accent = Color(0xFF292524);

  // ─────────────────────────────────────────────────────────────────────────
  // Dark OLED Mode Overrides
  // True black surface to maximize power savings on OLED panels.
  // ─────────────────────────────────────────────────────────────────────────

  /// OLED dark surface — true black.
  static const Color surfaceDark = Color(0xFF000000);

  /// OLED dark page background — near black (not pure, for visual depth).
  static const Color backgroundDark = Color(0xFF0A0A0A);

  /// Dark mode border. Stone-800 — barely visible, precise 1px lines.
  static const Color borderDark = Color(0xFF292524);

  /// Dark mode subtle border. Stone-900.
  static const Color borderSubtleDark = Color(0xFF1C1917);

  /// Dark mode primary text. Stone-50 — warm off-white.
  static const Color textPrimaryDark = Color(0xFFFAFAF9);

  /// Dark mode secondary text. Stone-400.
  static const Color textSecondaryDark = Color(0xFFA8A29E);

  /// Dark mode muted text. Stone-600.
  static const Color textMutedDark = Color(0xFF57534E);

  /// Dark mode accent. Stone-300.
  static const Color accentDark = Color(0xFFD6D3D1);

  // ─────────────────────────────────────────────────────────────────────────
  // Metric-specific Chart Line Colors
  // Chosen for maximum discriminability on white and OLED-black backgrounds.
  // ─────────────────────────────────────────────────────────────────────────

  /// Temperature line color. Warm amber.
  static const Color metricTemperature = Color(0xFFF59E0B);

  /// Humidity line color. Sky blue.
  static const Color metricHumidity = Color(0xFF38BDF8);

  /// eCO₂ line color. Violet.
  static const Color metricEco2 = Color(0xFF8B5CF6);

  /// TVOC line color. Rose.
  static const Color metricTvoc = Color(0xFFF43F5E);
}
