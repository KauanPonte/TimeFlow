import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';

/// Representa uma modificação (editar ou remover) sobre um evento existente.
class EventoModification {
  final String eventoId;
  final String oldTipo;
  final DateTime oldHorario;
  final SolicitationAction action;
  String newTipo;
  TimeOfDay newTime;

  EventoModification({
    required this.eventoId,
    required this.oldTipo,
    required this.oldHorario,
    required this.action,
    required this.newTipo,
    required this.newTime,
  });
}

/// Representa um novo registro a adicionar.
class NewEntry {
  String tipo;
  TimeOfDay time;

  NewEntry({required this.tipo, required this.time});
}
