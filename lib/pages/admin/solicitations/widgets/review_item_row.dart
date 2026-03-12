import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'review_dialog_helpers.dart';

/// Card de um item de solicitação no dialog de revisão do admin.
/// Exibe ação, tipo, antes/depois e permite aceitar ou rejeitar individualmente.
class ReviewItemRow extends StatelessWidget {
  final SolicitationItem item;
  final SolicitationItemStatus status;

  /// True quando este item foi rejeitado por cascata (não pelo admin).
  final bool isCascadeRejected;

  /// Chamado quando o admin toca no item para alternar aceito/rejeitado.
  final VoidCallback? onTap;

  const ReviewItemRow({
    super.key,
    required this.item,
    required this.status,
    required this.isCascadeRejected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAccepted = status == SolicitationItemStatus.accepted;
    final color = colorForTipo(item.tipo);
    final acColor = actionColor(item.action);

    return Opacity(
      opacity: isCascadeRejected ? 0.5 : 1.0,
      child: InkWell(
        onTap: isCascadeRejected ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isAccepted
                ? AppColors.success.withValues(alpha: 0.05)
                : AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isAccepted
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isAccepted, acColor, color),
              const SizedBox(height: 8),
              _buildBeforeAfter(),
            ],
          ),
        ),
      ),
    );
  }

  // Sub-builders

  Widget _buildHeader(bool isAccepted, Color acColor, Color color) {
    return Row(
      children: [
        // Badge de ação (Adicionar / Editar / Remover)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: acColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            actionLabel(item.action),
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: acColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Icon(iconForTipo(item.tipo), size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          labelForTipo(item.tipo),
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        // Status: cascata ou toggle
        if (isCascadeRejected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Cascata',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          )
        else
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              key: ValueKey(isAccepted),
              color: isAccepted ? AppColors.success : AppColors.error,
              size: 22,
            ),
          ),
      ],
    );
  }

  Widget _buildBeforeAfter() {
    return Row(
      children: [
        if (item.action == SolicitationAction.edit ||
            item.action == SolicitationAction.delete) ...[
          BeforeAfterChip(
            label: 'Antes',
            tipo: item.oldTipo ?? item.tipo,
            horario: item.oldHorario ?? item.horario,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded,
              size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 8),
        ],
        if (item.action != SolicitationAction.delete)
          BeforeAfterChip(
            label: item.action == SolicitationAction.add ? 'Novo' : 'Depois',
            tipo: item.tipo,
            horario: item.horario,
            color: AppColors.success,
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Será removido',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
