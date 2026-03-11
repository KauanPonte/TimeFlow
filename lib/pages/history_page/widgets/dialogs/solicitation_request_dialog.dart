import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_request_models.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'widgets/solicitation_helpers.dart';
import 'widgets/existing_event_row.dart';
import 'widgets/new_entry_row.dart';
import 'widgets/pending_event_row.dart';

/// Dialog para o funcionário solicitar alterações de ponto em um dia.
/// Suporta ADICIONAR novos registros, EDITAR e REMOVER registros existentes.
class SolicitationRequestDialog extends StatefulWidget {
  final String diaId;

  /// Eventos existentes no dia (reais + pendentes virtuais).
  final List<Map<String, dynamic>> eventosExistentes;

  const SolicitationRequestDialog({
    super.key,
    required this.diaId,
    required this.eventosExistentes,
  });

  @override
  State<SolicitationRequestDialog> createState() =>
      _SolicitationRequestDialogState();
}

class _SolicitationRequestDialogState extends State<SolicitationRequestDialog> {
  /// Modificações (editar/remover) de eventos existentes, indexadas por eventoId.
  final Map<String, EventoModification> _modifications = {};

  /// Novos registros a adicionar.
  final List<NewEntry> _newEntries = [];

  final _reasonController = TextEditingController();

  bool get _hasChanges => _modifications.isNotEmpty || _newEntries.isNotEmpty;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  //  Ações sobre eventos existentes

  void _startEdit(Map<String, dynamic> ev) {
    final eventoId = ev['id'] as String?;
    if (eventoId == null) return;
    final oldTipo = (ev['tipo'] ?? 'entrada').toString();
    final oldAt = ev['at'] as DateTime;
    setState(() {
      _modifications[eventoId] = EventoModification(
        eventoId: eventoId,
        oldTipo: oldTipo,
        oldHorario: oldAt,
        action: SolicitationAction.edit,
        newTipo: oldTipo,
        newTime: TimeOfDay(hour: oldAt.hour, minute: oldAt.minute),
      );
    });
  }

  void _startDelete(Map<String, dynamic> ev) {
    final eventoId = ev['id'] as String?;
    if (eventoId == null) return;
    final oldTipo = (ev['tipo'] ?? 'entrada').toString();
    final oldAt = ev['at'] as DateTime;
    setState(() {
      _modifications[eventoId] = EventoModification(
        eventoId: eventoId,
        oldTipo: oldTipo,
        oldHorario: oldAt,
        action: SolicitationAction.delete,
        newTipo: oldTipo,
        newTime: TimeOfDay(hour: oldAt.hour, minute: oldAt.minute),
      );
    });
  }

  Future<void> _pickTimeForModification(String eventoId) async {
    final mod = _modifications[eventoId];
    if (mod == null) return;
    final picked = await showTimePicker(
      context: context,
      initialTime: mod.newTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => mod.newTime = picked);
  }

  //  Ações sobre novas entradas

  void _addNewEntry() {
    setState(() =>
        _newEntries.add(NewEntry(tipo: 'entrada', time: TimeOfDay.now())));
  }

  void _removeNewEntry(int index) {
    setState(() => _newEntries.removeAt(index));
  }

