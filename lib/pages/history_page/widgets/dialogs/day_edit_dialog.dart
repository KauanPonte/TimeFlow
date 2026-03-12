import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/day_edit_models.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/pages/history_page/widgets/dialogs/widgets/solicitation_helpers.dart';
import 'package:flutter_application_appdeponto/pages/history_page/widgets/dialogs/widgets/pending_event_row.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/services/ponto_validator.dart';
import 'package:intl/intl.dart';
import 'widgets/batch_edit_result.dart';
import 'widgets/day_edit_actions.dart';
import 'widgets/day_edit_header.dart';
import 'widgets/existing_event_row.dart';
import 'widgets/new_entry_row.dart';
import 'widgets/observacao_field.dart';
import 'widgets/validation_error_banner.dart';

export 'widgets/batch_edit_result.dart';

/// Modo de operação do diálogo unificado de edição de dia.
enum DayEditMode {
  /// Modo admin — edição direta dos pontos com validação.
  adminEdit,

  /// Modo funcionário — solicitação de alteração com observação.
  solicitation,
}

/// Diálogo unificado para editar pontos de um dia.
///
/// No modo [DayEditMode.adminEdit], retorna [BatchEditResult].
/// No modo [DayEditMode.solicitation], retorna `Map<String, dynamic>`
/// com chaves `items` (`List<SolicitationItem>`) e `reason` (`String?`).
class DayEditDialog extends StatefulWidget {
  final DayEditMode mode;
  final String diaId;
  final List<Map<String, dynamic>> eventos;

  const DayEditDialog({
    super.key,
    required this.mode,
    required this.diaId,
    required this.eventos,
  });

