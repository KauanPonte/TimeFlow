import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (icon != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: AppColors.surface,
            ),
          ),
        const SizedBox(height: 30),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }
}
