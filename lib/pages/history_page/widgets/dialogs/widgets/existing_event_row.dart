import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/models/solicitation_request_models.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'solicitation_helpers.dart';

const _tipos = ['entrada', 'pausa', 'retorno', 'saida'];

/// Linha de um evento existente no diálogo de solicitação.
/// Pode estar em estado normal, edição ou marcado para remoção.
class ExistingEventRow extends StatelessWidget {
  final Map<String, dynamic> ev;
  final EventoModification? modification;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUndo;
  final VoidCallback onPickTime;
  final ValueChanged<String> onChangeTipo;

  const ExistingEventRow({
    super.key,
    required this.ev,
    required this.modification,
    required this.onEdit,
    required this.onDelete,
    required this.onUndo,
    required this.onPickTime,
    required this.onChangeTipo,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = (ev['tipo'] ?? 'entrada').toString();
    final at = ev['at'] as DateTime?;

    //  Marcado para remoção
    if (modification?.action == SolicitationAction.delete) {
      return _DeletedRow(tipo: tipo, at: at, onUndo: onUndo);
    }

    //  Em modo edição
    if (modification?.action == SolicitationAction.edit) {
      return _EditRow(
        mod: modification!,
        onUndo: onUndo,
        onPickTime: onPickTime,
        onChangeTipo: onChangeTipo,
      );
    }

    //  Normal
    final color = colorForTipo(tipo);
    final hora = at != null ? DateFormat('HH:mm').format(at) : '--:--';
    final eventoId = ev['id'] as String?;

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
          Icon(iconForTipo(tipo), size: 15, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${labelForTipo(tipo)} — $hora',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
          if (eventoId != null) ...[
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
}

//  Sub-widgets privados

class _DeletedRow extends StatelessWidget {
  final String tipo;
  final DateTime? at;
  final VoidCallback onUndo;

  const _DeletedRow(
      {required this.tipo, required this.at, required this.onUndo});

  @override
  Widget build(BuildContext context) {
    final hora = at != null ? DateFormat('HH:mm').format(at!) : '--:--';
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
          Icon(iconForTipo(tipo),
              size: 15, color: AppColors.error.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${labelForTipo(tipo)} — $hora',
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
          _UndoBtn(onTap: onUndo),
        ],
      ),
    );
  }
}

class _EditRow extends StatelessWidget {
  final EventoModification mod;
  final VoidCallback onUndo;
  final VoidCallback onPickTime;
  final ValueChanged<String> onChangeTipo;

  const _EditRow({
    required this.mod,
    required this.onUndo,
    required this.onPickTime,
    required this.onChangeTipo,
  });

  @override
  Widget build(BuildContext context) {
    final editColor = colorForTipo(mod.newTipo);
    final timeStr =
        '${mod.newTime.hour.toString().padLeft(2, '0')}:${mod.newTime.minute.toString().padLeft(2, '0')}';

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
              const SizedBox(width: 6),
              Text(
                'antes: ${labelForTipo(mod.oldTipo)} ${DateFormat('HH:mm').format(mod.oldHorario)}',
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const Spacer(),
              _UndoBtn(onTap: onUndo),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: mod.newTipo,
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
                      if (v != null) onChangeTipo(v);
                    },
                  ),
                ),
              ),
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

class _UndoBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _UndoBtn({required this.onTap});

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
