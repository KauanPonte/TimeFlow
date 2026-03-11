import 'package:equatable/equatable.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';

abstract class SolicitationState extends Equatable {
  const SolicitationState();
  @override
  List<Object?> get props => [];
}

class SolicitationInitial extends SolicitationState {
  const SolicitationInitial();
}

class SolicitationLoading extends SolicitationState {
  const SolicitationLoading();
}

class SolicitationLoaded extends SolicitationState {
  final List<SolicitationModel> solicitations;

  /// Solicitações recentemente revisadas (aprovadas/rejeitadas) do funcionário.
  /// Vazio para admin (admin não precisa ver suas próprias revisões aqui).
  final List<SolicitationModel> reviewedSolicitations;
  final bool isAdmin;

  const SolicitationLoaded({
    required this.solicitations,
    this.reviewedSolicitations = const [],
    this.isAdmin = false,
  });

  int get pendingCount =>
      solicitations.where((s) => s.status == SolicitationStatus.pending).length;

  @override
  List<Object?> get props => [solicitations, reviewedSolicitations, isAdmin];
}

class SolicitationActionProcessing extends SolicitationState {
  final String message;
  final List<SolicitationModel> solicitations;

  const SolicitationActionProcessing({
    required this.message,
    required this.solicitations,
  });

  @override
  List<Object?> get props => [message, solicitations];
}

class SolicitationActionSuccess extends SolicitationState {
  final String message;
  final List<SolicitationModel> solicitations;

  /// Revisadas visíveis (já filtradas pelas dispensadas).
  final List<SolicitationModel> reviewedSolicitations;
  final DateTime timestamp;

  SolicitationActionSuccess({
    required this.message,
    required this.solicitations,
    this.reviewedSolicitations = const [],
  }) : timestamp = DateTime.now();

  @override
  List<Object?> get props =>
      [message, solicitations, reviewedSolicitations, timestamp];
}

class SolicitationError extends SolicitationState {
  final String message;
  final List<SolicitationModel> solicitations;

  const SolicitationError({
    required this.message,
    this.solicitations = const [],
  });

  @override
  List<Object?> get props => [message, solicitations];
}
