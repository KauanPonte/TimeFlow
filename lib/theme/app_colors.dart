import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF303F9F); // indigo700
  static const Color primaryLight = Color(0xFF5C6BC0); // indigo400
  static const Color accent = Color(0xFF64B5F6); // blue300

  static const Color bgLight = Color(0xFFE8EAF6); // indigo50
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color surface90 = Color(0xE6FFFFFF); // 90% opacity
  static const Color surface80 = Color(0xCCFFFFFF); // 80%
  static const Color surface70 = Color(0xB3FFFFFF); // 70%
  static const Color surface50 = Color(0x80FFFFFF); // 50%
  static const Color surface30 = Color(0x4DFFFFFF); // 30%

  static const Color border = Color(0xFFE0E0E0); // grey300
  static const Color borderLight = Color(0xFFE0E0E0); // grey300
  static const Color greyLight = Color(0xFFF5F5F5);

  static const Color textPrimary = Color(0xFF212121); // black87
  static const Color textSecondary = Color(0xFF757575); // grey600

  // Snackbar colors
  static const Color success = Color(0xFF4CAF50); // green
  static const Color error = Color(0xFFE53935); // red
  static const Color info = Color(0xFF2196F3); // blue
  static const Color warning = Color(0xFFFF9800); // orange

  // Opacity colors for shadows, overlays and backgrounds
  static const Color shadow = Color(0x08000000); // black 3%
  static const Color shadowMedium = Color(0x14000000); // black 8%

  // Primary variants with opacity
  static const Color primaryLight10 = Color(0x1A303F9F); // primary 10%
  static const Color primaryLight20 = Color(0x33303F9F); // primary 20%
  static const Color primaryLight30 = Color(0x4D303F9F); // primary 30%

  // Border variants with opacity
  static const Color borderLight30 = Color(0x4DE0E0E0); // borderLight 30%
  static const Color borderLight50 = Color(0x80E0E0E0); // borderLight 50%

  // Success variants
  static const Color successLight10 = Color(0x1A4CAF50); // success 10%

  // Error variants
  static const Color errorLight10 = Color(0x1AE53935); // error 10%
  static const Color errorLight20 = Color(0x33E53935); // error 20%

  // Warning variants
  static const Color warningLight8 = Color(0x14FF9800); // warning 8%
  static const Color warningLight10 = Color(0x1AFF9800); // warning 10%
  static const Color warningLight20 = Color(0x33FF9800); // warning 20%
  static const Color warningLight30 = Color(0x4DFF9800); // warning 30%
  static const Color warningLight40 = Color(
      0x66FF9800); // warning 40%`n`n  // Text secondary variants`n  static const Color textSecondary50 = Color(0x80757575); // textSecondary 50%
}
