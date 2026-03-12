import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'solicitation_helpers.dart';
import '../../../../../models/day_edit_models.dart';
import 'undo_btn.dart';

class ExistingEventRow extends StatelessWidget {
  static const _tipos = ['entrada', 'pausa', 'retorno', 'saida'];

  final EventoEditState ev;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUndo;
  final VoidCallback onPickTime;
  final ValueChanged<String> onTipoChanged;

  /// Quando `true`, exibe os valores originais (antes) na linha de edição.
  final bool showOldValues;

  const ExistingEventRow({
    super.key,
    required this.ev,
    required this.onEdit,
    required this.onDelete,
    required this.onUndo,
    required this.onPickTime,
    required this.onTipoChanged,
    this.showOldValues = false,
  });

  @override
  Widget build(BuildContext context) {
    switch (ev.mode) {
      case RowMode.deleting:
        return _buildDeletedRow();
      case RowMode.editing:
        return _buildEditingRow();
      case RowMode.normal:
        return _buildNormalRow();
    }
  }

  Widget _buildNormalRow() {
    final color = colorForTipo(ev.tipo);
    final hora = ev.originalAt != null
        ? DateFormat('HH:mm').format(ev.originalAt!)
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Icon(iconForTipo(ev.tipo), size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${labelForTipo(ev.tipo)} — $hora',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (ev.id != null) ...[
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 16),
              color: AppColors.primary,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 16),
              color: AppColors.error,
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero,
              tooltip: 'Remover',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeletedRow() {
    final hora = ev.originalAt != null
        ? DateFormat('HH:mm').format(ev.originalAt!)
        : '--:--';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(iconForTipo(ev.originalTipo ?? ev.tipo),
              size: 15, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${labelForTipo(ev.originalTipo ?? ev.tipo)} — $hora',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error.withValues(alpha: 0.6),
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Remover',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 10,
                color: AppColors.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          UndoBtn(onTap: onUndo),
        ],
      ),
    );
  }

  Widget _buildEditingRow() {
    final editColor = colorForTipo(ev.tipo);
    final timeStr =
        '${ev.time.hour.toString().padLeft(2, '0')}:${ev.time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: editColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: editColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Editando',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 9,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (showOldValues &&
                  ev.originalTipo != null &&
                  ev.originalAt != null) ...[
                const SizedBox(width: 6),
                Text(
                  'antes: ${labelForTipo(ev.originalTipo!)} ${DateFormat('HH:mm').format(ev.originalAt!)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
              const Spacer(),
              UndoBtn(onTap: onUndo),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: ev.tipo,
                    isDense: true,
                    items: _tipos.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconForTipo(t),
                                size: 15, color: colorForTipo(t)),
                            const SizedBox(width: 6),
                            Text(labelForTipo(t),
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) onTipoChanged(v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onPickTime,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: editColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 13, color: editColor),
                      const SizedBox(width: 4),
                      Text(
                        timeStr,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: editColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
