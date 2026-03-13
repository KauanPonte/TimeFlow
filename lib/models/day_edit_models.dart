import 'package:flutter/material.dart';

enum RowMode { normal, editing, deleting }

/// Estado mutável de um evento existente sendo editado.
class EventoEditState {
  final String? id;
  String tipo;
  TimeOfDay time;
  final String? originalTipo;
  final TimeOfDay? originalTime;
  final DateTime? originalAt;
  RowMode mode;

  EventoEditState({
    this.id,
    required this.tipo,
    required this.time,
    this.originalTipo,
    this.originalTime,
    this.originalAt,
    this.mode = RowMode.normal,
  });

  bool get hasChanged {
    if (originalTipo == null || originalTime == null) return true;
    return tipo != originalTipo ||
        time.hour != originalTime!.hour ||
        time.minute != originalTime!.minute;
  }
}

/// Estado mutável de um novo evento a ser adicionado.
class NewEntryState {
  String tipo;
  TimeOfDay time;

  NewEntryState({required this.tipo, required this.time});
}
