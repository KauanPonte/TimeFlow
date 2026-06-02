import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class BalanceCard extends StatelessWidget {
  final double monthBalance;

  const BalanceCard({
    super.key,
    required this.monthBalance,
  });

  String _formatBalanceAsHoursMinutes(double hours) {
    final isNegative = hours < 0;
    final absHours = hours.abs();
    final h = absHours.toInt();
    final m = ((absHours - h) * 60).toInt();
    final sign = isNegative ? '-' : '';
    return '$sign${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = monthBalance >= 0;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryLight30 : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.successLight10
                  : AppColors.errorLight10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? AppColors.success : AppColors.error,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo acumulado',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${monthBalance >= 0 ? '+' : ''}${_formatBalanceAsHoursMinutes(monthBalance)}',
                  style: AppTextStyles.h2.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'total de horas acumuladas',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.68),
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
