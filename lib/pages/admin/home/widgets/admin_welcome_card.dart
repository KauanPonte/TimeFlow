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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
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
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bem-vindo ao painel administrativo',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface90,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.admin_panel_settings,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }
}
