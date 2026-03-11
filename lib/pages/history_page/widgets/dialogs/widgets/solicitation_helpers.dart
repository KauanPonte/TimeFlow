import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

/// Helpers de apresentação reutilizados pelos widgets do diálogo de solicitação.

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

/// Cabeçalho de seção do diálogo.
class SolicitationSectionLabel extends StatelessWidget {
  final String label;
  final String? subtitle;

  const SolicitationSectionLabel(this.label, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
      ],
    );
  }
}

/// Botão "Desfazer" compacto.
class UndoButton extends StatelessWidget {
  final VoidCallback onTap;

  const UndoButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.undo_rounded,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 2),
            Text(
              'Desfazer',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
