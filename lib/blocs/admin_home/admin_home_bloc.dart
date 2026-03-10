import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/repositories/user_repository.dart';
import 'admin_home_event.dart';
import 'admin_home_state.dart';

class AdminHomeBloc extends Bloc<AdminHomeEvent, AdminHomeState> {
  AdminHomeBloc() : super(const AdminHomeInitial()) {
    on<LoadAdminStatsEvent>(_onLoadStats);
    on<RefreshAdminStatsEvent>(_onRefreshStats);
    on<ResetAdminHomeEvent>((_, emit) => emit(const AdminHomeInitial()));
  }

  /// Limpa o estado (chamado no logout).
  void reset() => add(const ResetAdminHomeEvent());

  /// Carrega as estatísticas do dashboard
  Future<void> _onLoadStats(
    LoadAdminStatsEvent event,
    Emitter<AdminHomeState> emit,
  ) async {
    try {
      emit(const AdminHomeLoading());

      final totalUsers = await UserRepository.getTotalUsers();
      final pendingRequests = await UserRepository.getPendingRequestsCount();

      emit(AdminHomeLoaded(
        totalUsers: totalUsers,
        pendingRequests: pendingRequests,
      ));
    } catch (e) {
      emit(AdminHomeError('Erro ao carregar estatísticas: ${e.toString()}'));
    }
  }

  /// Atualiza as estatísticas (refresh)
  Future<void> _onRefreshStats(
    RefreshAdminStatsEvent event,
    Emitter<AdminHomeState> emit,
  ) async {
    // Não mostra loading no refresh para melhor UX
    try {
      final totalUsers = await UserRepository.getTotalUsers();
      final pendingRequests = await UserRepository.getPendingRequestsCount();

      emit(AdminHomeLoaded(
        totalUsers: totalUsers,
        pendingRequests: pendingRequests,
      ));
    } catch (e) {
      // Mantém o estado anterior em caso de erro no refresh
      if (state is AdminHomeLoaded) {
        // Poderia emitir um estado de erro temporário aqui se necessário
        return;
      }
      emit(AdminHomeError('Erro ao atualizar estatísticas: ${e.toString()}'));
    }
  }
}
