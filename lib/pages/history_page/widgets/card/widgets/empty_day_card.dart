import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'day_card_helpers.dart';

class EmptyDayCard extends StatelessWidget {
  final String diaId;
  final bool disabled;
  final bool isAdmin;
  final VoidCallback? onAddEvento;
  final VoidCallback? onBatchEdit;
  final VoidCallback? onRequestSolicitation;
  final String? holidayName;
  final VoidCallback? onOpenDayActions;

  final VoidCallback? onJustify;
  final VoidCallback? onDeleteJustificativa;
  final JustificativaModel? justificativa;

  final AbonoModel? abono;
  final VoidCallback? onApplyAbono;
  final VoidCallback? onDeleteAbono;

  const EmptyDayCard({
    super.key,
    required this.diaId,
    this.disabled = false,
    this.isAdmin = false,
    this.onAddEvento,
    this.onBatchEdit,
    this.onRequestSolicitation,
    this.onJustify,
    this.onDeleteJustificativa,
    this.justificativa,
    this.abono,
    this.onApplyAbono,
    this.onDeleteAbono,
    this.holidayName,
    this.onOpenDayActions,
  });

  bool get _isAbsentDay =>
      !disabled && !isWeekendOrHoliday(diaId) && holidayName == null;

  bool get _hasHighlight =>
      _isAbsentDay && (abono != null || justificativa != null);

  Color get _absentColor {
    if (abono != null && abono!.status == AbonoStatus.approved) {
      return AppColors.warning;
    }
    return AppColors.error;
  }

  String get _subtitleText {
    if (!_isAbsentDay) return 'Sem registros';
    if (abono != null) {
      switch (abono!.status) {
        case AbonoStatus.approved:
          return 'Abono aplicado';
        case AbonoStatus.pending:
          return 'Abono pendente';
        case AbonoStatus.rejected:
          return 'Abono recusado';
      }
    }
    if (justificativa != null) return 'Falta justificada';
    return 'Sem registros';
  }

