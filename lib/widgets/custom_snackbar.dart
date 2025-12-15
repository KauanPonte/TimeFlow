import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

/// Custom SnackBar widget with styled appearance
class CustomSnackbar {
  /// Shows a success SnackBar with green background
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle_outline,
    );
  }

  /// Shows an error SnackBar with red background
  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.error,
      icon: Icons.error_outline,
    );
  }

  /// Shows an info SnackBar with blue background
  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.info,
      icon: Icons.info_outline,
    );
  }

  /// Shows a warning SnackBar with orange background
  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning_amber_outlined,
    );
  }

  /// Internal method to show the custom styled SnackBar
  static void _show(
    BuildContext context,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        duration: const Duration(seconds: 3),
        elevation: 6,
      ),
    );
  }
}