  Future<void> _pickTimeForNew(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _newEntries[index].time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _newEntries[index].time = picked);
  }

  //  Submit

  void _submit() {
    if (!_hasChanges) return;
    final date = DateTime.parse(widget.diaId);
    final items = <SolicitationItem>[];

    for (final mod in _modifications.values) {
      if (mod.action == SolicitationAction.edit) {
        final newDt = DateTime(date.year, date.month, date.day,
            mod.newTime.hour, mod.newTime.minute);
        items.add(SolicitationItem(
          eventoId: mod.eventoId,
          action: SolicitationAction.edit,
          tipo: mod.newTipo,
          horario: newDt,
          oldTipo: mod.oldTipo,
          oldHorario: mod.oldHorario,
        ));
      } else if (mod.action == SolicitationAction.delete) {
        items.add(SolicitationItem(
          eventoId: mod.eventoId,
          action: SolicitationAction.delete,
          tipo: mod.oldTipo,
          horario: mod.oldHorario,
          oldTipo: mod.oldTipo,
          oldHorario: mod.oldHorario,
        ));
      }
    }

    for (final entry in _newEntries) {
      final dt = DateTime(
          date.year, date.month, date.day, entry.time.hour, entry.time.minute);
      items.add(SolicitationItem(
        action: SolicitationAction.add,
        tipo: entry.tipo,
        horario: dt,
      ));
    }

    Navigator.pop(context, {
      'items': items,
      'reason': _reasonController.text.trim().isEmpty
          ? null
          : _reasonController.text.trim(),
    });
  }

  //  Build

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.diaId);
    final dateStr = date != null
        ? DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(date)
        : widget.diaId;
    final formattedDate = dateStr.isNotEmpty
        ? dateStr[0].toUpperCase() + dateStr.substring(1)
        : dateStr;

    final realEventos =
        widget.eventosExistentes.where((e) => e['pending'] != true).toList();
    final pendingEventos =
        widget.eventosExistentes.where((e) => e['pending'] == true).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(formattedDate),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (realEventos.isNotEmpty) ...[
                      const SolicitationSectionLabel(
                        'Registros existentes',
                        subtitle: 'Toque em ✏ para editar ou 🗑 para remover',
                      ),
                      const SizedBox(height: 6),
                      ...realEventos.map((ev) => _buildExistingRow(ev)),
                      const SizedBox(height: 4),
                    ],
                    if (pendingEventos.isNotEmpty) ...[
                      const SolicitationSectionLabel('Solicitações pendentes'),
                      const SizedBox(height: 6),
                      ...pendingEventos.map((ev) => PendingEventRow(ev: ev)),
                      const SizedBox(height: 4),
                    ],
                    const Divider(height: 24),
                    const SolicitationSectionLabel('Adicionar novos registros'),
                    const SizedBox(height: 8),
                    ..._newEntries.asMap().entries.map((e) => NewEntryRow(
                          index: e.key,
                          entry: e.value,
                          onRemove: () => _removeNewEntry(e.key),
                          onPickTime: () => _pickTimeForNew(e.key),
                          onChangeTipo: (v) =>
                              setState(() => _newEntries[e.key].tipo = v),
                        )),
                    Center(
                      child: TextButton.icon(
                        onPressed: _addNewEntry,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Adicionar registro'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              _buildObservacao(),
              const SizedBox(height: 16),
              _buildActions(),
            ],
          ),
        ),
      ),
    );
  }

  //  Partes do build

  Widget _buildHeader(String formattedDate) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.edit_note_rounded,
              color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Solicitar Alteração', style: AppTextStyles.h3),
              Text(formattedDate,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingRow(Map<String, dynamic> ev) {
    final eventoId = ev['id'] as String?;
    return ExistingEventRow(
      ev: ev,
      modification: eventoId != null ? _modifications[eventoId] : null,
      onEdit: () => _startEdit(ev),
      onDelete: () => _startDelete(ev),
      onUndo: () => setState(() => _modifications.remove(eventoId)),
      onPickTime: () =>
          eventoId != null ? _pickTimeForModification(eventoId) : null,
      onChangeTipo: (v) =>
          setState(() => _modifications[eventoId!]!.newTipo = v),
    );
  }

  Widget _buildObservacao() {
    return TextField(
      controller: _reasonController,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Observação (opcional)',
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
      style: AppTextStyles.bodySmall,
    );
  }

  Widget _buildActions() {
    return Row(
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
            child: Text('Cancelar',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _hasChanges ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Enviar Solicitação'),
          ),
        ),
      ],
    );
  }
}