  bool get _isFullDayAbonoApproved =>
      abono != null &&
      abono!.status == AbonoStatus.approved &&
      abono!.isFullDay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _hasHighlight
            ? _absentColor.withValues(alpha: 0.04)
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasHighlight
              ? _absentColor.withValues(alpha: 0.3)
              : disabled
                  ? (isDark
                      ? AppColors.primaryLight20
                      : AppColors.borderLight.withValues(alpha: 0.7))
                  : (isDark ? AppColors.primaryLight30 : AppColors.borderLight),
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
                    ? colorScheme.onSurface.withValues(alpha: 0.08)
                    : colorScheme.onSurface.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: disabled
                      ? colorScheme.onSurface.withValues(alpha: 0.14)
                      : (isDark
                          ? AppColors.primaryLight30
                          : AppColors.borderLight),
                ),
              ),
              child: Icon(
                Icons.calendar_today,
                color: colorScheme.onSurface.withValues(alpha: 0.68),
                size: 20,
              ),
            ),
            title: Text(
              formatDate(diaId),
              style: AppTextStyles.bodyMedium.copyWith(
                color: (_isAbsentDay && justificativa != null)
                    ? _absentColor
                    : colorScheme.onSurface.withValues(alpha: 0.68),
                fontWeight: (_isAbsentDay && justificativa != null)
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
            subtitle: disabled
                ? null
                : Text(
                    _subtitleText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _hasHighlight
                          ? _absentColor.withValues(alpha: 0.7)
                          : colorScheme.onSurface.withValues(alpha: 0.60),
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

          // Chip de abono (separado da justificativa)
          if (_isAbsentDay && abono != null) _buildAbonoChip(context),

          // Chip de justificativa de falta
          if (_isAbsentDay && justificativa != null)
            _buildJustificativaChip(context),

          // Admin: adicionar justificativa de falta quando não há nenhuma
          if (_isAbsentDay &&
              isAdmin &&
              justificativa == null &&
              onJustify != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: InkWell(
                onTap: onJustify,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

          // Admin: aplicar abono quando ainda não há nenhum
          if (_isAbsentDay && isAdmin && abono == null && onApplyAbono != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: InkWell(
                onTap: onApplyAbono,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_outlined,
                          size: 13, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        'Aplicar abono',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.warning,
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

    if (onOpenDayActions != null) {
      return IconButton(
        constraints: const BoxConstraints(),
        style: IconButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
        ),
        padding: EdgeInsets.zero,
        onPressed: onOpenDayActions,
        icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
        tooltip: 'Ações do dia',
      );
    }

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

  Widget _buildAbonoChip(BuildContext context) {
    final status = abono!.status;
    Color chipColor;
    IconData chipIcon;
    String chipLabel;

    switch (status) {
      case AbonoStatus.approved:
        chipColor = AppColors.success;
        chipIcon = Icons.verified_outlined;
        if (abono!.isFullDay) {
          chipLabel = 'Abono dia inteiro';
        } else if (abono!.abonoMinutes > 0) {
          final h = abono!.abonoMinutes ~/ 60;
          final m = abono!.abonoMinutes % 60;
          chipLabel = h > 0 && m > 0
              ? '${h}h ${m}min abonados'
              : h > 0
                  ? '${h}h abonados'
                  : '${m}min abonados';
        } else {
          chipLabel = 'Abono aprovado';
        }
        break;
      case AbonoStatus.pending:
        chipColor = AppColors.warning;
        chipIcon = Icons.hourglass_empty;
        chipLabel = 'Abono pendente de aprovação';
        break;
      case AbonoStatus.rejected:
        chipColor = AppColors.error;
        chipIcon = Icons.cancel_outlined;
        chipLabel = 'Abono recusado';
        break;
    }

    void confirmDelete() {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remover abono'),
          content: const Text(
              'Tem certeza que deseja remover este abono? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDeleteAbono?.call();
              },
              child: const Text(
                'Remover',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
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
                if (onDeleteAbono != null ||
                    (isAdmin && onApplyAbono != null)) ...[
                  const Spacer(),
                  if (onDeleteAbono != null)
                    GestureDetector(
                      onTap: confirmDelete,
                      child: const Icon(Icons.delete_outline,
                          size: 13, color: AppColors.error),
                    ),
                ],
              ],
            ),
            if (abono!.observacao.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                abono!.observacao,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (status == AbonoStatus.rejected &&
                abono!.rejectionReason != null &&
                abono!.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                'Motivo: ${abono!.rejectionReason}',
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
    );
  }

  Widget _buildJustificativaChip(BuildContext context) {
    final status = justificativa!.status;
    Color chipColor;
    IconData chipIcon;
    String chipLabel;

    switch (status) {
      case JustificativaStatus.approved:
        chipColor =
            _isFullDayAbonoApproved ? AppColors.warning : AppColors.success;
        chipIcon = Icons.check_circle_outline;
        chipLabel = _isFullDayAbonoApproved
            ? 'Abono justificado'
            : 'Justificativa aprovada';
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

    void confirmDelete() {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Remover justificativa'),
          content:
              const Text('Tem certeza que deseja remover esta justificativa?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                onDeleteJustificativa?.call();
              },
              child: const Text(
                'Remover',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: InkWell(
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
                  if (onDeleteJustificativa != null ||
                      (isAdmin && onJustify != null)) ...[
                    const Spacer(),
                    if (isAdmin && onJustify != null)
                      Icon(Icons.edit_outlined,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.68)),
                    if (onDeleteJustificativa != null) ...[
                      if (isAdmin && onJustify != null)
                        const SizedBox(width: 6),
                      GestureDetector(
                        onTap: confirmDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 13, color: AppColors.error),
                      ),
                    ],
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                justificativa!.justificativa,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.68),
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
