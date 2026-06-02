import 'package:equatable/equatable.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega lista de usuários cadastrados
class LoadUsersEvent extends UserManagementEvent {
  const LoadUsersEvent();
}

/// Carrega lista de solicitações pendentes
class LoadPendingRequestsEvent extends UserManagementEvent {
  const LoadPendingRequestsEvent();
}

/// Aprova uma solicitação de cadastro
class ApproveRequestEvent extends UserManagementEvent {
  final String requestId;
  final String userName;
  final String cargaHoraria;
  final String role;
  final String contractType;
  final List<String> workDays;
  final String projectType;
  final List<String> projects;
  final DateTime startDate;

  const ApproveRequestEvent({
    required this.requestId,
    required this.userName,
    required this.cargaHoraria,
    required this.role,
    required this.contractType,
    required this.workDays,
    required this.projectType,
    required this.projects,
    required this.startDate,
  });

  @override
  List<Object?> get props => [
        requestId,
        userName,
        cargaHoraria,
        role,
        contractType,
        workDays,
        projectType,
        projects,
        startDate,
      ];
}

/// Rejeita uma solicitação de cadastro
class RejectRequestEvent extends UserManagementEvent {
  final String requestId;
  final String userName;

  const RejectRequestEvent({
    required this.requestId,
    required this.userName,
  });

  @override
  List<Object?> get props => [requestId, userName];
}

/// Atualiza o cargo de um usuário
class UpdateUserRoleEvent extends UserManagementEvent {
  final String userId;
  final String userName;
  final String newRole;

  const UpdateUserRoleEvent({
    required this.userId,
    required this.userName,
    required this.newRole,
  });

  @override
  List<Object?> get props => [userId, userName, newRole];
}

// Editar a carga horária do usuário
class UpdateUserWorkloadEvent extends UserManagementEvent {
  final String userId;
  final String userName;
  final int workloadMinutes;

  const UpdateUserWorkloadEvent({
    required this.userId,
    required this.userName,
    required this.workloadMinutes,
  });

  @override
  List<Object> get props => [userId, userName, workloadMinutes];
}

/// Editar cargo e carga horária do usuário em uma única operação
class UpdateUserProfileEvent extends UserManagementEvent {
  final String userId;
  final String userName;
  final String newRole;
  final int workloadMinutes;
  final String contractType;
  final List<String> workDays;
  final String projectType;
  final List<String> projects;
  final DateTime? effectiveDate;

  const UpdateUserProfileEvent({
    required this.userId,
    required this.userName,
    required this.newRole,
    required this.workloadMinutes,
    required this.contractType,
    required this.workDays,
    required this.projectType,
    required this.projects,
    this.effectiveDate,
  });

  @override
  List<Object?> get props => [
        userId,
        userName,
        newRole,
        workloadMinutes,
        contractType,
        workDays,
        projectType,
        projects,
        effectiveDate,
      ];
}

/// Remove um usuário do sistema
class DeleteUserEvent extends UserManagementEvent {
  final String userId;
  final String userName;

  const DeleteUserEvent({
    required this.userId,
    required this.userName,
  });

  @override
  List<Object?> get props => [userId, userName];
}

/// Busca usuários por query
class SearchUsersEvent extends UserManagementEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Busca solicitações pendentes por query
class SearchPendingRequestsEvent extends UserManagementEvent {
  final String query;

  const SearchPendingRequestsEvent(this.query);

  @override
  List<Object?> get props => [query];
}
