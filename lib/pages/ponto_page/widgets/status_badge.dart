import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dotColor = _dotColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryLight30 : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
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
                style: AppTextStyles.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                  fontSize: 12,
                ),
              ),
              Text(
                statusLabel,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusLabel == 'Trabalhando...' ||
                          statusLabel == 'Pausado'
                      ? dotColor
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
