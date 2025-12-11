import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';

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
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ).copyWith(color: AppColors.surface),
        ),
        const SizedBox(height: 20),
        const Text(
          'Controle de Ponto Simplificado',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.surface90,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
