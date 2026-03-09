import 'package:equatable/equatable.dart';

abstract class AdminHomeState extends Equatable {
  const AdminHomeState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AdminHomeInitial extends AdminHomeState {
  const AdminHomeInitial();
}

/// Carregando estatísticas
class AdminHomeLoading extends AdminHomeState {
  const AdminHomeLoading();
}

/// Estatísticas carregadas
class AdminHomeLoaded extends AdminHomeState {
  final int totalUsers;
  final int pendingRequests;

  const AdminHomeLoaded({
    required this.totalUsers,
    required this.pendingRequests,
  });

  @override
  List<Object?> get props => [totalUsers, pendingRequests];

  AdminHomeLoaded copyWith({
    int? totalUsers,
    int? pendingRequests,
  }) {
    return AdminHomeLoaded(
      totalUsers: totalUsers ?? this.totalUsers,
      pendingRequests: pendingRequests ?? this.pendingRequests,
    );
  }
}

/// Erro ao carregar estatísticas
class AdminHomeError extends AdminHomeState {
  final String message;

  const AdminHomeError(this.message);

  @override
  List<Object?> get props => [message];
}
