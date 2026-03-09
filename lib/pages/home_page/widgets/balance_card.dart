import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class BalanceCard extends StatelessWidget {
  final double monthBalance;

  const BalanceCard({
    super.key,
    required this.monthBalance,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = monthBalance >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
                  'Saldo do mês',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : ''}${monthBalance.toStringAsFixed(2)} h',
                  style: AppTextStyles.h2.copyWith(
                    color: isPositive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'horas positivas ou negativas',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
