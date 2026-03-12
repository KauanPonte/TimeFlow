import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/widgets/time_picker.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class EventoDialog extends StatefulWidget {
  final String? initialTipo;
  final DateTime? initialHorario;
  final DateTime? fixedDate;
  final String title;

  const EventoDialog({
    super.key,
    this.initialTipo,
    this.initialHorario,
    this.fixedDate,
    required this.title,
  });

  @override
  State<EventoDialog> createState() => _EventoDialogState();
}

class _EventoDialogState extends State<EventoDialog> {
  late String _tipo;
  late DateTime _date;
  late TimeOfDay _time;

  static const _tipos = ['entrada', 'pausa', 'retorno', 'saida'];

  @override
  void initState() {
    super.initState();
    _tipo = widget.initialTipo ?? 'entrada';
    final dt = widget.initialHorario ?? DateTime.now();
    _date = widget.fixedDate ?? DateTime(dt.year, dt.month, dt.day);
    _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
  }

  String _labelForTipo(String tipo) {
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

  IconData _iconForTipo(String tipo) {
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

  Color _colorForTipo(String tipo) {
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker24h(context, _time);
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = _colorForTipo(_tipo);
    final timeStr =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    final dateStr = DateFormat("EEE, dd 'de' MMM", 'pt_BR').format(_date);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                const Icon(Icons.edit_calendar_rounded,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.title, style: AppTextStyles.h3),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Data
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    dateStr[0].toUpperCase() + dateStr.substring(1),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Seletor de tipo
            Text(
              'Tipo de registro',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _tipos.map((t) {
                final isSelected = _tipo == t;
                final color = _colorForTipo(t);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _tipo = t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.12)
                              : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? color : AppColors.borderLight,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _iconForTipo(t),
                              size: 18,
                              color:
                                  isSelected ? color : AppColors.textSecondary,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _labelForTipo(t),
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: isSelected
                                    ? color
                                    : AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Seletor de hora
            Text(
              'Horário',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: selectedColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: selectedColor.withValues(alpha: 0.4), width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        color: selectedColor, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      timeStr,
                      style: AppTextStyles.h2.copyWith(
                        color: selectedColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.expand_more_rounded,
                        color: selectedColor.withValues(alpha: 0.6), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Ações
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: AppColors.borderLight),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final dt = DateTime(
                        _date.year,
                        _date.month,
                        _date.day,
                        _time.hour,
                        _time.minute,
                      );
                      final diaId = DateFormat('yyyy-MM-dd').format(_date);
                      Navigator.pop(context, {
                        'tipo': _tipo,
                        'horario': dt,
                        'diaId': diaId,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Salvar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
