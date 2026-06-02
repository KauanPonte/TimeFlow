import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_event.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_state.dart';
import 'package:flutter_application_appdeponto/pages/history_page/history_page.dart';
import 'package:flutter_application_appdeponto/pages/admin/users_management/widgets/user_card.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class ControlePontoPage extends StatelessWidget {
  const ControlePontoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserManagementBloc(
        globalLoading: context.read<GlobalLoadingCubit>(),
      )..add(const LoadUsersEvent()),
      child: const _ControlePontoView(),
    );
  }
}

class _ControlePontoView extends StatefulWidget {
  const _ControlePontoView();

  @override
  State<_ControlePontoView> createState() => _ControlePontoViewState();
}

class _ControlePontoViewState extends State<_ControlePontoView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String? _currentUid;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUid();
  }

  Future<void> _loadCurrentUid() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentUid = prefs.getString('userUid');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface),
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
              child: const Icon(
                Icons.access_time,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Controle de Ponto',
              style: AppTextStyles.h3
                  .copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ],
        ),
      ),
      body: BlocBuilder<UserManagementBloc, UserManagementState>(
        builder: (context, state) {
          if (state is UserManagementLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            );
          }

          if (state is UserManagementError) {
            return Center(
              child: Text(
                state.message,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.error,
                ),
              ),
            );
          }

          if (state is UsersLoaded) {
            return Column(
              children: [
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
                      suffixIcon: state.searchQuery.isNotEmpty
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
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<UserManagementBloc>()
                          .add(const LoadUsersEvent());
                    },
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = state.filteredUsers[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: UserCard(
                            user: user,
                            isCurrentUser: user['id'] == _currentUid,
                            onTap: () => _openHistory(user),
                            onEdit: () {},
                            onDelete: () {},
                            showActions: false,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openHistory(Map<String, dynamic> user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryPage(
          targetUid: user['id'] as String?,
          targetName: user['name'] as String?,
          targetProfileImage:
              (user['profileImage'] ?? user['profileImageURL']) as String?,
          showMonthlyTab: true,
        ),
      ),
    );
  }
}
