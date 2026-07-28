import 'package:flutter/material.dart';

/// Provides Material 3 themes that follow the Android system's light/dark mode.
///
/// No in-app theme selector is provided — the app automatically adapts to
/// the device's current brightness setting via [ThemeMode.system].
class AppTheme {
  AppTheme._();

  /// Light theme using Material 3 with a neutral seed color.
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF1A1A2E),
      );

  /// Dark theme using Material 3 with a neutral seed color.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF1A1A2E),
      );
}