// lib/core/theme/app_colors.dart
//
// DetaDesign color system for DetaHub (Idea/Style.md).
//
// Design philosophy:
//   - Technical Elegance / Lab Instrument Aesthetic.
//   - Default: Light Mode (#F8F9FA canvas, #FFFFFF surface, #D0D7DE border).
//   - Dark Mode: OLED Native (#0B0C0E canvas, #14171A surface, #2A3138 border).
//   - AQI palette strictly follows ENS160 5-level scale (Style.md 2.2).
//   - Metric Chart palette follows Style.md 4.5.

import 'package:flutter/material.dart';

/// Central color registry for the DetaDesign system.
abstract final class AppColors {
  // ─────────────────────────────────────────────────────────────────────────
  // AQI Semantic Colors (Sesuai Hardware ENS160 / Web LAT — Style.md 2.2)
  // ─────────────────────────────────────────────────────────────────────────

  /// AQI 1 — Good air quality. Light Green (#10B981).
  static const Color aqiGood = Color(0xFF10B981);

  /// AQI 2 — Moderate air quality. Muted Blue (#3B82F6).
  static const Color aqiModerate = Color(0xFF3B82F6);

  /// AQI 3 — Unhealthy for Sensitive. Amber / Warm Yellow (#F59E0B).
  static const Color aqiSensitive = Color(0xFFF59E0B);

  /// AQI 4 — Unhealthy air quality. Crisp Red (#EF4444).
  static const Color aqiUnhealthy = Color(0xFFEF4444);

  /// AQI 5 — Very Unhealthy air quality. Deep Crimson (#991B1B).
  static const Color aqiVeryUnhealthy = Color(0xFF991B1B);

  // Backward compatibility aliases
  static const Color aqiExcellent = aqiGood;
  static const Color aqiPoor = aqiUnhealthy;

  /// Returns the official DetaDesign AQI color for a given [aqi] level (1–5).
  static Color forAqi(int aqi) {
    switch (aqi) {
      case 1:
        return aqiGood;
      case 2:
        return aqiModerate;
      case 3:
        return aqiSensitive;
      case 4:
        return aqiUnhealthy;
      case 5:
        return aqiVeryUnhealthy;
      default:
        return aqiModerate;
    }
  }

  /// Human-readable label for each AQI level (Style.md 2.2).
  static String labelForAqi(int aqi) {
    switch (aqi) {
      case 1:
        return 'Good';
      case 2:
        return 'Moderate';
      case 3:
        return 'Unhealthy for Sensitive';
      case 4:
        return 'Unhealthy';
      case 5:
        return 'Very Unhealthy';
      default:
        return 'Unknown';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Base Theme Colors — Light Mode (Default) — Style.md 2.1
  // ─────────────────────────────────────────────────────────────────────────

  /// Page background: Clean Off-White (#F8F9FA).
  static const Color background = Color(0xFFF8F9FA);

  /// Card / widget surface: Pure White (#FFFFFF).
  static const Color surface = Color(0xFFFFFFFF);

  /// Surface variant / chip / track bar: Cool Light Grey (#EFF1F4).
  static const Color surfaceVariant = Color(0xFFEFF1F4);

  /// Primary 1px border color: Crisp Divider (#D0D7DE).
  static const Color border = Color(0xFFD0D7DE);

  /// Subtle divider / secondary border.
  static const Color borderSubtle = Color(0xFFE7ECF0);

  /// Primary body & title text: Deep Slate (#0D1117).
  static const Color textPrimary = Color(0xFF0D1117);

  /// Secondary text, units, descriptions: Neutral Grey (#57606A).
  static const Color textSecondary = Color(0xFF57606A);

  /// Muted / caption text.
  static const Color textMuted = Color(0xFF8C959F);

  /// Accent / primary actions: Pure Industrial (#111827).
  static const Color accent = Color(0xFF111827);

  // ─────────────────────────────────────────────────────────────────────────
  // Base Theme Colors — Dark Mode (LAT Web Native) — Style.md 2.1
  // ─────────────────────────────────────────────────────────────────────────

  /// OLED Dark page background: OLED Obsidian (#0B0C0E).
  static const Color backgroundDark = Color(0xFF0B0C0E);

  /// Dark surface container / cards: Charcoal Tint (#14171A).
  static const Color surfaceDark = Color(0xFF14171A);

  /// Dark surface variant / chips: Muted Steel (#1F2428).
  static const Color surfaceVariantDark = Color(0xFF1F2428);

  /// Dark mode 1px border: Low-contrast Dark (#2A3138).
  static const Color borderDark = Color(0xFF2A3138);

  /// Dark mode subtle border.
  static const Color borderSubtleDark = Color(0xFF1F2428);

  /// Dark mode primary text: Crisp Chalk (#EDEDED).
  static const Color textPrimaryDark = Color(0xFFEDEDED);

  /// Dark mode secondary text: Subdued Steel (#8B949E).
  static const Color textSecondaryDark = Color(0xFF8B949E);

  /// Dark mode muted text.
  static const Color textMutedDark = Color(0xFF6E7681);

  /// Dark mode accent / buttons: Stark Minimalist (#FFFFFF).
  static const Color accentDark = Color(0xFFFFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // Chart Color Mapping (Style.md 4.5)
  // ─────────────────────────────────────────────────────────────────────────

  /// eCO₂: Emerald (#10B981).
  static const Color metricEco2 = Color(0xFF10B981);

  /// TVOC: Amber (#F59E0B).
  static const Color metricTvoc = Color(0xFFF59E0B);

  /// Temperature: Warm Orange (#F97316).
  static const Color metricTemperature = Color(0xFFF97316);

  /// Humidity: Cyan Water (#06B6D4).
  static const Color metricHumidity = Color(0xFF06B6D4);
}

