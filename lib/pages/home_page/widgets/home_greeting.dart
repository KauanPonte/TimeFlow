import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class HomeGreeting extends StatelessWidget {
  final String employeeName;

  const HomeGreeting({super.key, required this.employeeName});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.white : AppColors.textPrimary;
    final name = employeeName.isNotEmpty ? employeeName : 'Colaborador';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient:
            isDark ? AppColors.brandGradient : AppColors.softBrandGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.primaryLight30 : AppColors.surface70,
        ),
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
                  'Olá, $name!',
                  style: AppTextStyles.h2.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Aqui está seu resumo de hoje',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
