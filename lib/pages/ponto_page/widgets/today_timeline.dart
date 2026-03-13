import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class TodayTimeline extends StatelessWidget {
  /// Lista ordenada de eventos do dia: cada item é {'tipo': String, 'hora': String, 'origin'?: String}.
  final List<Map<String, String>> eventos;
  const TodayTimeline({super.key, required this.eventos});

  static const _labels = {
    'entrada': 'Entrada',
    'pausa': 'Pausa',
    'retorno': 'Retorno',
    'saida': 'Saída',
  };
  static const _icons = {
    'entrada': Icons.login_rounded,
    'pausa': Icons.coffee_rounded,
    'retorno': Icons.replay_rounded,
    'saida': Icons.logout_rounded,
  };
  static const _colors = {
    'entrada': Color(0xFF18A999),
    'pausa': Color(0xFF3DB2FF),
    'retorno': Color(0xFFF7A500),
    'saida': Color(0xFFE53935),
  };

  static const _originLabels = {
    'registrado': 'Registrado',
    'solicitado': 'Solicitado',
    'ajustado': 'Ajustado',
  };
  static const _originColors = {
    'registrado': AppColors.success,
    'solicitado': AppColors.info,
    'ajustado': AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    if (eventos.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(eventos.length, (i) {
          final ev = eventos[i];
          final tipo = ev['tipo'] ?? '';
          final hora = ev['hora'] ?? '--:--';
          final origin = ev['origin'] ?? 'registrado';
          final color = _colors[tipo] ?? AppColors.textSecondary;
          final icon = _icons[tipo] ?? Icons.access_time;
          final label = _labels[tipo] ?? tipo;
          final isLast = i == eventos.length - 1;
          final originLabel = _originLabels[origin] ?? origin;
          final originColor = _originColors[origin] ?? AppColors.textSecondary;
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // linha + bolinha
                SizedBox(
                  width: 56,
                  child: Column(
                    children: [
                      if (i == 0) const SizedBox(height: 16),
                      Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: AppColors.borderLight,
                          ),
                        ),
                      if (isLast) const SizedBox(height: 16),
                    ],
                  ),
                ),
                // conteúdo
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: i == 0 ? 16 : 8,
                      bottom: isLast ? 16 : 8,
                      right: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                label,
                                style: AppTextStyles.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: originColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: originColor.withValues(alpha: 0.3),
                                    width: 0.5,
                                  ),
                                ),
                                child: Text(
                                  originLabel,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: originColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hora,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
