import 'package:flutter/material.dart';
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

  const EmptyDayCard({
    super.key,
    required this.diaId,
    this.disabled = false,
    this.isAdmin = false,
    this.onAddEvento,
    this.onBatchEdit,
    this.onRequestSolicitation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: disabled ? AppColors.bgLight : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled
              ? AppColors.borderLight.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.borderLight.withValues(alpha: 0.3)
                : AppColors.borderLight.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.calendar_today,
            color: disabled ? AppColors.borderLight : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          formatDate(diaId),
          style: AppTextStyles.bodyMedium.copyWith(
            color: disabled ? AppColors.borderLight : AppColors.textSecondary,
          ),
        ),
        subtitle: disabled
            ? null
            : Text(
                'Sem registros',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
        trailing: (!disabled && isAdmin && onBatchEdit != null)
            ? IconButton(
                constraints: const BoxConstraints(),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  minimumSize: Size.zero,
                  padding: EdgeInsets.zero,
                ),
                padding: EdgeInsets.zero,
                onPressed: onBatchEdit,
                icon: const Icon(Icons.edit_note_rounded,
                    color: AppColors.primary),
                tooltip: 'Editar dia',
              )
            : (!disabled && isAdmin && onAddEvento != null)
                ? IconButton(
                    constraints: const BoxConstraints(),
                    style: IconButton.styleFrom(
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                      padding: EdgeInsets.zero,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onAddEvento,
                    icon: const Icon(Icons.add_circle_outline,
                        color: AppColors.primary),
                    tooltip: 'Adicionar ponto',
                  )
                : (!disabled && onRequestSolicitation != null)
                    ? IconButton(
                        constraints: const BoxConstraints(),
                        style: IconButton.styleFrom(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onRequestSolicitation,
                        icon: const Icon(Icons.edit_note_rounded,
                            color: AppColors.primary),
                        tooltip: 'Solicitar alteração',
                      )
                    : null,
      ),
    );
  }
}
