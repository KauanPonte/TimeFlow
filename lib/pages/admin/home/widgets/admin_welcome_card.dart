import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class AdminWelcomeCard extends StatelessWidget {
  final String employeeName;

  const AdminWelcomeCard({
    super.key,
    required this.employeeName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            isDark ? AppColors.brandGradient : AppColors.softBrandGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Olá, ${employeeName.split(' ')[0]}!',
                  style: AppTextStyles.h3.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bem-vindo ao painel administrativo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.admin_panel_settings,
            color: textColor,
            size: 32,
          ),
        ],
      ),
    );
  }
}
