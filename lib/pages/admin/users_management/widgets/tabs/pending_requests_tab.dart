import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_event.dart';
import 'package:flutter_application_appdeponto/blocs/user_management/user_management_state.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
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
    context.read<AtestadoBloc>().add(const LoadAtestadosEvent(isAdmin: true));
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

        return BlocConsumer<AtestadoBloc, AtestadoState>(
          listener: (context, atestadoState) {
            if (atestadoState is AtestadoActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(atestadoState.message),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            }
          },
          builder: (context, atestadoState) {
            final atestados = switch (atestadoState) {
              AtestadoLoaded(:final atestados) => atestados,
              AtestadoActionSuccess(:final atestados) => atestados,
              _ => <AtestadoModel>[],
            };

            final totalEmpty = requestsNonNull.isEmpty && atestados.isEmpty;

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
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppColors.primary, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),

                // Lista unificada
                Expanded(
                  child: totalEmpty
                      ? const EmptyRequestsState()
                      : RefreshIndicator(
                          onRefresh: () async {
                            context
                                .read<UserManagementBloc>()
                                .add(const LoadPendingRequestsEvent());
                            context
                                .read<AtestadoBloc>()
                                .add(const LoadAtestadosEvent(isAdmin: true));
                          },
                          color: AppColors.primary,
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              // Atestados pendentes integrados na lista
                              ...atestados.map(
                                  (a) => _AtestadoPendingCard(atestado: a)),
                              // Solicitações de cadastro
                              ...filteredRequests.map((request) =>
                                  PendingRequestCard(
                                    request: request,
                                    onApprove: () => _showApproveDialog(
                                      request['id'],
                                      request['name'],
                                    ),
                                    onReject: () => _showRejectDialog(
                                      request['id'],
                                      request['name'],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
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
        onApprove: (role, cargaHoraria) {
          bloc.add(
            ApproveRequestEvent(
              requestId: requestId,
              userName: userName,
              cargaHoraria: cargaHoraria,
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

class _AtestadoPendingCard extends StatelessWidget {
  final AtestadoModel atestado;
  const _AtestadoPendingCard({required this.atestado});

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Recusar atestado'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Motivo (opcional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AtestadoBloc>().add(
                    RejectAtestadoEvent(
                      atestado.id,
                      reason: controller.text.trim().isEmpty
                          ? null
                          : controller.text.trim(),
                    ),
                  );
            },
            child: const Text('Recusar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final inicio = fmt.format(DateTime.parse(atestado.dataInicio));
    final fim = fmt.format(DateTime.parse(atestado.dataFim));
    final mesmodia = atestado.dataInicio == atestado.dataFim;
    final dias =
        DateTime.parse(atestado.dataFim).difference(DateTime.parse(atestado.dataInicio)).inDays + 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  atestado.employeeName,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                DateFormat('dd/MM/yy').format(atestado.createdAt),
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.date_range_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                mesmodia ? inicio : '$inicio – $fim',
                style: AppTextStyles.bodySmall,
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$dias ${dias == 1 ? 'dia' : 'dias'}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (atestado.fileUrl != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(
                        Uri.parse(atestado.fileUrl!),
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                  label: const Text('Ver documento'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showRejectDialog(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Recusar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context
                        .read<AtestadoBloc>()
                        .add(ApproveAtestadoEvent(atestado.id));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Aprovar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
