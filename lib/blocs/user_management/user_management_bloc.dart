import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_management_event.dart';
import 'user_management_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementBloc
    extends Bloc<UserManagementEvent, UserManagementState> {
  UserManagementBloc() : super(const UserManagementInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<LoadPendingRequestsEvent>(_onLoadPendingRequests);
    on<ApproveRequestEvent>(_onApproveRequest);
    on<RejectRequestEvent>(_onRejectRequest);
    on<UpdateUserRoleEvent>(_onUpdateUserRole);
    on<UpdateUserWorkloadEvent>(_onUpdateUserWorkload);
    on<DeleteUserEvent>(_onDeleteUser);
    on<SearchUsersEvent>(_onSearchUsers);
    on<SearchPendingRequestsEvent>(_onSearchPendingRequests);
  }

  /// Carrega lista de usuários cadastrados
  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      // Só emite Loading se não houver dados em cache
      if (state is! UsersLoaded) {
        emit(const UserManagementLoading());
      }
      // Exclui o próprio admin logado da listagem
      final prefs = await SharedPreferences.getInstance();
      final currentUid = prefs.getString('userUid');
      final users = await UserRepository.getUsers(excludeUid: currentUid);
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UserManagementError(
        message: 'Erro ao carregar usuários',
        details: e.toString(),
      ));
    }
  }

  /// Carrega lista de solicitações pendentes
  Future<void> _onLoadPendingRequests(
    LoadPendingRequestsEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      // Só emite Loading se não houver dados em cache
      if (state is! PendingRequestsLoaded) {
        emit(const UserManagementLoading());
      }
      final requests = await UserRepository.getPendingRequests();
      emit(PendingRequestsLoaded(requests: requests));
    } catch (e) {
      emit(UserManagementError(
        message: 'Erro ao carregar solicitações',
        details: e.toString(),
      ));
    }
  }

  /// Aprova uma solicitação de cadastro
  Future<void> _onApproveRequest(
    ApproveRequestEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final currentState = state;

      await UserRepository.approveRequest(
        requestId: event.requestId,
        cargaHoraria: event.cargaHoraria,
        role: event.role,
      );

      // Recarrega as solicitações pendentes
      final requests = await UserRepository.getPendingRequests();
      final newState = PendingRequestsLoaded(
        requests: requests,
        searchQuery: currentState is PendingRequestsLoaded
            ? currentState.searchQuery
            : '',
      );

      // Emite sucesso apenas uma vez
      emit(UserManagementActionSuccess(
        message: '${event.userName} aprovado com sucesso!',
        previousState: newState,
      ));

      // Aguarda um pouco e então emite o novo estado
      await Future.delayed(const Duration(milliseconds: 100));
      emit(newState);
    } catch (e) {
      emit(UserManagementError(
        message: 'Erro ao aprovar solicitação',
        details: e.toString(),
      ));
    }
  }

  /// Rejeita uma solicitação de cadastro
  Future<void> _onRejectRequest(
    RejectRequestEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final currentState = state;

      await UserRepository.rejectRequest(event.requestId);

      // Recarrega as solicitações pendentes
      final requests = await UserRepository.getPendingRequests();
      final newState = PendingRequestsLoaded(
        requests: requests,
        searchQuery: currentState is PendingRequestsLoaded
            ? currentState.searchQuery
            : '',
      );

      emit(UserManagementActionSuccess(
        message: 'Solicitação de ${event.userName} rejeitada',
        previousState: newState,
      ));

      // Aguarda um pouco e então emite o novo estado
      await Future.delayed(const Duration(milliseconds: 100));
      emit(newState);
    } catch (e) {
      emit(UserManagementError(
        message: 'Erro ao rejeitar solicitação',
        details: e.toString(),
      ));
    }
  }

  /// Atualiza o cargo de um usuário
  Future<void> _onUpdateUserRole(
    UpdateUserRoleEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final currentState = state;

      await UserRepository.updateUserRole(event.userId, event.newRole);

      // Recarrega os usuários excluindo o admin logado
      final prefs = await SharedPreferences.getInstance();
      final currentUid = prefs.getString('userUid');
      final users = await UserRepository.getUsers(excludeUid: currentUid);
      final newState = UsersLoaded(
        users: users,
        searchQuery:
            currentState is UsersLoaded ? currentState.searchQuery : '',
      );

      emit(UserManagementActionSuccess(
        message: 'Cargo de ${event.userName} atualizado com sucesso!',
        previousState: newState,
      ));

      emit(newState);
    } catch (e) {
      emit(UserManagementError(
        message: 'Erro ao atualizar cargo',
        details: e.toString(),
      ));
    }
  }

Future<void> _onUpdateUserWorkload(
  UpdateUserWorkloadEvent event,
  Emitter<UserManagementState> emit,
) async {
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(event.userId)
        .update({
      'cargaHorariaMinutos': event.cargaHorariaMinutos,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    emit(
      UserManagementActionSuccess(
        message: 'Carga horária de ${event.userName} atualizada com sucesso',
        previousState: state,
      ),
    );

    add(const LoadUsersEvent());
  } catch (e) {
    emit(
      UserManagementError(
        message: 'Erro ao atualizar carga horária',
        details: e.toString(),
      ),
    );
  }
}

  /// Remove um usuário do sistema
  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    try {
      final currentState = state;

      await UserRepository.deleteUser(event.userId);

      // Recarrega os usuários excluindo o admin logado
      final prefs = await SharedPreferences.getInstance();
      final currentUid = prefs.getString('userUid');
      final users = await UserRepository.getUsers(excludeUid: currentUid);
      final newState = UsersLoaded(
        users: users,
        searchQuery:
            currentState is UsersLoaded ? currentState.searchQuery : '',
      );

      emit(UserManagementActionSuccess(
        message: '${event.userName} excluído com sucesso',
        previousState: newState,
      ));

      emit(newState);
    } catch (e) {
      emit(UserManagementError(
        message: 'Erro ao excluir usuário',
        details: e.toString(),
      ));
    }
  }

  /// Busca usuários por query
  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state is UsersLoaded) {
      final currentState = state as UsersLoaded;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }

  /// Busca solicitações pendentes por query
  Future<void> _onSearchPendingRequests(
    SearchPendingRequestsEvent event,
    Emitter<UserManagementState> emit,
  ) async {
    if (state is PendingRequestsLoaded) {
      final currentState = state as PendingRequestsLoaded;
      emit(currentState.copyWith(searchQuery: event.query));
    }
  }
}
