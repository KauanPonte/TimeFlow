import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class MonthlySummaryCard extends StatelessWidget {
  final Future<MesResumo>? mesResumoFuture;
  final bool isLoading;

  const MonthlySummaryCard({
    super.key,
    required this.mesResumoFuture,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (mesResumoFuture == null && !isLoading) return const SizedBox.shrink();

    if (isLoading) {
      return _buildLoadingCard();
    }

    return FutureBuilder<MesResumo>(
      future: mesResumoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            snapshot.connectionState == ConnectionState.active) {
          return _buildLoadingCard();
        }
        if (!snapshot.hasData) return const SizedBox.shrink();
        final r = snapshot.data!;
        final h = r.workedMinutes ~/ 60;
        final m = r.workedMinutes % 60;
        final eH = r.expectedMinutes ~/ 60;
        final eM = r.expectedMinutes % 60;
        final balH = r.monthBalance.abs() ~/ 60;
        final balM = r.monthBalance.abs().toInt() % 60;
        final prefix = r.monthBalance >= 0 ? "+" : "-";

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniStat(
                'Trabalhado',
                '${h}h ${m.toString().padLeft(2, '0')}m',
                AppColors.textPrimary,
              ),
              _buildMiniStat(
                'Esperado',
                '${eH}h ${eM.toString().padLeft(2, '0')}m',
                AppColors.textSecondary,
              ),
              _buildMiniStat(
                'Saldo',
                '$prefix ${balH}h ${balM.toString().padLeft(2, '0')}m',
                r.monthBalance >= 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyLarge
              .copyWith(color: valueColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLoadingStat(),
          _buildLoadingStat(),
          _buildLoadingStat(),
        ],
      ),
    );
  }

  Widget _buildLoadingStat() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primaryLight10,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryLight20,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
