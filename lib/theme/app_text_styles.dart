import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  // Body text
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = const TextStyle(
    fontSize: 15,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmall = const TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  // Links
  static TextStyle link = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  // Subtitle
  static TextStyle subtitle = const TextStyle(
    fontSize: 16,
    letterSpacing: 0.5,
  );
}