  @override
  State<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends State<DayEditDialog> {
  /// Eventos reais existentes (editáveis).
  late List<EventoEditState> _existing;

  /// Eventos pendentes (somente leitura — apenas para solicitation).
  late List<Map<String, dynamic>> _pendingEventos;

  /// Novos eventos a serem adicionados.
  final List<NewEntryState> _newEntries = [];

  /// Mensagem de erro de validação (apenas adminEdit).
  String? _validationError;

  /// Observação (apenas solicitation).
  final _reasonController = TextEditingController();

  bool get _isSolicitation => widget.mode == DayEditMode.solicitation;

  @override
  void initState() {
    super.initState();

    final realEventos =
        widget.eventos.where((e) => e['pending'] != true).toList();
    _pendingEventos =
        widget.eventos.where((e) => e['pending'] == true).toList();

    _existing = realEventos.map((ev) {
      final at = ev['at'] as DateTime?;
      return EventoEditState(
        id: ev['id'] as String?,
        tipo: (ev['tipo'] ?? 'entrada').toString(),
        time: at != null
            ? TimeOfDay(hour: at.hour, minute: at.minute)
            : TimeOfDay.now(),
        originalTipo: (ev['tipo'] ?? 'entrada').toString(),
        originalTime: at != null
            ? TimeOfDay(hour: at.hour, minute: at.minute)
            : TimeOfDay.now(),
        originalAt: at,
      );
    }).toList();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  // Helpers

  DateTime _dateForDay() => DateTime.parse(widget.diaId);

  DateTime _toDateTime(TimeOfDay t) {
    final d = _dateForDay();
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool get _hasChanges {
    if (_newEntries.isNotEmpty) return true;
    return _existing.any((e) =>
        e.mode == RowMode.deleting ||
        (e.mode == RowMode.editing && e.hasChanged));
  }

  // Pick time

  Future<void> _pickTimeForExisting(EventoEditState ev) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: ev.time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _validationError = null;
        ev.time = picked;
      });
    }
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
    if (picked != null) {
      setState(() {
        _validationError = null;
        _newEntries[index].time = picked;
      });
    }
  }

  // Add new entry

  void _addNewEntry() {
    final visible = [
      for (final e in _existing)
        if (e.mode != RowMode.deleting) MapEntry(e.tipo, e.time),
      for (final n in _newEntries) MapEntry(n.tipo, n.time),
    ];
    final suggestion = suggestNextEntry(visible);
    setState(() {
      _validationError = null;
      _newEntries
          .add(NewEntryState(tipo: suggestion.tipo, time: suggestion.time));
    });
  }

  // Save

  void _onSave() {
    if (_isSolicitation) {
      _submitSolicitation();
    } else {
      _submitAdminEdit();
    }
  }

  void _submitAdminEdit() {
    // Validação da sequência final
    final finalEventos = <Map<String, dynamic>>[];
    for (final ev in _existing) {
      if (ev.mode == RowMode.deleting) continue;
      finalEventos.add({
        if (ev.id != null) 'id': ev.id,
        'tipo': ev.tipo,
        'at': _toDateTime(ev.time),
      });
    }
    for (final n in _newEntries) {
      finalEventos.add({'tipo': n.tipo, 'at': _toDateTime(n.time)});
    }

    if (finalEventos.isNotEmpty) {
      final error = PontoValidator.validarSequenciaCompleta(finalEventos);
      if (error != null) {
        setState(() => _validationError = error);
        return;
      }
    }

    final updates = <Map<String, dynamic>>[];
    final deletes = <String>[];
    final adds = <Map<String, dynamic>>[];

    for (final ev in _existing) {
      if (ev.mode == RowMode.deleting) {
        if (ev.id != null) deletes.add(ev.id!);
      } else if (ev.mode == RowMode.editing && ev.id != null && ev.hasChanged) {
        updates.add({
          'id': ev.id,
          'tipo': ev.tipo,
          'horario': _toDateTime(ev.time),
        });
      }
    }
    for (final n in _newEntries) {
      adds.add({'tipo': n.tipo, 'horario': _toDateTime(n.time)});
    }

    Navigator.pop(
      context,
      BatchEditResult(updates: updates, deletes: deletes, adds: adds),
    );
  }

  void _submitSolicitation() {
    if (!_hasChanges) return;
    final date = _dateForDay();
    final items = <SolicitationItem>[];

    for (final ev in _existing) {
      if (ev.id == null) continue;
      if (ev.mode == RowMode.editing && ev.hasChanged) {
        final newDt = _toDateTime(ev.time);
        items.add(SolicitationItem(
          eventoId: ev.id,
          action: SolicitationAction.edit,
          tipo: ev.tipo,
          horario: newDt,
          oldTipo: ev.originalTipo,
          oldHorario: ev.originalAt,
        ));
      } else if (ev.mode == RowMode.deleting) {
        items.add(SolicitationItem(
          eventoId: ev.id,
          action: SolicitationAction.delete,
          tipo: ev.originalTipo ?? ev.tipo,
          horario: ev.originalAt ?? date,
          oldTipo: ev.originalTipo,
          oldHorario: ev.originalAt,
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

  // Build

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.diaId);
    final dateStr = date != null
        ? DateFormat("EEEE, dd 'de' MMMM", 'pt_BR').format(date)
        : widget.diaId;
    final formattedDate = dateStr.isNotEmpty
        ? dateStr[0].toUpperCase() + dateStr.substring(1)
        : dateStr;

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
              DayEditHeader(
                formattedDate: formattedDate,
                title: _isSolicitation ? 'Solicitar Alteração' : 'Editar Dia',
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_existing.isNotEmpty) ...[
                      const SolicitationSectionLabel(
                        'Registros existentes',
                        subtitle: 'Toque em ✏ para editar ou 🗑 para remover',
                      ),
                      const SizedBox(height: 6),
                      ..._existing.map(_buildExistingRow),
                      const SizedBox(height: 4),
                    ],
                    if (_isSolicitation && _pendingEventos.isNotEmpty) ...[
                      const SolicitationSectionLabel('Solicitações pendentes'),
                      const SizedBox(height: 6),
                      ..._pendingEventos.map((ev) => PendingEventRow(ev: ev)),
                      const SizedBox(height: 4),
                    ],
                    const Divider(height: 24),
                    const SolicitationSectionLabel('Adicionar novos registros'),
                    const SizedBox(height: 8),
                    ..._newEntries.asMap().entries.map(
                          (e) => _buildNewEntryRow(e.key, e.value),
                        ),
                    Center(
                      child: TextButton.icon(
                        onPressed: _addNewEntry,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Adicionar registro'),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary),
                      ),
                    ),
                    if (_validationError != null)
                      ValidationErrorBanner(message: _validationError!),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (_isSolicitation)
                ObservacaoField(controller: _reasonController),
              const SizedBox(height: 16),
              DayEditActions(
                hasChanges: _hasChanges,
                onCancel: () => Navigator.pop(context),
                onSave: _onSave,
                saveLabel: _isSolicitation
                    ? 'Enviar Solicitação'
                    : 'Salvar alterações',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExistingRow(EventoEditState ev) {
    return ExistingEventRow(
      key: ValueKey(ev.id ?? ev.hashCode),
      ev: ev,
      showOldValues: _isSolicitation,
      onEdit: () => setState(() {
        _validationError = null;
        ev.mode = RowMode.editing;
      }),
      onDelete: () => setState(() {
        _validationError = null;
        ev.mode = RowMode.deleting;
      }),
      onUndo: () => setState(() {
        _validationError = null;
        ev.tipo = ev.originalTipo ?? ev.tipo;
        ev.time = ev.originalTime ?? ev.time;
        ev.mode = RowMode.normal;
      }),
      onPickTime: () => _pickTimeForExisting(ev),
      onTipoChanged: (v) => setState(() {
        _validationError = null;
        ev.tipo = v;
      }),
    );
  }

  Widget _buildNewEntryRow(int index, NewEntryState entry) {
    return NewEntryRow(
      key: ValueKey('new_$index'),
      entry: entry,
      onPickTime: () => _pickTimeForNew(index),
      onTipoChanged: (v) => setState(() {
        _validationError = null;
        entry.tipo = v;
      }),
      onRemove: () => setState(() {
        _validationError = null;
        _newEntries.removeAt(index);
      }),
    );
  }
}
