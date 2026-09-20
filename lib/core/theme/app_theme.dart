// lib/core/theme/app_theme.dart
//
// DetaDesign ThemeData factory.
//
// Design rules enforced here:
//   1. Flat, no elevation (elevation: 0 everywhere).
//   2. 1px solid borders — no fuzzy drop-shadows.
//   3. Monospace font (JetBrains Mono) for all numeric/data displays.
//   4. Sans-serif font (Inter) for all UI text.
//   5. Max border-radius: 4px (sharp corners for instrument aesthetic).
//   6. Default: Light Mode. OLED Dark Mode available.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Maximum allowed border radius in the DetaDesign system.
/// Larger values violate the "Industrial Instrument" aesthetic.
const _kBorderRadius = 4.0;

/// Standard 1px border width for all interactive components.
const _kBorderWidth = 1.0;

abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // Typography
  // ─────────────────────────────────────────────────────────────────────────

  /// Inter — primary UI typeface.
  /// Used for labels, body text, navigation, and all non-numeric strings.
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        // Display styles — section headers, screen titles
        displayLarge:
            TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: primaryColor),
        displayMedium:
            TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: primaryColor),
        displaySmall:
            TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: primaryColor),

        // Headline styles — card titles, group labels
        headlineLarge:
            TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: primaryColor),
        headlineMedium:
            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: primaryColor),
        headlineSmall:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),

        // Title styles — list items, dialog titles
        titleLarge:
            TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: primaryColor),
        titleMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
        titleSmall:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor),

        // Body styles — general content text
        bodyLarge:
            TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: primaryColor),
        bodyMedium:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: primaryColor),
        bodySmall:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor),

        // Label styles — chips, captions, form labels
        labelLarge:
            TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor),
        labelMedium:
            TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor),
        labelSmall:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: secondaryColor),
      ),
    );
  }

  /// JetBrains Mono — monospace typeface for numeric data.
  ///
  /// Apply this explicitly to any widget showing telemetry values:
  ///   style: AppTheme.monoStyle(fontSize: 28, fontWeight: FontWeight.w600)
  static TextStyle monoStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: -0.5, // Tighter for dense numeric displays
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Light Theme (default)
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get light {
    final textTheme =
        _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
        primary: AppColors.accent,
        onPrimary: AppColors.surface,
        secondary: AppColors.textSecondary,
        onSecondary: AppColors.surface,
        error: AppColors.aqiPoor,
        onError: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // 1px bottom border instead of elevation shadow.
        shape: const Border(
          bottom: BorderSide(color: AppColors.border, width: _kBorderWidth),
        ),
      ),

      // --- Cards ---
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_kBorderRadius)),
          side: BorderSide(color: AppColors.border, width: _kBorderWidth),
        ),
      ),

      // --- Inputs ---
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide:
              const BorderSide(color: AppColors.border, width: _kBorderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide:
              const BorderSide(color: AppColors.border, width: _kBorderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide:
              const BorderSide(color: AppColors.accent, width: _kBorderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide:
              const BorderSide(color: AppColors.aqiPoor, width: _kBorderWidth),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // --- Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(
              color: AppColors.border, width: _kBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // --- List Tile ---
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        minLeadingWidth: 20,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          side:
              const BorderSide(color: AppColors.border, width: _kBorderWidth),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),

      // --- Chip ---
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: AppColors.background,
        side:
            const BorderSide(color: AppColors.border, width: _kBorderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // --- Bottom Navigation ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.borderSubtle,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),

      // --- Scroll Behavior ---
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(AppColors.border),
        radius: const Radius.circular(2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dark OLED Theme
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    final textTheme = _buildTextTheme(
        AppColors.textPrimaryDark, AppColors.textSecondaryDark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        outline: AppColors.borderDark,
        primary: AppColors.accentDark,
        onPrimary: AppColors.surfaceDark,
        secondary: AppColors.textSecondaryDark,
        onSecondary: AppColors.surfaceDark,
        error: AppColors.aqiPoor,
        onError: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: textTheme,
      primaryTextTheme: textTheme,

      // --- AppBar ---
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        shape: const Border(
          bottom:
              BorderSide(color: AppColors.borderDark, width: _kBorderWidth),
        ),
      ),

      // --- Cards ---
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(_kBorderRadius)),
          side: BorderSide(color: AppColors.borderDark, width: _kBorderWidth),
        ),
      ),

      // --- Inputs ---
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide: const BorderSide(
              color: AppColors.borderDark, width: _kBorderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide: const BorderSide(
              color: AppColors.borderDark, width: _kBorderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide: const BorderSide(
              color: AppColors.accentDark, width: _kBorderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          borderSide:
              const BorderSide(color: AppColors.aqiPoor, width: _kBorderWidth),
        ),
        hintStyle: const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),

      // --- Buttons ---
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.accentDark,
          foregroundColor: AppColors.surfaceDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(
              color: AppColors.borderDark, width: _kBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          textStyle: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_kBorderRadius),
          ),
        ),
      ),

      // --- Divider ---
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
        space: 1,
      ),

      // --- List Tile ---
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        minLeadingWidth: 20,
      ),

      // --- Dialog ---
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
          side: const BorderSide(
              color: AppColors.borderDark, width: _kBorderWidth),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondaryDark,
        ),
      ),

      // --- Chip ---
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: AppColors.backgroundDark,
        side: const BorderSide(
            color: AppColors.borderDark, width: _kBorderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_kBorderRadius),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // --- Bottom Navigation ---
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.borderDark,
        shadowColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),

      // --- Scroll Behavior ---
      scrollbarTheme: ScrollbarThemeData(
        thickness: WidgetStateProperty.all(4),
        thumbColor: WidgetStateProperty.all(AppColors.borderDark),
        radius: const Radius.circular(2),
      ),
    );
  }
}
