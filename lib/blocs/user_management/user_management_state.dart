import 'package:equatable/equatable.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial do BLoC
class UserManagementInitial extends UserManagementState {
  const UserManagementInitial();
}

/// Carregando dados
class UserManagementLoading extends UserManagementState {
  const UserManagementLoading();
}

/// Usuários cadastrados carregados com sucesso
class UsersLoaded extends UserManagementState {
  final List<Map<String, dynamic>> users;
  final String searchQuery;

  const UsersLoaded({
    required this.users,
    this.searchQuery = '',
  });

  List<Map<String, dynamic>> get filteredUsers {
    if (searchQuery.isEmpty) return users;

    return users.where((user) {
      final name = user['name'].toString().toLowerCase();
      final email = user['email'].toString().toLowerCase();
      final role = user['role'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return name.contains(query) ||
          email.contains(query) ||
          role.contains(query);
    }).toList();
  }

  @override
  List<Object?> get props => [users, searchQuery];

  UsersLoaded copyWith({
    List<Map<String, dynamic>>? users,
    String? searchQuery,
  }) {
    return UsersLoaded(
      users: users ?? this.users,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Solicitações pendentes carregadas com sucesso
class PendingRequestsLoaded extends UserManagementState {
  final List<Map<String, dynamic>> requests;
  final String searchQuery;

  const PendingRequestsLoaded({
    required this.requests,
    this.searchQuery = '',
  });

  List<Map<String, dynamic>> get filteredRequests {
    if (searchQuery.isEmpty) return requests;

    return requests.where((request) {
      final name = request['name'].toString().toLowerCase();
      final email = request['email'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  List<Object?> get props => [requests, searchQuery];

  PendingRequestsLoaded copyWith({
    List<Map<String, dynamic>>? requests,
    String? searchQuery,
  }) {
    return PendingRequestsLoaded(
      requests: requests ?? this.requests,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Erro ao carregar dados
class UserManagementError extends UserManagementState {
  final String message;
  final String? details;

  const UserManagementError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}

/// Ação executada com sucesso (aprovar, rejeitar, atualizar, deletar)
class UserManagementActionSuccess extends UserManagementState {
  final String message;
  final UserManagementState previousState;

  const UserManagementActionSuccess({
    required this.message,
    required this.previousState,
  });

  @override
  List<Object?> get props => [message, previousState];
}
