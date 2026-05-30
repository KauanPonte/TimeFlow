import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_palette.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String statusLabel;
  const StatusBadge({super.key, required this.statusLabel});

  Color get _dotColor {
    switch (statusLabel) {
      case 'Trabalhando...':
        return AppColors.success;
      case 'Pausado':
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = _dotColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.palette.borderLight),
        boxShadow: [
          BoxShadow(
              color: context.palette.shadow, blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dotColor,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status atual',
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.palette.textSecondary, fontSize: 12),
              ),
              Text(
                statusLabel,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.palette.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
