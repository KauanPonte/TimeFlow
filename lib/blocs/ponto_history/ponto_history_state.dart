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

  const PontoHistoryActionSuccess({
    required this.message,
    required this.daysMap,
  });

  @override
  List<Object?> get props => [message, daysMap];
}

class PontoHistoryError extends PontoHistoryState {
  final String message;

  const PontoHistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}
