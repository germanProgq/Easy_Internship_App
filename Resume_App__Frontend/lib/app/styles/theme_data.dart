import 'package:flutter/material.dart';
import 'app_colors.dart';

ThemeData buildAppTheme() {
  final bool dark = AppColors.isDarkMode;

  // Create a color scheme that fits your custom colors
  final colorScheme = dark
      ? ColorScheme.dark(
          primary: AppColors.accentBlue,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textPrimary,
        )
      : ColorScheme.light(
          primary: AppColors.accentBlue,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: AppColors.textPrimary,
          onSurface: AppColors.textPrimary,
          onError: AppColors.textPrimary,
        );

  return ThemeData(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.accentBlue,

    // IconTheme for general icons
    iconTheme: IconThemeData(
      color: AppColors.iconColor,
    ),

    // BottomNavigationBar theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accentBlue,
      unselectedItemColor: AppColors.iconColor,
      // You can also set selectedIconTheme or unselectedIconTheme if you want
      // more fine-grained control over the size, opacity, etc.
    ),

    // TextTheme
    textTheme: TextTheme(
      bodyLarge: TextStyle(
        fontSize: 18,
        color: AppColors.textPrimary,
      ),
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentBlue,
        foregroundColor: AppColors.textPrimary,
      ),
    ),
  );
}
