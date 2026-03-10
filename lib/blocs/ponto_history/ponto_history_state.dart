import 'package:equatable/equatable.dart';

abstract class PontoHistoryState extends Equatable {
  const PontoHistoryState();

  @override
  List<Object?> get props => [];
}

class PontoHistoryInitial extends PontoHistoryState {
  const PontoHistoryInitial();
}

class PontoHistoryLoading extends PontoHistoryState {
  const PontoHistoryLoading();
}

/// Estado emitido enquanto uma ação (add/edit/delete) está em andamento.
class PontoHistoryActionProcessing extends PontoHistoryState {
  final String message;
  final Map<String, List<Map<String, dynamic>>> daysMap;

  const PontoHistoryActionProcessing({
    required this.message,
    required this.daysMap,
  });

  @override
  List<Object?> get props => [message, daysMap];
}

class PontoHistoryLoaded extends PontoHistoryState {
  /// Mapa de diaId → eventos: [{ id, tipo, at }]
  final Map<String, List<Map<String, dynamic>>> daysMap;

  const PontoHistoryLoaded({required this.daysMap});

  @override
  List<Object?> get props => [daysMap];
}

class PontoHistoryActionSuccess extends PontoHistoryState {
  final String message;
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final DateTime timestamp;

  PontoHistoryActionSuccess({
    required this.message,
    required this.daysMap,
  }) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [message, daysMap, timestamp];
}

class PontoHistoryError extends PontoHistoryState {
  final String message;

  const PontoHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

class PontoHistoryActionError extends PontoHistoryState {
  final String message;
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final DateTime timestamp;

  PontoHistoryActionError({
    required this.message,
    required this.daysMap,
  }) : timestamp = DateTime.now();

  @override
  List<Object?> get props => [message, daysMap, timestamp];
}
