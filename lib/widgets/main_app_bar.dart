import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_today/ponto_today_state.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/profile/profile_state.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_state.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/pages/admin/solicitations/solicitation_review_dialog.dart';
import 'package:flutter_application_appdeponto/repositories/solicitation_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import '../pages/solicitacoes_page/solicitacoes_page.dart';

/// AppBar padrão para as telas principais (Painel, Meu Ponto, Perfil).
/// Logo + subtítulo configurável + menu com "Sair" (e "Configurações" opcional).
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final bool showSettings;
  final VoidCallback? onSettingsTap;

  /// Callback disparado quando o usuário toca em um dia na lista de
  /// registros incompletos. Se fornecido, NÃO navega — delega à tela
  /// atual (ex.: [HomePage]) para tratar internamente.
  /// Se null, navega para a rota /home com `initialHistoryDate`.
  final void Function(DateTime date)? onNotificationDayTap;

  const MainAppBar({
    super.key,
    required this.subtitle,
    this.showSettings = false,
    this.onSettingsTap,
    this.onNotificationDayTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Incompletos helpers
  static List<MapEntry<String, Map<String, String>>> _computeIncompletos(
      PontoTodayState state) {
    final now = DateTime.now();
    final hoje =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return state.registros.entries.where((e) {
      if (e.key == hoje) return false;
      final m = e.value;
      if (m['entrada'] != null && m['saida'] == null) return true;
      if (m['pausa'] != null && m['retorno'] == null) return true;
      return false;
    }).toList()
      ..sort((a, b) => b.key.compareTo(a.key));
  }

  static bool _resolveIsAdmin(BuildContext context) {
    final profileState = context.read<ProfileBloc>().state;
    if (profileState is ProfileLoaded && profileState.role.isNotEmpty) {
      return profileState.role.toUpperCase().contains('ADM');
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is AdminAuthenticated) return true;
    if (authState is UserAuthenticated) {
      final r = (authState.userData['role'] ?? '').toString();
      return r.toUpperCase().contains('ADM');
    }
    return false;
  }

  void _showNotificationsSheet(
    BuildContext context,
    List<MapEntry<String, Map<String, String>>> incompletos, {
    bool isAdmin = false,
    List<SolicitationModel> reviewedSolicitations = const [],
  }) {
    // Obtém solicitações pendentes para admin
    List<SolicitationModel> solicitations = [];
    if (isAdmin) {
      final solState = context.read<SolicitationBloc>().state;
      if (solState is SolicitationLoaded) {
        solicitations = solState.solicitations
            .where((s) => s.status == SolicitationStatus.pending)
            .toList();
      } else if (solState is SolicitationActionSuccess) {
        solicitations = solState.solicitations
            .where((s) => s.status == SolicitationStatus.pending)
            .toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        final Set<String> pendingDismiss = {};
        final Set<String> seenInSession = {};
        return StatefulBuilder(builder: (_, setSheetState) {
          // Mostra todo o histórico (repo já ordena: não vistos mais recentes primeiro).
          final allReviewed = reviewedSolicitations;
          final unseenCount = allReviewed
              .where((s) => !s.seenByEmployee && !seenInSession.contains(s.id))
              .length;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      //  Estado vazio — sem nenhuma notificação
                      if (incompletos.isEmpty &&
                          allReviewed.isEmpty &&
                          solicitations.isEmpty) ...[
                        const SizedBox(height: 32),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryLight10,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Tudo em dia!',
                                style: AppTextStyles.h3,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nenhuma notificação no momento.',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],

                      //  Seção: Registros incompletos
                      if (incompletos.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: AppColors.warning),
                            const SizedBox(width: 10),
                            const Text('Registros Incompletos',
                                style: AppTextStyles.h3),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${incompletos.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        ...incompletos.map((entry) {
                          final date = DateTime.tryParse(entry.key);
                          final label = date != null
                              ? DateFormat('dd/MM/yyyy', 'pt_BR').format(date)
                              : entry.key;
                          final m = entry.value;
                          final motivo =
                              (m['pausa'] != null && m['retorno'] == null)
                                  ? 'Pausa sem retorno'
                                  : 'Entrada sem saída';
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppColors.warning),
                            ),
                            title: Text(label,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(motivo,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.warning)),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              if (date == null) return;

                              if (onNotificationDayTap != null) {
                                // Tela atual já é a home — trata internamente.
                                onNotificationDayTap!(date);
                              } else {
                                // Outra tela (perfil, admin) — navega para a home.
                                final currentArgs = (ModalRoute.of(context)
                                        ?.settings
                                        .arguments as Map<String, dynamic>?) ??
                                    {};

                                // Resolve nome e foto: prioriza args da rota atual,
                                // fallback para AuthBloc (sempre persistente após fix).
                                final authState =
                                    context.read<AuthBloc>().state;
                                Map<String, dynamic> authUserData = {};
                                if (authState is UserAuthenticated) {
                                  authUserData = authState.userData;
                                } else if (authState is AdminAuthenticated) {
                                  authUserData = authState.userData;
                                }

                                final resolvedName =
                                    (currentArgs['employeeName'] as String?)
                                                ?.isNotEmpty ==
                                            true
                                        ? currentArgs['employeeName'] as String
                                        : (authUserData['name'] ?? '')
                                            .toString();

                                final resolvedImage =
                                    (currentArgs['profileImageUrl'] as String?)
                                                ?.isNotEmpty ==
                                            true
                                        ? currentArgs['profileImageUrl']
                                            as String
                                        : (authUserData['profileImage'] ?? '')
                                            .toString();

                                String roleFromArgs =
                                    (currentArgs['employeeRole'] ?? '')
                                        .toString();
                                String chosenRole = roleFromArgs;
                                final profileState =
                                    context.read<ProfileBloc>().state;
                                if (profileState is ProfileLoaded &&
                                    profileState.role.isNotEmpty) {
                                  chosenRole = profileState.role;
                                }

                                // Fallback: role do AuthBloc
                                if (chosenRole.isEmpty) {
                                  chosenRole =
                                      (authUserData['role'] ?? '').toString();
                                }

                                final isAdminUser =
                                    chosenRole.toUpperCase().contains('ADM');

                                final navArgs = <String, dynamic>{
                                  ...currentArgs,
                                  'employeeName': resolvedName,
                                  'profileImageUrl': resolvedImage,
                                  'employeeRole': chosenRole,
                                  'initialHistoryDate': date.toIso8601String(),
                                };

                                final route =
                                    isAdminUser ? '/home/employee' : '/home';
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  route,
                                  (r) => false,
                                  arguments: navArgs,
                                );
                              }
                            },
                          );
                        }),
                      ], // end incompletos

                      //  Seção: Resultado de solicitações (funcionário)
                      if (!isAdmin && allReviewed.isNotEmpty) ...[
                        if (incompletos.isNotEmpty) const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.task_alt_rounded,
                                color: AppColors.success),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('Resultado de Solicitações',
                                  style: AppTextStyles.h3),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$unseenCount',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        ...allReviewed.map((sol) {
                          final isSeen = sol.seenByEmployee ||
                              seenInSession.contains(sol.id);
                          final isPending = pendingDismiss.contains(sol.id);
                          return _buildReviewedSolicitationTile(
                            context,
                            sol,
                            isPendingDismiss: isPending,
                            isSeen: isSeen && !isPending,
                            onLocalDismiss: (isSeen || isPending)
                                ? null
                                : () {
                                    setSheetState(
                                        () => pendingDismiss.add(sol.id));
                                    context.read<SolicitationBloc>().add(
                                          DismissReviewedSolicitationEvent(
                                              solicitationId: sol.id),
                                        );
                                    Future.delayed(
                                        const Duration(milliseconds: 800),
                                        () => setSheetState(() {
                                              pendingDismiss.remove(sol.id);
                                              seenInSession.add(sol.id);
                                            }));
                                  },
                          );
                        }),
                      ], // end reviewed

                      //  Seção: Solicitações pendentes (admin)
                      if (solicitations.isNotEmpty) ...[
                        if (incompletos.isNotEmpty) const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.rate_review_rounded,
                                color: AppColors.primary),
                            const SizedBox(width: 10),
                            const Text('Solicitações de Ponto',
                                style: AppTextStyles.h3),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${solicitations.length}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        ...solicitations.map((sol) {
                          final date = DateTime.tryParse(sol.diaId);
                          final dateLabel = date != null
                              ? DateFormat('dd/MM/yyyy', 'pt_BR').format(date)
                              : sol.diaId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit_note_rounded,
                                  size: 18, color: AppColors.primary),
                            ),
                            title: Text(sol.employeeName,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '$dateLabel • ${sol.items.length} alteração(ões)',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.primary)),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              _openSolicitationReview(context, sol);
                            },
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  //  Helpers para reviewed solicitations

  String _reviewedStatusLabel(SolicitationModel sol) {
    final allAccepted =
        sol.items.every((i) => i.status == SolicitationItemStatus.accepted);
    final allRejected =
        sol.items.every((i) => i.status == SolicitationItemStatus.rejected);
    if (allAccepted) return 'Totalmente aprovada';
    if (allRejected) return 'Totalmente rejeitada';
    return 'Parcialmente processada';
  }

  Color _reviewedStatusColor(SolicitationModel sol) {
    final allAccepted =
        sol.items.every((i) => i.status == SolicitationItemStatus.accepted);
    final allRejected =
        sol.items.every((i) => i.status == SolicitationItemStatus.rejected);
    if (allAccepted) return AppColors.success;
    if (allRejected) return AppColors.error;
    return AppColors.warning;
  }

  String _actionLabel(SolicitationAction action) {
    switch (action) {
      case SolicitationAction.add:
        return 'Adicionar';
      case SolicitationAction.edit:
        return 'Corrigir';
      case SolicitationAction.delete:
        return 'Remover';
    }
  }

  Widget _buildReviewedSolicitationTile(
    BuildContext context,
    SolicitationModel sol, {
    VoidCallback? onLocalDismiss,
    bool isPendingDismiss = false,
    bool isSeen = false,
  }) {
    final date = DateTime.tryParse(sol.diaId);
    final dateLabel = date != null
        ? DateFormat('dd/MM/yyyy', 'pt_BR').format(date)
        : sol.diaId;
    final statusLabel = _reviewedStatusLabel(sol);
    final statusColor = _reviewedStatusColor(sol);

    return Opacity(
        opacity: isSeen ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: isSeen ? 0.03 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: statusColor.withValues(alpha: isSeen ? 0.12 : 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: data + status badge
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 14, color: statusColor),
                  const SizedBox(width: 6),
                  Text(dateLabel,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(statusLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Items
              ...sol.items.map((item) {
                final accepted = item.status == SolicitationItemStatus.accepted;
                final itemColor =
                    accepted ? AppColors.success : AppColors.error;
                final icon = accepted
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined;
                final hora = DateFormat('HH:mm').format(item.horario);
                final tipoLabel = _tipoLabel(item.tipo);
                final actionLabel = _actionLabel(item.action);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: 14, color: itemColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '$actionLabel $tipoLabel $hora',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: itemColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Observação do admin
              if (sol.reason != null && sol.reason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.comment_outlined,
                          size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(sol.reason!,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            )),
                      ),
                    ],
                  ),
                ),
              ],
              // Botão / estado marcar como visto
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isSeen
                      // Já marcado como visto
                      ? Padding(
                          key: const ValueKey('seen'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 12,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.5)),
                              const SizedBox(width: 4),
                              Text('Visto',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textSecondary
                                        .withValues(alpha: 0.5),
                                  )),
                            ],
                          ),
                        )
                      // Botão ativo ou estado pendente ("Visto!")
                      : InkWell(
                          key: ValueKey(isPendingDismiss),
                          onTap: isPendingDismiss ? null : onLocalDismiss,
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPendingDismiss
                                      ? Icons.check_circle
                                      : Icons.check_circle_outline,
                                  size: 13,
                                  color: isPendingDismiss
                                      ? AppColors.success
                                      : AppColors.textSecondary
                                          .withValues(alpha: 0.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPendingDismiss
                                      ? 'Visto!'
                                      : 'Marcar como visto',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: isPendingDismiss
                                        ? AppColors.success
                                        : AppColors.textSecondary
                                            .withValues(alpha: 0.7),
                                    fontWeight: isPendingDismiss
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ));
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'Entrada';
      case 'pausa':
        return 'Pausa';
      case 'retorno':
        return 'Retorno';
      case 'saida':
        return 'Saída';
      default:
        return tipo;
    }
  }

  void _openSolicitationReview(
      BuildContext context, SolicitationModel sol) async {
    // Carrega eventos reais do dia antes de abrir o dialog
    List<Map<String, dynamic>> eventosAtuais = [];
    try {
      eventosAtuais =
          await SolicitationRepository().getEventosDoDia(sol.uid, sol.diaId);
    } catch (_) {}

    if (!context.mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => SolicitationReviewDialog(
        solicitation: sol,
        eventosAtuais: eventosAtuais,
      ),
    );

    if (result != null && context.mounted) {
      final itemStatuses =
          result['itemStatuses'] as List<SolicitationItemStatus>;
      final reason = result['reason'] as String?;
      context.read<SolicitationBloc>().add(
            ProcessSolicitationEvent(
              solicitationId: sol.id,
              itemStatuses: itemStatuses,
              reason: reason,
            ),
          );
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sair', style: AppTextStyles.h3),
        content:
            Text('Deseja realmente sair?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const LogoutRequested());
              Navigator.pushNamedAndRemoveUntil(
                  context, '/welcome', (r) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/app_icon/timeflow.png',
                width: 32,
                height: 32,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'TimeFlow',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        //  Notificação: incompletos (funcionários) + solicitações (admin)
        Builder(
          builder: (context) {
            final pontoState = context.watch<PontoTodayCubit>().state;
            final incompletos = _computeIncompletos(pontoState);

            // Descobre se é admin
            final isAdmin = _resolveIsAdmin(context);

            // Conta solicitações pendentes (admin) ou revisadas (funcionário)
            final solState = context.watch<SolicitationBloc>().state;
            int solCount = 0;
            List<SolicitationModel> reviewedSolicitations = [];

            if (isAdmin) {
              if (solState is SolicitationLoaded) {
                solCount = solState.pendingCount;
              } else if (solState is SolicitationActionSuccess) {
                solCount = solState.solicitations
                    .where((s) => s.status == SolicitationStatus.pending)
                    .length;
              }
            } else {
              if (solState is SolicitationLoaded) {
                reviewedSolicitations = solState.reviewedSolicitations;
              } else if (solState is SolicitationActionSuccess) {
                reviewedSolicitations = solState.reviewedSolicitations;
              }
              solCount =
                  reviewedSolicitations.where((s) => !s.seenByEmployee).length;
            }

            final totalCount = incompletos.length + solCount;
            final hasNotification = totalCount > 0;
            final badgeColor = isAdmin
                ? (solCount > 0 ? AppColors.primary : AppColors.warning)
                : (solCount > 0 ? AppColors.success : AppColors.warning);

            return Badge(
              isLabelVisible: hasNotification,
              label: Text('$totalCount'),
              offset: const Offset(-4, 4),
              backgroundColor: badgeColor,
              child: IconButton(
                icon: Icon(
                  hasNotification
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: hasNotification ? badgeColor : AppColors.primary,
                  size: 22,
                ),
                tooltip: !hasNotification
                    ? 'Sem pendências'
                    : '$totalCount pendência(s)',
                onPressed: () => _showNotificationsSheet(
                  context,
                  incompletos,
                  isAdmin: isAdmin,
                  reviewedSolicitations: reviewedSolicitations,
                ),
              ),
            );
          },
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.primary, size: 22),
          tooltip: 'Menu',
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          offset: const Offset(0, 50),
          onSelected: (value) {
            if (value == 'settings') {
              onSettingsTap?.call();
            } else if (value == 'solicitacoes') {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SolicitacoesPage()));
            } else if (value == 'logout') {
              _showLogoutDialog(context);
            }
          },
          itemBuilder: (context) => [
            if (showSettings)
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(children: [
                  const Icon(Icons.settings_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Text('Configurações',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textPrimary)),
                ]),
              ),
            if (showSettings) const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'solicitacoes',
              child: Row(children: [
                const Icon(Icons.assignment_turned_in_outlined,
                    color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Text('Solicitações', style: AppTextStyles.bodyMedium),
              ]),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(children: [
                const Icon(Icons.logout, color: AppColors.error, size: 20),
                const SizedBox(width: 12),
                Text('Sair',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.error)),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}
