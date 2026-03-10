import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class HomeGreeting extends StatelessWidget {
  final String employeeName;

  const HomeGreeting({super.key, required this.employeeName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Olá, ${employeeName.isNotEmpty ? employeeName : 'Colaborador'}!',
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Aqui está seu resumo de hoje',
          style:
              AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
