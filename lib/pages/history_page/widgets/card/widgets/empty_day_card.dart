import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'day_card_helpers.dart';

/// Day card para dias sem eventos (futuros ou sem registros).
class EmptyDayCard extends StatelessWidget {
  final String diaId;
  final bool disabled;
  final bool isAdmin;
  final VoidCallback? onAddEvento;
  final VoidCallback? onBatchEdit;
  final VoidCallback? onRequestSolicitation;
  final String? holidayName;

  /// Funcionário: abre dialog para enviar justificativa de falta.
  /// Admin: abre dialog para definir justificativa diretamente.
  final VoidCallback? onJustify;
  final JustificativaModel? justificativa;

  const EmptyDayCard({
    super.key,
    required this.diaId,
    this.disabled = false,
    this.isAdmin = false,
    this.onAddEvento,
    this.onBatchEdit,
    this.onRequestSolicitation,
    this.onJustify,
    this.justificativa,
    this.holidayName,
  });

  bool get _isAbsentDay => !disabled && !isWeekendOrHoliday(diaId);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: (_isAbsentDay && justificativa != null)
            ? AppColors.error.withValues(alpha: 0.04)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_isAbsentDay && justificativa != null)
              ? AppColors.error.withValues(alpha: 0.3)
              : disabled
                  ? AppColors.borderLight.withValues(alpha: 0.7)
                  : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: disabled
                    ? AppColors.borderLight.withValues(alpha: 0.4)
                    : AppColors.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: disabled
                      ? AppColors.borderLight.withValues(alpha: 0.7)
                      : AppColors.borderLight,
                ),
              ),
              child: const Icon(
                Icons.calendar_today,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
            title: Text(
              formatDate(diaId),
              style: AppTextStyles.bodyMedium.copyWith(
                color: (_isAbsentDay && justificativa != null)
                    ? AppColors.error
                    : AppColors.textSecondary,
                fontWeight: (_isAbsentDay && justificativa != null)
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            subtitle: disabled
                ? null
                : Text(
                    (_isAbsentDay && justificativa != null)
                        ? 'Falta justificada'
                        : 'Sem registros',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: (_isAbsentDay && justificativa != null)
                          ? AppColors.error.withValues(alpha: 0.7)
                          : AppColors.textSecondary.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
            trailing: _buildTrailing(),
          ),

          // Feriado / recesso banner
          if (holidayName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: buildHolidayBanner(holidayName!),
            ),

          // Justificativa chip (funcionário e admin)
          if (_isAbsentDay && justificativa != null)
            _buildJustificativaChip(),

          // Admin: botão adicionar justificativa quando não há nenhuma
          if (_isAbsentDay && isAdmin && justificativa == null && onJustify != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: InkWell(
                onTap: onJustify,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_late_outlined,
                          size: 13, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'Adicionar justificativa de falta',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildTrailing() {
    if (disabled) return null;

    if (isAdmin && onBatchEdit != null) {
      return IconButton(
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        padding: EdgeInsets.zero,
        onPressed: onBatchEdit,
        icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
        tooltip: 'Editar dia',
      );
    }
    if (isAdmin && onAddEvento != null) {
      return IconButton(
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        padding: EdgeInsets.zero,
        onPressed: onAddEvento,
        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        tooltip: 'Adicionar ponto',
      );
    }

    if (onRequestSolicitation != null) {
      return IconButton(
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        padding: EdgeInsets.zero,
        onPressed: onRequestSolicitation,
        icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
        tooltip: 'Solicitar alteração',
      );
    }
    return null;
  }

  Widget _buildJustificativaChip() {
    final status = justificativa!.status;
    Color chipColor;
    IconData chipIcon;
    String chipLabel;

    switch (status) {
      case JustificativaStatus.approved:
        chipColor = AppColors.success;
        chipIcon = Icons.check_circle_outline;
        chipLabel = 'Justificativa aprovada';
        break;
      case JustificativaStatus.pending:
        chipColor = AppColors.warning;
        chipIcon = Icons.hourglass_empty;
        chipLabel = 'Justificativa pendente';
        break;
      case JustificativaStatus.rejected:
        chipColor = AppColors.error;
        chipIcon = Icons.cancel_outlined;
        chipLabel = 'Justificativa recusada';
        break;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
        // Admin pode tocar no chip para editar/sobrescrever a justificativa
        onTap: isAdmin && onJustify != null ? onJustify : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(chipIcon, size: 13, color: chipColor),
                  const SizedBox(width: 6),
                  Text(
                    chipLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: chipColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  if (isAdmin && onJustify != null) ...[
                    const Spacer(),
                    const Icon(Icons.edit_outlined,
                        size: 12, color: AppColors.textSecondary),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                justificativa!.justificativa,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (status == JustificativaStatus.rejected &&
                  justificativa!.reason != null &&
                  justificativa!.reason!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  'Motivo: ${justificativa!.reason}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
