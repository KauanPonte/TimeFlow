import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_state.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';
import 'upload_atestado_page.dart';

class SolicitacoesPage extends StatefulWidget {
  const SolicitacoesPage({super.key});

  @override
  State<SolicitacoesPage> createState() => _SolicitacoesPageState();
}

class _SolicitacoesPageState extends State<SolicitacoesPage> {
  bool _isAdmin = false;
  List<AtestadoModel> _adminHistoryCache = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isAdmin = _resolveIsAdmin(context);
      context.read<AtestadoBloc>().add(
            LoadAtestadosEvent(
              isAdmin: _isAdmin,
              includeReviewed: _isAdmin,
            ),
          );
    });
  }

  bool _resolveIsAdmin(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AdminAuthenticated) return true;
    if (authState is UserAuthenticated) {
      final role = (authState.userData['role'] ?? '').toString();
      return role.toUpperCase().contains('ADM');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
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
                Icons.assignment_turned_in_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Solicitações',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
      body: BlocBuilder<AtestadoBloc, AtestadoState>(
        builder: (context, state) {
          final atestados = switch (state) {
            AtestadoLoaded(:final atestados) => atestados,
            AtestadoActionSuccess(:final atestados) => atestados,
            AtestadoError(:final atestados) => atestados,
            _ => <AtestadoModel>[],
          };

          var visibleAtestados = atestados;
          if (_isAdmin) {
            if (atestados.isNotEmpty) {
              final merged = {
                for (final item in _adminHistoryCache) item.id: item,
              };
              for (final item in atestados) {
                merged[item.id] = item;
              }
              _adminHistoryCache = merged.values.toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            }

            if (_adminHistoryCache.isNotEmpty) {
              visibleAtestados = _adminHistoryCache;
            }
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Botão enviar atestado
              _ActionCard(
                icon: Icons.cloud_upload_rounded,
                title: 'Enviar Novo Atestado',
                subtitle: 'Upload de arquivo PDF para abonos',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadAtestadoPage(),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<AtestadoBloc>().add(
                            LoadAtestadosEvent(
                              isAdmin: _isAdmin,
                              includeReviewed: _isAdmin,
                            ),
                          );
                    }
                  });
                },
              ),

              if (visibleAtestados.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Histórico de pedidos',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...visibleAtestados.map(
                  (a) => _AtestadoCard(
                    atestado: a,
                    isAdmin: _isAdmin,
                    onApprove: _isAdmin
                        ? () => context
                            .read<AtestadoBloc>()
                            .add(ApproveAtestadoEvent(a.id))
                        : null,
                    onReject: _isAdmin
                        ? (reason) => context.read<AtestadoBloc>().add(
                              RejectAtestadoEvent(
                                a.id,
                                reason: reason,
                              ),
                            )
                        : null,
                  ),
                ),
              ] else if (state is! AtestadoLoading) ...[
                const SizedBox(height: 60),
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48,
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma solicitação encontrada',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],

              if (state is AtestadoLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.border, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AtestadoCard extends StatelessWidget {
  final AtestadoModel atestado;
  final bool isAdmin;
  final VoidCallback? onApprove;
  final void Function(String? reason)? onReject;

  const _AtestadoCard({
    required this.atestado,
    this.isAdmin = false,
    this.onApprove,
    this.onReject,
  });

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AppDialogScaffold(
        title: 'Recusar Atestado',
        subtitle: 'Informe um motivo opcional antes de recusar este atestado.',
        icon: Icons.close,
        isDestructive: true,
        confirmLabel: 'Recusar',
        onConfirm: () {
          final raw = controller.text.trim();
          final reason = raw.isEmpty ? null : raw;
          Navigator.pop(context);
          onReject?.call(reason);
        },
        children: [
          AppDialogField(
            label: 'Motivo (opcional)',
            hintText: 'Digite uma observação breve',
            controller: controller,
            errorText: null,
            icon: Icons.comment_outlined,
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

    final (statusLabel, statusColor) = switch (atestado.status) {
      AtestadoStatus.pending => ('Em análise', Colors.orange),
      AtestadoStatus.approved => ('Aprovado', AppColors.success),
      AtestadoStatus.rejected => ('Recusado', AppColors.error),
    };

    final isResolved = atestado.status != AtestadoStatus.pending;
    final isApproved = atestado.status == AtestadoStatus.approved;
    final isRejected = atestado.status == AtestadoStatus.rejected;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResolved
              ? statusColor.withValues(alpha: 0.15)
              : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isApproved
                        ? Icons.check_circle_rounded
                        : isRejected
                            ? Icons.cancel_rounded
                            : Icons.access_time_filled_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mesmodia ? inicio : '$inicio – $fim',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              atestado.fileName,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel.toUpperCase(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Feedback de Resultado
          if (isRejected &&
              atestado.reason != null &&
              atestado.reason!.isNotEmpty)
            _StatusFeedback(
              color: AppColors.error,
              icon: Icons.info_outline_rounded,
              message: atestado.reason!,
              isItalic: true,
            )
          else if (isApproved)
            const _StatusFeedback(
              color: AppColors.success,
              icon: Icons.check_circle_outline_rounded,
              message: 'Dias marcados como facultativos no seu banco de horas.',
            ),

          if (isAdmin) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  if (atestado.status == AtestadoStatus.approved) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showRejectDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Recusar',
                        ),
                      ),
                    ),
                  ],
                  if (atestado.status == AtestadoStatus.pending)
                    const SizedBox(width: 12),
                  if (atestado.status == AtestadoStatus.rejected) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Aprovar',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusFeedback extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;
  final bool isItalic;

  const _StatusFeedback({
    required this.color,
    required this.icon,
    required this.message,
    this.isItalic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: color.withValues(alpha: 0.1))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: color,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
