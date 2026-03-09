import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class TodayTimeline extends StatelessWidget {
  final Map<String, String> registros;
  const TodayTimeline({super.key, required this.registros});

  static const _order = ['entrada', 'pausa', 'retorno', 'saida'];
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

  @override
  Widget build(BuildContext context) {
    final events = _order.where((k) => registros[k] != null).toList();
    if (events.isEmpty) return const SizedBox.shrink();

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
        children: List.generate(events.length, (i) {
          final key = events[i];
          final color = _colors[key]!;
          final isLast = i == events.length - 1;
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
                        child: Icon(_icons[key]!, color: color, size: 18),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _labels[key]!,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
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
                            registros[key]!,
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
