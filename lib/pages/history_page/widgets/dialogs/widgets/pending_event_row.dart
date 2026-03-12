import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'solicitation_helpers.dart';

/// Linha somente-leitura de um evento já em solicitação pendente.
class PendingEventRow extends StatelessWidget {
  final Map<String, dynamic> ev;

  const PendingEventRow({super.key, required this.ev});

  @override
  Widget build(BuildContext context) {
    final tipo = (ev['tipo'] ?? '').toString();
    final at = ev['at'] as DateTime?;
    final hora = at != null ? DateFormat('HH:mm').format(at) : '--:--';
    final color = colorForTipo(tipo);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(iconForTipo(tipo), size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${labelForTipo(tipo)} — $hora',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Pendente',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9,
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
