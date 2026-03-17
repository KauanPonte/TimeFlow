import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class StatusCard extends StatelessWidget {
  final String statusLabel;
  final String todayWorkedDisplay;
  final double workProgress;
  final int workedMinutes;
  final int monthWorkedMinutes;
  final int monthExpectedMinutes;

  const StatusCard({
    super.key,
    required this.statusLabel,
    required this.todayWorkedDisplay,
    required this.workProgress,
    required this.workedMinutes,
    this.monthWorkedMinutes = 0,
    this.monthExpectedMinutes = 0,
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

  String _formatMinutesAsHoursLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '$h horas';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Calcula o primeiro e último dia do mês conforme sua lógica
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final String formattedFirstDay =
        DateFormat('dd/MM/yyyy').format(firstDayOfMonth);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final String formattedLastDay =
        DateFormat('dd/MM/yyyy').format(lastDayOfMonth);

    final hasExpected = monthExpectedMinutes > 0;
    final monthlyProgress = hasExpected
        ? '${_formatMinutesAsHoursLabel(monthWorkedMinutes)} de ${_formatMinutesAsHoursLabel(monthExpectedMinutes)}/mês'
        : '';

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(workProgress * 100).toStringAsFixed(0)}% da jornada diária',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),

                // --- SEÇÃO DE DATAS E MÊS ---
                const SizedBox(height: 12),
                Text(
                  '$formattedFirstDay à $formattedLastDay',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                if (monthlyProgress.isNotEmpty)
                  Text(
                    monthlyProgress,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Bloco da animação Lottie mantido
          SizedBox(
            width: 72,
            height: 72,
            child: FutureBuilder<String>(
              future: rootBundle
                  .loadString('assets/lottie/gears.json')
                  .catchError((_) => ''),
              builder: (context, snapshot) {
                if (!snapshot.hasData || (snapshot.data ?? '').isEmpty) {
                  return const Icon(Icons.timer_outlined,
                      size: 40, color: AppColors.primary);
                }
                return Lottie.asset('assets/lottie/gears.json',
                    fit: BoxFit.contain);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Renomeei para evitar conflito com a biblioteca intl se você decidir usá-la no futuro
class CustomDateFormatter {
  CustomDateFormatter(String s);

  String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '${day}_${month}_$year';
  }
}
