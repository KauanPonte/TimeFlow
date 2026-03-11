import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'day_card_helpers.dart';

/// Lista de solicitações pendentes exibida dentro dos day cards.
/// Reutilizada tanto no FilledDayCard quanto no PendingOnlyDayCard.
class PendingSolicitationsSection extends StatelessWidget {
  final List<SolicitationModel> solicitations;
  final bool isAdmin;
  final void Function(String solicitationId)? onCancel;

  const PendingSolicitationsSection({
    super.key,
    required this.solicitations,
    required this.isAdmin,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.pending_actions_rounded,
                size: 14, color: AppColors.warning),
            const SizedBox(width: 6),
            Text(
              'Solicitações em análise',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...solicitations.map((sol) => _SolicitationCard(
              sol: sol,
              isAdmin: isAdmin,
              onCancel: onCancel,
            )),
      ],
    );
  }
}

class _SolicitationCard extends StatelessWidget {
  final SolicitationModel sol;
  final bool isAdmin;
  final void Function(String)? onCancel;

  const _SolicitationCard({
    required this.sol,
    required this.isAdmin,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final createdStr = DateFormat('dd/MM · HH:mm').format(sol.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SolicitationHeader(
            createdStr: createdStr,
            solId: sol.id,
            isAdmin: isAdmin,
            onCancel: onCancel,
          ),
          const Divider(height: 1, indent: 10, endIndent: 10),
          ...sol.items.map((item) => _SolicitationItemRow(item: item)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SolicitationHeader extends StatelessWidget {
  final String createdStr;
  final String solId;
  final bool isAdmin;
  final void Function(String)? onCancel;

  const _SolicitationHeader({
    required this.createdStr,
    required this.solId,
    required this.isAdmin,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 12, color: AppColors.warning),
          const SizedBox(width: 5),
          Text(
            'Enviada em $createdStr',
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 10,
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onCancel != null && !isAdmin)
            InkWell(
              onTap: () => onCancel!(solId),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.close_rounded,
                        size: 11, color: AppColors.error),
                    const SizedBox(width: 2),
                    Text(
                      'Cancelar',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SolicitationItemRow extends StatelessWidget {
  final SolicitationItem item;

  const _SolicitationItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final aColor = actionColor(item.action);
    final tColor = colorForTipo(item.tipo);
    final horaStr = DateFormat('HH:mm').format(item.horario);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 4),
      child: Row(
        children: [
          // Badge de ação
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: aColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              actionLabel(item.action),
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: aColor,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(iconForTipo(item.tipo), size: 13, color: tColor),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              labelForTipo(item.tipo),
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 12,
              ),
            ),
          ),
          // Antes → Depois
          if (item.action == SolicitationAction.edit &&
              item.oldHorario != null) ...[
            Text(
              DateFormat('HH:mm').format(item.oldHorario!),
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 10, color: AppColors.textSecondary),
            ),
            Text(
              horaStr,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tColor,
              ),
            ),
          ] else if (item.action == SolicitationAction.delete) ...[
            Text(
              horaStr,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.error.withValues(alpha: 0.7),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ] else ...[
            Text(
              horaStr,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: tColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
