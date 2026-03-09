import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class IncompletosCard extends StatelessWidget {
  final List<MapEntry<String, Map<String, String>>> incompletos;
  const IncompletosCard({super.key, required this.incompletos});

  String _formatDate(String key) {
    try {
      final d = DateTime.parse(key);
      return DateFormat('dd/MM/yyyy', 'pt_BR').format(d);
    } catch (_) {
      return key;
    }
  }

  String _motivo(Map<String, String> m) {
    if (m['pausa'] != null && m['retorno'] == null) {
      return 'Pausa sem retorno';
    }
    return 'Entrada sem saída';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.warningLight8,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warningLight30),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Registros incompletos',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${incompletos.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.warningLight20),
          ...List.generate(incompletos.length, (i) {
            final entry = incompletos[i];
            final isLast = i == incompletos.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 16, color: AppColors.warning),
                      const SizedBox(width: 10),
                      Text(
                        _formatDate(entry.key),
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        _motivo(entry.value),
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.warning, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(
                      height: 1, indent: 42, color: AppColors.warningLight20),
              ],
            );
          }),
        ],
      ),
    );
  }
}
