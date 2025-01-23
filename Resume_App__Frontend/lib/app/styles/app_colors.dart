import 'package:flutter/material.dart';

/// Centralized app color definitions.
/// We keep them in two sets: one for dark theme, one for light theme.
/// A static boolean [isDarkMode] determines which set is returned by the getters.
class AppColors {
  // -------------------------------------------------
  // (A) TRACK THE THEME STATE
  // -------------------------------------------------
  /// Controls whether the app is in dark mode. By default, false = light mode.
  static bool isDarkMode = false;

  /// Call this whenever your theme mode changes at runtime.
  static void updateDarkMode(bool dark) {
    isDarkMode = dark;
  }

  // -------------------------------------------------
  // (B) DARK THEME COLORS
  // -------------------------------------------------
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E24);

  // Accent
  static const Color _darkAccentBlue = Color(0xFF4056F4);
  static const Color _darkAccentOrange = Color(0xFFFA7344);

  // Text
  static const Color _darkTextPrimary = Color(0xFFFDFEFE);
  static const Color _darkTextSecondary = Color(0xFFB3B3B3);

  // Icons
  static const Color _darkIconColor = Color(0xFFFDFEFE);

  // Supplementary
  static const Color _darkHighlightSuccess = Color(0xFF4CAF50);
  static const Color _darkError = Color(0xFFFF1744);

  /// A mild shadow color that complements the dark theme accent.
  static const Color _darkButtonShadow = Color(0xFF2A39B1);

  // -------------------------------------------------
  // (C) LIGHT THEME COLORS
  // -------------------------------------------------
  static const Color _lightBackground = Color(0xFFF9FAFD);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  // Accent
  static const Color _lightAccentBlue = Color(0xFF4056F4);
  static const Color _lightAccentOrange = Color(0xFFFA7344);

  // Text
  static const Color _lightTextPrimary = Color(0xFF202124);
  static const Color _lightTextSecondary = Color(0xFF5F6368);

  // Icons
  static const Color _lightIconColor = Color(0xFF202124);

  // Supplementary
  static const Color _lightHighlightSuccess = Color(0xFF4CAF50);
  static const Color _lightError = Color(0xFFFF1744);

  /// A mild shadow color that complements the light theme accent.
  static const Color _lightButtonShadow = Color(0xFF8F9DFE);

  // -------------------------------------------------
  // (D) GETTERS: SWITCH BASED ON isDarkMode
  // -------------------------------------------------
  static Color get background =>
      isDarkMode ? _darkBackground : _lightBackground;

  static Color get surface => isDarkMode ? _darkSurface : _lightSurface;

  static Color get accentBlue =>
      isDarkMode ? _darkAccentBlue : _lightAccentBlue;

  static Color get accentOrange =>
      isDarkMode ? _darkAccentOrange : _lightAccentOrange;

  static Color get textPrimary =>
      isDarkMode ? _darkTextPrimary : _lightTextPrimary;

  static Color get textSecondary =>
      isDarkMode ? _darkTextSecondary : _lightTextSecondary;

  static Color get iconColor => isDarkMode ? _darkIconColor : _lightIconColor;

  static Color get highlightSuccess =>
      isDarkMode ? _darkHighlightSuccess : _lightHighlightSuccess;

  static Color get error => isDarkMode ? _darkError : _lightError;

  static Color get buttonShadow =>
      isDarkMode ? _darkButtonShadow : _lightButtonShadow;
}
