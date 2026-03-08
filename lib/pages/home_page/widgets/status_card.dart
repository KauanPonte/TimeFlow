import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class StatusCard extends StatelessWidget {
  final String statusLabel;
  final String todayWorkedDisplay;
  final double workProgress;

  const StatusCard({
    super.key,
    required this.statusLabel,
    required this.todayWorkedDisplay,
    required this.workProgress,
  });

  Color get _statusColor {
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  todayWorkedDisplay,
                  style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'trabalhado hoje',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: workProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(workProgress * 100).toStringAsFixed(0)}% da jornada diária',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 72,
            height: 72,
            child: FutureBuilder<String>(
              future: rootBundle
                  .loadString('assets/lottie/gears.json')
                  .catchError((_) => ''),
              builder: (context, snapshot) {
                if (!snapshot.hasData || (snapshot.data ?? '').isEmpty) {
                  return const Icon(
                    Icons.timer_outlined,
                    size: 40,
                    color: AppColors.primary,
                  );
                }
                try {
                  return Lottie.asset(
                    'assets/lottie/gears.json',
                    fit: BoxFit.contain,
                  );
                } catch (_) {
                  return const Icon(
                    Icons.timer_outlined,
                    size: 40,
                    color: AppColors.primary,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
