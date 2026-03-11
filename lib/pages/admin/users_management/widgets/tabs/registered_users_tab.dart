import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_event.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/pages/history_page/history_page.dart';
import '../user_card.dart';
import '../empty_users_state.dart';
import '../error_loading_state.dart';
import '../dialogs/edit_role_dialog.dart';
import '../dialogs/delete_user_dialog.dart';

class RegisteredUsersTab extends StatefulWidget {
  const RegisteredUsersTab({super.key});

  @override
  State<RegisteredUsersTab> createState() => _RegisteredUsersTabState();
}

class _RegisteredUsersTabState extends State<RegisteredUsersTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _cachedUsers;
  String _cachedSearchQuery = '';
  TabController? _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Carrega os usuários apenas se ainda não foram carregados
    final currentState = context.read<UserManagementBloc>().state;
    if (currentState is! UsersLoaded) {
      context.read<UserManagementBloc>().add(const LoadUsersEvent());
    } else {
      _cachedUsers = currentState.users;
      _cachedSearchQuery = currentState.searchQuery;
    }
    // Escuta mudanças de aba para recarregar dados quando necessário
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = DefaultTabController.of(context);
      _tabController?.addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    if (!mounted) return;
    // Verifica sempre que o index é 0, inclusive durante arrastos parciais
    if (_tabController?.index == 0) {
      final currentState = context.read<UserManagementBloc>().state;
      if (currentState is! UsersLoaded &&
          currentState is! UserManagementLoading) {
        context.read<UserManagementBloc>().add(const LoadUsersEvent());
      }
    }
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessário para AutomaticKeepAliveClientMixin
    return BlocBuilder<UserManagementBloc, UserManagementState>(
      builder: (context, state) {
        // Atualiza cache quando recebe UsersLoaded
        if (state is UsersLoaded) {
          _cachedUsers = state.users;
          _cachedSearchQuery = state.searchQuery;
        }

        if (state is UserManagementLoading && _cachedUsers == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (state is UserManagementError && _cachedUsers == null) {
          return ErrorLoadingState(
            title: state.message,
            subtitle: state.details ?? 'Tente novamente mais tarde',
          );
        }

        // Usa cache se o estado não for UsersLoaded mas tivermos dados
        final users = state is UsersLoaded ? state.users : _cachedUsers;
        final searchQuery =
            state is UsersLoaded ? state.searchQuery : _cachedSearchQuery;

        if (users == null) {
          return const Center(child: Text('Carregando...'));
        }

        final usersNonNull = users;

        final filteredUsers = searchQuery.isEmpty
            ? usersNonNull
            : usersNonNull.where((user) {
                final name = user['name'].toString().toLowerCase();
                final email = user['email'].toString().toLowerCase();
                final role = user['role'].toString().toLowerCase();
                final query = searchQuery.toLowerCase();

                return name.contains(query) ||
                    email.contains(query) ||
                    role.contains(query);
              }).toList();

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  context
                      .read<UserManagementBloc>()
                      .add(SearchUsersEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nome, email ou cargo...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<UserManagementBloc>()
                                .add(const SearchUsersEvent(''));
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // User List
            Expanded(
              child: usersNonNull.isEmpty
                  ? const EmptyUsersState()
                  : filteredUsers.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Nenhum resultado encontrado',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tente buscar com outros termos',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            context
                                .read<UserManagementBloc>()
                                .add(const LoadUsersEvent());
                          },
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              return UserCard(
                                user: user,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => HistoryPage(
                                        targetUid: user['id'],
                                        targetName: user['name'],
                                      ),
                                    ),
                                  );
                                },
                                onEditRole: () => _showEditRoleDialog(
                                  user['id'],
                                  user['name'],
                                  user['role'],
                                ),
                                onEditWorkload: () => _showEditWorkloadDialog(
                                  user['id'],
                                  user['name'],
                                ),
                                onDelete: () => _showDeleteUserDialog(
                                  user['id'],
                                  user['name'],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditRoleDialog(
    String userId,
    String userName,
    String currentRole,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => EditRoleDialog(
        userName: userName,
        currentRole: currentRole,
        onSave: (newRole) {
          context.read<UserManagementBloc>().add(
                UpdateUserRoleEvent(
                  userId: userId,
                  userName: userName,
                  newRole: newRole,
                ),
              );
          Navigator.pop(context);
        },
      ),
    );
  }

  int? _parseCargaHoraria(String input) {
    input = input.trim();

    if (input.contains(':')) {
      final parts = input.split(':');

      if (parts.length != 2) return null;

      final horas = int.tryParse(parts[0]);
      final minutos = int.tryParse(parts[1]);

      if (horas == null || minutos == null) return null;
      if (minutos < 0 || minutos >= 60) return null;
      if (horas < 0) return null;

      return horas * 60 + minutos;
    }

    final horas = int.tryParse(input);
    if (horas == null || horas < 0) return null;

    return horas * 60;
  }

 Future<void> _showEditWorkloadDialog(
  String userId,
  String userName,
) async {
  final controller = TextEditingController();
   final blocContext = context;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Editar carga horária de $userName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Digite a carga horária diária (ex: 8 ou 8:30)',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Carga horária',
                hintText: 'Ex: 8:30',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final minutos = _parseCargaHoraria(controller.text);

              if (minutos == null) {
                ScaffoldMessenger.of(blocContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Formato inválido. Use 8 ou 8:30',
                    ),
                  ),
                );
                return;
              }

              blocContext.read<UserManagementBloc>().add(
                    UpdateUserWorkloadEvent(
                      userId: userId,
                      userName: userName,
                      cargaHorariaMinutos: minutos,
                    ),
                  );

              Navigator.pop(dialogContext);
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}

  Future<void> _showDeleteUserDialog(String userId, String userName) async {
    await showDialog(
      context: context,
      builder: (context) => DeleteUserDialog(
        userName: userName,
        onConfirm: () {
          context.read<UserManagementBloc>().add(
                DeleteUserEvent(
                  userId: userId,
                  userName: userName,
                ),
              );
          Navigator.pop(context);
        },
      ),
    );
  }
}
