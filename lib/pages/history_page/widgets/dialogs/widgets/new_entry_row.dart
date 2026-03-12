import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'solicitation_helpers.dart';
import '../../../../../models/day_edit_models.dart';

class NewEntryRow extends StatelessWidget {
  static const _tipos = ['entrada', 'pausa', 'retorno', 'saida'];

  final NewEntryState entry;
  final VoidCallback onPickTime;
  final ValueChanged<String> onTipoChanged;
  final VoidCallback onRemove;

  const NewEntryRow({
    super.key,
    required this.entry,
    required this.onPickTime,
    required this.onTipoChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = colorForTipo(entry.tipo);
    final timeStr =
        '${entry.time.hour.toString().padLeft(2, '0')}:${entry.time.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11,
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: entry.tipo,
                isDense: true,
                items: _tipos.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconForTipo(t), size: 15, color: colorForTipo(t)),
                        const SizedBox(width: 6),
                        Text(labelForTipo(t), style: AppTextStyles.bodySmall),
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
          InkWell(
            onTap: onPickTime,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 16),
            color: AppColors.error,
            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
