import 'package:equatable/equatable.dart';

abstract class AdminHomeEvent extends Equatable {
  const AdminHomeEvent();

  @override
  List<Object?> get props => [];
}

/// Carrega as estatísticas do dashboard
class LoadAdminStatsEvent extends AdminHomeEvent {
  const LoadAdminStatsEvent();
}

/// Atualiza as estatísticas (refresh)
class RefreshAdminStatsEvent extends AdminHomeEvent {
  const RefreshAdminStatsEvent();
}
