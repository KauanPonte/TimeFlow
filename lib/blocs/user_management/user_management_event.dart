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
  final String role;

  const ApproveRequestEvent({
    required this.requestId,
    required this.userName,
    required this.role,
  });

  @override
  List<Object?> get props => [requestId, userName, role];
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
