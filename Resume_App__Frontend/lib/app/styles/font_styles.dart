import 'package:flutter/material.dart';
import 'app_colors.dart'; // (the file above)

class AppTextStyles {
  static TextStyle get button => TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: AppColors.textPrimary, // dynamic
        shadows: const [
          Shadow(
            blurRadius: 4.0,
            color: Colors.black45,
            offset: Offset(1, 1),
          ),
        ],
      );

  static TextStyle get jobTitle => TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary, // dynamic
      );

  static TextStyle get jobInfo => TextStyle(
        fontSize: 16.0,
        color: AppColors.textSecondary, // dynamic
      );

  static TextStyle get jobDetail => TextStyle(
        fontSize: 14.0,
        color: AppColors.textSecondary, // dynamic
      );
}
