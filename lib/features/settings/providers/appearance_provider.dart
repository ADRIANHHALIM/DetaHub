// lib/features/settings/providers/appearance_provider.dart
//
// Riverpod state management for user-selected ThemeMode.
// Persisted locally via SharedPreferences with zero cloud dependencies.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemePrefKey = 'detahub_theme_mode';

class AppearanceNotifier extends StateNotifier<ThemeMode> {
  AppearanceNotifier() : super(ThemeMode.system) {
    _loadPersistedTheme();
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_kThemePrefKey);
      if (saved != null) {
        state = switch (saved) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
    } catch (_) {
      // Fallback cleanly to system mode on read error
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringValue = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await prefs.setString(_kThemePrefKey, stringValue);
    } catch (_) {
      // SharedPreferences failure should not crash the UI
    }
  }
}

final appearanceProvider =
    StateNotifierProvider<AppearanceNotifier, ThemeMode>((ref) {
  return AppearanceNotifier();
});
