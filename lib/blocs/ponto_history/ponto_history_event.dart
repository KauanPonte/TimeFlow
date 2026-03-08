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
