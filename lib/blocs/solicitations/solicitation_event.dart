import 'package:equatable/equatable.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';

abstract class SolicitationEvent extends Equatable {
  const SolicitationEvent();
  @override
  List<Object?> get props => [];
}

/// Carrega solicitações pendentes (funcionário: apenas as suas; admin: todas).
class LoadSolicitationsEvent extends SolicitationEvent {
  final bool isAdmin;
  const LoadSolicitationsEvent({this.isAdmin = false});
  @override
  List<Object?> get props => [isAdmin];
}

/// Funcionário: cria nova solicitação de alteração de ponto.
class CreateSolicitationEvent extends SolicitationEvent {
  final String diaId;
  final List<SolicitationItem> items;
  final String? reason;

  const CreateSolicitationEvent({
    required this.diaId,
    required this.items,
    this.reason,
  });

  @override
  List<Object?> get props => [diaId, items, reason];
}

/// Funcionário: atualiza uma solicitação pendente (cancela a atual e cria nova).
class UpdateSolicitationEvent extends SolicitationEvent {
  final String existingSolicitationId;
  final String diaId;
  final List<SolicitationItem> items;
  final String? reason;

  const UpdateSolicitationEvent({
    required this.existingSolicitationId,
    required this.diaId,
    required this.items,
    this.reason,
  });

  @override
  List<Object?> get props => [existingSolicitationId, diaId, items, reason];
}

/// Funcionário: cancela uma solicitação pendente.
class CancelSolicitationEvent extends SolicitationEvent {
  final String solicitationId;
  const CancelSolicitationEvent({required this.solicitationId});
  @override
  List<Object?> get props => [solicitationId];
}

/// Admin: processa uma solicitação (aceitar/rejeitar itens individuais).
class ProcessSolicitationEvent extends SolicitationEvent {
  final String solicitationId;
  final List<SolicitationItemStatus> itemStatuses;
  final String? reason;

  const ProcessSolicitationEvent({
    required this.solicitationId,
    required this.itemStatuses,
    this.reason,
  });

  @override
  List<Object?> get props => [solicitationId, itemStatuses, reason];
}

/// Reload silencioso (sem loading indicator).
class SilentReloadSolicitationsEvent extends SolicitationEvent {
  final bool isAdmin;
  const SilentReloadSolicitationsEvent({this.isAdmin = false});
  @override
  List<Object?> get props => [isAdmin];
}

/// Reset no logout.
class ResetSolicitationsEvent extends SolicitationEvent {
  const ResetSolicitationsEvent();
}

/// Funcionário: marca uma notificação de resultado como vista.
class DismissReviewedSolicitationEvent extends SolicitationEvent {
  final String solicitationId;
  const DismissReviewedSolicitationEvent({required this.solicitationId});
  @override
  List<Object?> get props => [solicitationId];
}
