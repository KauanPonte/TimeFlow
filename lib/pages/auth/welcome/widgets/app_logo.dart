import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(12),
          width: 120,
          height: 120,
          child: ClipOval(
            child: Image.asset(
              'assets/app_icon/timeflow.png',
              fit: BoxFit.cover,
              width: 120,
              height: 120,
            ),
          ),
        ),
        Text(
          'TimeFlow',
          style: AppTextStyles.h1.copyWith(color: AppColors.surface),
        ),
        Text(
          'Controle de Ponto Simplificado',
          style: AppTextStyles.subtitle.copyWith(color: AppColors.surface90),
        ),
      ],
    );
  }
}
