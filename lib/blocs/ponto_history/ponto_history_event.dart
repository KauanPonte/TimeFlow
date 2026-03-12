import 'package:equatable/equatable.dart';

abstract class PontoHistoryEvent extends Equatable {
  const PontoHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega histórico de pontos. Se [uid] for null, usa o usuário logado.
/// [month] define o mês a carregar (ano e mês são usados).
class LoadHistoryEvent extends PontoHistoryEvent {
  final String? uid;
  final DateTime month;

  LoadHistoryEvent({this.uid, DateTime? month})
      : month = month ?? DateTime.now();

  @override
  List<Object?> get props => [uid, month.year, month.month];
}

/// Reseta o histórico para o estado inicial (logout).
class ResetHistoryEvent extends PontoHistoryEvent {
  const ResetHistoryEvent();
}

/// Admin adiciona um evento de ponto.
class AddEventoEvent extends PontoHistoryEvent {
  final String uid;
  final String diaId;
  final String tipo;
  final DateTime horario;

  const AddEventoEvent({
    required this.uid,
    required this.diaId,
    required this.tipo,
    required this.horario,
  });

  @override
  List<Object?> get props => [uid, diaId, tipo, horario];
}

/// Admin edita um evento de ponto.
class UpdateEventoEvent extends PontoHistoryEvent {
  final String uid;
  final String diaId;
  final String eventoId;
  final String tipo;
  final DateTime horario;

  const UpdateEventoEvent({
    required this.uid,
    required this.diaId,
    required this.eventoId,
    required this.tipo,
    required this.horario,
  });

  @override
  List<Object?> get props => [uid, diaId, eventoId, tipo, horario];
}

/// Recarrega o histórico silenciosamente (sem emitir PontoHistoryLoading),
/// mantendo os dados existentes visíveis durante o fetch.
class SilentReloadHistoryEvent extends PontoHistoryEvent {
  const SilentReloadHistoryEvent();
}

/// Admin remove um evento de ponto.
class DeleteEventoEvent extends PontoHistoryEvent {
  final String uid;
  final String diaId;
  final String eventoId;

  const DeleteEventoEvent({
    required this.uid,
    required this.diaId,
    required this.eventoId,
  });

  @override
  List<Object?> get props => [uid, diaId, eventoId];
}

/// Admin edita, adiciona e remove pontos de um dia em lote.
class BatchUpdateDayEvent extends PontoHistoryEvent {
  final String uid;
  final String diaId;
  final List<Map<String, dynamic>> updates;
  final List<String> deletes;
  final List<Map<String, dynamic>> adds;

  const BatchUpdateDayEvent({
    required this.uid,
    required this.diaId,
    required this.updates,
    required this.deletes,
    required this.adds,
  });

  @override
  List<Object?> get props => [uid, diaId, updates, deletes, adds];
}
