import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/pages/admin/home/relatorios/reports_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_event.dart';
import 'package:flutter_application_appdeponto/blocs/admin_home/admin_home_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/bottom_nav.dart';
import 'package:flutter_application_appdeponto/widgets/main_app_bar.dart';
import 'widgets/admin_welcome_card.dart';
import 'widgets/admin_stat_card.dart';
import 'widgets/admin_menu_item.dart';
import '../users_management/users_management_page.dart';
import '../create_user/create_user_page.dart';

class HomeAdminPage extends StatelessWidget {
  final String employeeName;
  final String profileImageUrl;
  final String employeeRole;

  const HomeAdminPage({
    super.key,
    required this.employeeName,
    required this.profileImageUrl,
    required this.employeeRole,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdminHomeBloc()..add(const LoadAdminStatsEvent()),
      child: HomeAdminView(
        employeeName: employeeName,
        profileImageUrl: profileImageUrl,
        employeeRole: employeeRole,
      ),
    );
  }
}

class HomeAdminView extends StatelessWidget {
  final String employeeName;
  final String profileImageUrl;
  final String employeeRole;

  const HomeAdminView({
    super.key,
    required this.employeeName,
    required this.profileImageUrl,
    required this.employeeRole,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: const MainAppBar(subtitle: 'Painel Admin'),
      bottomNavigationBar: BottomNav(
        index: 0,
        isAdmin: true,
        args: {
          'employeeName': employeeName,
          'profileImageUrl': profileImageUrl,
          'employeeRole': employeeRole,
        },
      ),
      body: BlocBuilder<AdminHomeBloc, AdminHomeState>(
        builder: (context, state) {
          if (state is AdminHomeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminHomeError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<AdminHomeBloc>().add(
                            const LoadAdminStatsEvent(),
                          );
                    },
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final stats = state is AdminHomeLoaded
              ? state
              : const AdminHomeLoaded(totalUsers: 0, pendingRequests: 0);

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminHomeBloc>().add(const RefreshAdminStatsEvent());
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Welcome Section
                AdminWelcomeCard(employeeName: employeeName),
                const SizedBox(height: 24),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: AdminStatCard(
                        icon: Icons.people,
                        label: 'Usuários',
                        value: '${stats.totalUsers}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AdminStatCard(
                        icon: Icons.person_add,
                        label: 'Pendentes',
                        value: '${stats.pendingRequests}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section Title
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Ações Rápidas',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                    ),
                  ),
                ),

                // Menu Items
                AdminMenuItem(
                  icon: Icons.person_add,
                  title: 'Cadastrar Usuário',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateUserPage(),
                      ),
                    );
                    if (result == true && context.mounted) {
                      context
                          .read<AdminHomeBloc>()
                          .add(const RefreshAdminStatsEvent());
                    }
                  },
                ),
                const SizedBox(height: 8),
                AdminMenuItem(
                  icon: Icons.group,
                  title: 'Gerenciar Usuários',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UsersManagementPage(),
                      ),
                    );
                    // Recarrega stats quando voltar
                    if (context.mounted) {
                      context
                          .read<AdminHomeBloc>()
                          .add(const RefreshAdminStatsEvent());
                    }
                  },
                ),
                const SizedBox(height: 8), // Espaçamento
                // NOVO BOTÃO RELATÓRIOS
                AdminMenuItem(
                  icon: Icons.assignment_outlined,
                  title: 'Relatórios',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        // REMOVA O CONST DAQUI
                        builder: (context) => const ReportsPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
