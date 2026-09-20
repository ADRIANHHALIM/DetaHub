// lib/core/theme/app_theme.dart
//
// DetaHub's calm, device-first presentation system.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Modular border radius definitions from Idea/Style.md Section 5.
const kRadiusCard = 22.0;
const kRadiusChip = 14.0;
const kRadiusModal = 28.0;
const kRadiusButton = 16.0;

/// Standard 1px border width for all interactive components (Style.md 5).
const kBorderWidth = 1.0;

abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────────────────────
  // Typography (Idea/Style.md Section 3)
  // ─────────────────────────────────────────────────────────────────────────

  /// Inter — primary UI typeface.
  /// Used for labels, body text, navigation, and all non-numeric strings.
  static TextTheme _buildTextTheme(Color primaryColor, Color secondaryColor) {
    return GoogleFonts.interTextTheme(
      TextTheme(
        // Display styles — section headers, screen titles
        displayLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: -1.2),
        displayMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: -0.8),
        displaySmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: -0.6),

        // Section Title: 18px · Bold · Sans-Serif · Tracking -0.02em (Style.md 3)
        headlineLarge: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: -0.4),
        headlineMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: primaryColor,
            letterSpacing: -0.36),
        headlineSmall: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),

        // Card Header: 14px · Medium · Sans-Serif (Style.md 3)
        titleLarge: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: primaryColor,
            letterSpacing: -0.2),
        titleMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: primaryColor),
        titleSmall: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor),

        // Body styles — general content text
        bodyLarge: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: primaryColor,
            height: 1.4),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: primaryColor),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor),

        // Label styles — chips, captions, form labels
        labelLarge: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: primaryColor),
        labelMedium: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: secondaryColor),
        labelSmall: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w400, color: secondaryColor),
      ),
    );
  }

  /// JetBrains Mono — monospace typeface for numeric data, units, and timestamps.
  ///
  /// Style.md 3:
  /// - Metric Display: 44px · SemiBold · Monospace
  /// - Subtitle / Unit: 12px · Regular · Monospace · All Caps · Tracking +0.05em
  /// - Caption / Timestamp: 11px · Regular · Monospace
  static TextStyle monoStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing ?? -0.5,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Light Theme (Default) — Style.md 2.1
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
        surfaceContainerHighest: AppColors.surfaceVariant,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSubtle,
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

      // Screens build their own headers; these defaults support secondary views.
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
        shape: const Border(),
      ),

      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadiusCard)),
          side: BorderSide(color: AppColors.border, width: kBorderWidth),
        ),
      ),

      // --- Inputs ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide:
              const BorderSide(color: AppColors.border, width: kBorderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide:
              const BorderSide(color: AppColors.border, width: kBorderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide:
              const BorderSide(color: AppColors.accent, width: kBorderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide:
              const BorderSide(color: AppColors.aqiPoor, width: kBorderWidth),
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
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: kBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
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

      // --- Dialog (Style.md 5: 10px radius) ---
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusCard),
          side: const BorderSide(color: AppColors.border, width: kBorderWidth),
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

      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: AppColors.surfaceVariant,
        side: const BorderSide(color: AppColors.border, width: kBorderWidth),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusChip)),
        labelStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // --- Bottom Sheet (Style.md 5: 16px top corners) ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(kRadiusModal)),
          side: BorderSide(color: AppColors.border, width: kBorderWidth),
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
  // Dark OLED Theme (LAT Web Native) — Style.md 2.1
  // ─────────────────────────────────────────────────────────────────────────

  static ThemeData get dark {
    final textTheme =
        _buildTextTheme(AppColors.textPrimaryDark, AppColors.textSecondaryDark);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.surfaceVariantDark,
        outline: AppColors.borderDark,
        outlineVariant: AppColors.borderSubtleDark,
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
        shape: const Border(),
      ),

      // --- Cards (Style.md 5: 10px radius, 1px border) ---
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(kRadiusCard)),
          side: BorderSide(color: AppColors.borderDark, width: kBorderWidth),
        ),
      ),

      // --- Inputs ---
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide: const BorderSide(
              color: AppColors.borderDark, width: kBorderWidth),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide: const BorderSide(
              color: AppColors.borderDark, width: kBorderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide: const BorderSide(
              color: AppColors.accentDark, width: kBorderWidth),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusButton),
          borderSide:
              const BorderSide(color: AppColors.aqiPoor, width: kBorderWidth),
        ),
        hintStyle:
            const TextStyle(color: AppColors.textMutedDark, fontSize: 14),
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
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(
              color: AppColors.borderDark, width: kBorderWidth),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          textStyle:
              GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusButton),
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

      // --- Dialog (Style.md 5: 10px radius) ---
      dialogTheme: DialogThemeData(
        elevation: 0,
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusCard),
          side: const BorderSide(
              color: AppColors.borderDark, width: kBorderWidth),
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

      // --- Chip (Style.md 5: 4px radius) ---
      chipTheme: ChipThemeData(
        elevation: 0,
        backgroundColor: AppColors.surfaceVariantDark,
        side:
            const BorderSide(color: AppColors.borderDark, width: kBorderWidth),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusChip),
        ),
        labelStyle:
            GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
      ),

      // --- Bottom Sheet (Style.md 5: 16px top corners) ---
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(kRadiusModal)),
          side: BorderSide(color: AppColors.borderDark, width: kBorderWidth),
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
