import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_event.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import '../pending_request_card.dart';
import '../empty_requests_state.dart';
import '../error_loading_state.dart';
import '../dialogs/approve_request_dialog.dart';
import '../dialogs/reject_request_dialog.dart';

class PendingRequestsTab extends StatefulWidget {
  const PendingRequestsTab({super.key});

  @override
  State<PendingRequestsTab> createState() => _PendingRequestsTabState();
}

class _PendingRequestsTabState extends State<PendingRequestsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>>? _cachedRequests;
  String _cachedSearchQuery = '';
  TabController? _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Tenta usar dados do estado atual para evitar recarregar se já estivermos com os dados carregados
    final currentState = BlocProvider.of<UserManagementBloc>(context).state;
    if (currentState is PendingRequestsLoaded) {
      _cachedRequests = currentState.requests;
      _cachedSearchQuery = currentState.searchQuery;
    }
    // Escuta mudanças de aba para carregar dados quando o usuário chegar aqui
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController = DefaultTabController.of(context);
      _tabController?.addListener(_onTabChanged);
      // Carrega imediatamente se já estiver na aba 1 (navegação direta)
      if (_tabController?.index == 1) {
        _loadIfNeeded();
      }
    });
  }

  void _loadIfNeeded() {
    final currentState = BlocProvider.of<UserManagementBloc>(context).state;
    if (currentState is! PendingRequestsLoaded &&
        currentState is! UserManagementLoading) {
      BlocProvider.of<UserManagementBloc>(context)
          .add(const LoadPendingRequestsEvent());
    }
  }

  void _onTabChanged() {
    if (!mounted) return;
    // Só carrega quando o usuário realmente chega na aba (animação concluída)
    if (_tabController?.index == 1 &&
        !(_tabController?.indexIsChanging ?? true)) {
      _loadIfNeeded();
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
        // Atualiza cache quando recebe PendingRequestsLoaded
        if (state is PendingRequestsLoaded) {
          _cachedRequests = state.requests;
          _cachedSearchQuery = state.searchQuery;
        }

        if (state is UserManagementLoading && _cachedRequests == null) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (state is UserManagementError && _cachedRequests == null) {
          return ErrorLoadingState(
            title: state.message,
            subtitle: state.details ?? 'Tente novamente mais tarde',
          );
        }

        // Usa cache se o estado não for PendingRequestsLoaded mas tivermos dados
        final requests =
            state is PendingRequestsLoaded ? state.requests : _cachedRequests;
        final searchQuery = state is PendingRequestsLoaded
            ? state.searchQuery
            : _cachedSearchQuery;

        if (requests == null) {
          return const Center(
              child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ));
        }

        final requestsNonNull = requests;

        final filteredRequests = searchQuery.isEmpty
            ? requestsNonNull
            : requestsNonNull.where((request) {
                final name = request['name'].toString().toLowerCase();
                final email = request['email'].toString().toLowerCase();
                final query = searchQuery.toLowerCase();

                return name.contains(query) || email.contains(query);
              }).toList();

        return Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  BlocProvider.of<UserManagementBloc>(context)
                      .add(SearchPendingRequestsEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Buscar por nome ou email...',
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.primary),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            BlocProvider.of<UserManagementBloc>(context)
                                .add(const SearchPendingRequestsEvent(''));
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

            // Requests List
            Expanded(
              child: requestsNonNull.isEmpty
                  ? const EmptyRequestsState()
                  : filteredRequests.isEmpty
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
                                .add(const LoadPendingRequestsEvent());
                          },
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredRequests.length,
                            itemBuilder: (context, index) {
                              final request = filteredRequests[index];
                              return PendingRequestCard(
                                request: request,
                                onApprove: () => _showApproveDialog(
                                  request['id'],
                                  request['name'],
                                ),
                                onReject: () => _showRejectDialog(
                                  request['id'],
                                  request['name'],
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

  Future<void> _showApproveDialog(String requestId, String userName) async {
    final bloc = BlocProvider.of<UserManagementBloc>(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => ApproveRequestDialog(
        userName: userName,
        onApprove: (role) {
          bloc.add(
            ApproveRequestEvent(
              requestId: requestId,
              userName: userName,
              role: role,
            ),
          );
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  Future<void> _showRejectDialog(String requestId, String userName) async {
    final bloc = BlocProvider.of<UserManagementBloc>(context);
    await showDialog(
      context: context,
      builder: (dialogContext) => RejectRequestDialog(
        userName: userName,
        onConfirm: () {
          bloc.add(
            RejectRequestEvent(
              requestId: requestId,
              userName: userName,
            ),
          );
          Navigator.pop(dialogContext);
        },
      ),
    );
  }
}
