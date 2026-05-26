import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_state.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_event.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'users_management_mode.dart';
import 'widgets/tabs/registered_users_tab.dart';

class UsersManagementPage extends StatelessWidget {
  final UsersManagementMode mode;

  const UsersManagementPage({
    super.key,
    this.mode = UsersManagementMode.reports,
  });

  @override
  Widget build(BuildContext context) {
    final isEmployeesMode = mode == UsersManagementMode.employees;

    return BlocProvider(
      create: (context) => UserManagementBloc(
        globalLoading: context.read<GlobalLoadingCubit>(),
      ),
      child: BlocListener<UserManagementBloc, UserManagementState>(
        listener: (context, state) {
          // Centraliza exibição de snackbar em um único lugar
          if (state is UserManagementActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );

            // Recarrega usuários cadastrados após aprovação/rejeição
            if (state.previousState is PendingRequestsLoaded) {
              context.read<UserManagementBloc>().add(const LoadUsersEvent());
            }
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.bgLight,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isEmployeesMode
                        ? Icons.people_outline
                        : Icons.bar_chart_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEmployeesMode ? 'Funcionários' : 'Relatórios',
                  style:
                      AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          body: RegisteredUsersTab(mode: mode),
        ),
      ),
    );
  }
}
