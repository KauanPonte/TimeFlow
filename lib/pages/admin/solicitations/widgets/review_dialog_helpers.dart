import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

// ── Funções helpers de apresentação ─────────────────────────────────────────

String labelForTipo(String tipo) {
  switch (tipo) {
    case 'entrada':
      return 'Entrada';
    case 'pausa':
      return 'Pausa';
    case 'retorno':
      return 'Retorno';
    case 'saida':
      return 'Saída';
    default:
      return tipo;
  }
}

IconData iconForTipo(String tipo) {
  switch (tipo) {
    case 'entrada':
      return Icons.login_rounded;
    case 'pausa':
      return Icons.coffee_rounded;
    case 'retorno':
      return Icons.replay_rounded;
    case 'saida':
      return Icons.logout_rounded;
    default:
      return Icons.access_time;
  }
}

Color colorForTipo(String tipo) {
  switch (tipo) {
    case 'entrada':
      return AppColors.success;
    case 'pausa':
      return const Color(0xFF3DB2FF);
    case 'retorno':
      return AppColors.warning;
    case 'saida':
      return AppColors.error;
    default:
      return AppColors.primary;
  }
}

String actionLabel(SolicitationAction action) {
  switch (action) {
    case SolicitationAction.add:
      return 'Adicionar';
    case SolicitationAction.edit:
      return 'Editar';
    case SolicitationAction.delete:
      return 'Remover';
  }
}

Color actionColor(SolicitationAction action) {
  switch (action) {
    case SolicitationAction.add:
      return AppColors.success;
    case SolicitationAction.edit:
      return AppColors.primary;
    case SolicitationAction.delete:
      return AppColors.error;
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

/// Chip de ação rápida (Aceitar todos / Rejeitar todos).
class QuickActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionChip({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Chip "Antes / Depois / Novo" com label, tipo e horário.
class BeforeAfterChip extends StatelessWidget {
  final String label;
  final String tipo;
  final DateTime horario;
  final Color color;

  const BeforeAfterChip({
    super.key,
    required this.label,
    required this.tipo,
    required this.horario,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final hora = DateFormat('HH:mm').format(horario);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${labelForTipo(tipo)} $hora',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
