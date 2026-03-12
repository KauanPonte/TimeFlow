import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'review_dialog_helpers.dart';

/// Seção "Registros atuais do dia" exibida no topo do dialog de revisão.
class ReviewCurrentEvents extends StatelessWidget {
  final List<Map<String, dynamic>> eventosAtuais;

  const ReviewCurrentEvents({
    super.key,
    required this.eventosAtuais,
  });

  @override
  Widget build(BuildContext context) {
    if (eventosAtuais.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded,
                size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              'Registros atuais do dia',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: eventosAtuais.map((e) {
            final tipo = (e['tipo'] ?? '').toString();
            final at = e['at'] as DateTime?;
            final horaStr =
                at != null ? DateFormat('HH:mm').format(at) : '--:--';
            final color = colorForTipo(tipo);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconForTipo(tipo), size: 12, color: color),
                  const SizedBox(width: 4),
                  Text(
                    '${labelForTipo(tipo)} $horaStr',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Divider(height: 1),
        const SizedBox(height: 10),
      ],
    );
  }
}
