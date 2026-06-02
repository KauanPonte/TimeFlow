import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_event.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_state.dart';
import 'package:flutter_application_appdeponto/pages/admin/relatorios/user_report_page.dart';
import 'package:flutter_application_appdeponto/pages/admin/users_management/users_management_mode.dart';
import 'package:flutter_application_appdeponto/services/analytics_service.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import '../dialogs/edit_user_dialog.dart';
import '../user_card.dart';
import '../empty_users_state.dart';
import '../error_loading_state.dart';

class RegisteredUsersTab extends StatefulWidget {
  final UsersManagementMode mode;

  const RegisteredUsersTab({
    super.key,
    required this.mode,
  });

  @override
  State<RegisteredUsersTab> createState() => _RegisteredUsersTabState();
}

class _RegisteredUsersTabState extends State<RegisteredUsersTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _cachedUsers;
  String _cachedSearchQuery = '';
  String? _currentUid;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUid();
    // Carrega os usuarios apenas se ainda nao foram carregados
    final currentState = context.read<UserManagementBloc>().state;
    if (currentState is! UsersLoaded) {
      context.read<UserManagementBloc>().add(const LoadUsersEvent());
    } else {
      _cachedUsers = currentState.users;
      _cachedSearchQuery = currentState.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUid() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUid = prefs.getString('userUid');
    if (!mounted) return;
    setState(() {
      _currentUid = currentUid;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Necessario para AutomaticKeepAliveClientMixin
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

        // Usa cache se o estado nao for UsersLoaded mas tivermos dados
        final users = state is UsersLoaded ? state.users : _cachedUsers;
        final searchQuery =
            state is UsersLoaded ? state.searchQuery : _cachedSearchQuery;

        if (users == null) {
          return const Center(child: Text('Carregando...'));
        }

        final usersNonNull = users;

        final filteredUsers = _applyFilters(usersNonNull, searchQuery);

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                              final isEmployeesMode =
                                  widget.mode == UsersManagementMode.employees;
                              return UserCard(
                                user: user,
                                isCurrentUser: user['id'] == _currentUid,
                                onTap: isEmployeesMode
                                    ? null
                                    : () => _openUserReport(user),
                                onEdit: isEmployeesMode
                                    ? () => _openEditUserDialog(user)
                                    : () {},
                                onDelete: () {},
                                showActions: isEmployeesMode,
                                showDeleteAction: false,
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

  List<Map<String, dynamic>> _applyFilters(
    List<Map<String, dynamic>> users,
    String searchQuery,
  ) {
    final query = searchQuery.toLowerCase().trim();
    final searchFiltered = query.isEmpty
        ? users
        : users.where((user) {
            final name = user['name'].toString().toLowerCase();
            final email = user['email'].toString().toLowerCase();
            final role = user['role'].toString().toLowerCase();
            return name.contains(query) ||
                email.contains(query) ||
                role.contains(query);
          }).toList();

    return searchFiltered;
  }

  Future<void> _openUserReport(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';

    AnalyticsService.logAdminOpenUserReport(
      userId: userId,
      adminUid: _currentUid,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserReportPage(user: user),
      ),
    );
  }

  void _openEditUserDialog(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => EditUserDialog(
        userName: user['name']?.toString() ?? '',
        currentRole: user['role']?.toString() ?? '',
        currentWorkloadMinutes: user['workloadMinutes'] as int?,
        currentContractType: user['contractType']?.toString() ?? '',
        currentWorkDays: (user['workDays'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        currentProjectType: user['projectType']?.toString() ?? '',
        currentProjects: (user['projects'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        onSave: ({
          required String role,
          required int workloadMinutes,
          required String contractType,
          required List<String> workDays,
          required String projectType,
          required List<String> projects,
          required DateTime? effectiveDate,
        }) {
          context.read<UserManagementBloc>().add(
                UpdateUserProfileEvent(
                  userId: user['id']?.toString() ?? '',
                  userName: user['name']?.toString() ?? '',
                  newRole: role,
                  workloadMinutes: workloadMinutes,
                  contractType: contractType,
                  workDays: workDays,
                  projectType: projectType,
                  projects: projects,
                  effectiveDate: effectiveDate,
                ),
              );
        },
      ),
    );
  }
}
