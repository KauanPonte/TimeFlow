import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  final _tipos = ['entrada', 'pausa', 'retorno', 'saida'];

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.access_time, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(widget.title, style: AppTextStyles.h3),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tipo
          DropdownButtonFormField<String>(
            value: _tipo,
            decoration: InputDecoration(
              labelText: 'Tipo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.textSecondary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            items: _tipos
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(_labelForTipo(t)),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _tipo = v);
            },
          ),
          const SizedBox(height: 16),

          // Data
          InkWell(
            onTap: widget.fixedDate != null ? null : _pickDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textSecondary),
                borderRadius: BorderRadius.circular(12),
                color: widget.fixedDate != null
                    ? AppColors.textSecondary.withValues(alpha: 0.2)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd/MM/yyyy').format(_date),
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Hora
          InkWell(
            onTap: _pickTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textSecondary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
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
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
