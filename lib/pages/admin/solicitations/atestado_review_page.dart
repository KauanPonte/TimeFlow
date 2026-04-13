import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';

class AtestadoReviewPage extends StatefulWidget {
  const AtestadoReviewPage({super.key});

  @override
  State<AtestadoReviewPage> createState() => _AtestadoReviewPageState();
}

class _AtestadoReviewPageState extends State<AtestadoReviewPage> {
  @override
  void initState() {
    super.initState();
    context.read<AtestadoBloc>().add(
          const LoadAtestadosEvent(
            isAdmin: true,
            includeReviewed: true,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Atestados'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocConsumer<AtestadoBloc, AtestadoState>(
        listener: (context, state) {
          if (state is AtestadoActionSuccess) {
            CustomSnackbar.showSuccess(context, state.message);
          } else if (state is AtestadoError) {
            CustomSnackbar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is AtestadoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final atestados = switch (state) {
            AtestadoLoaded(:final atestados) => atestados,
            AtestadoActionSuccess(:final atestados) => atestados,
            AtestadoError(:final atestados) => atestados,
            _ => <AtestadoModel>[],
          };

          final pendingAtestados = atestados
              .where((a) => a.status == AtestadoStatus.pending)
              .toList();
          final reviewedAtestados = atestados
              .where((a) => a.status != AtestadoStatus.pending)
              .toList();

          if (atestados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum atestado para revisar',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<AtestadoBloc>().add(const LoadAtestadosEvent(
                    isAdmin: true,
                    includeReviewed: true,
                  ));
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (pendingAtestados.isNotEmpty) ...[
                  const Text('Pendentes', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  ...pendingAtestados.map(
                    (atestado) => _AtestadoReviewCard(atestado: atestado),
                  ),
                ],
                if (reviewedAtestados.isNotEmpty) ...[
                  if (pendingAtestados.isNotEmpty) const SizedBox(height: 16),
                  const Text('Já decididos', style: AppTextStyles.h3),
                  const SizedBox(height: 12),
                  ...reviewedAtestados.map(
                    (atestado) => _AtestadoReviewCard(
                      atestado: atestado,
                      showCurrentStatus: true,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AtestadoReviewCard extends StatelessWidget {
  final AtestadoModel atestado;
  final bool showCurrentStatus;

  const _AtestadoReviewCard({
    required this.atestado,
    this.showCurrentStatus = false,
  });

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
            child:
                const Text('Recusar', style: TextStyle(color: AppColors.error)),
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
    final isApproved = atestado.status == AtestadoStatus.approved;
    final statusColor = isApproved ? AppColors.success : AppColors.error;
    final statusLabel = isApproved ? 'Aprovado' : 'Recusado';
    final approveLabel = atestado.status == AtestadoStatus.pending
        ? 'Aprovar'
        : 'Aprovar novamente';
    final rejectLabel = atestado.status == AtestadoStatus.pending
        ? 'Recusar'
        : 'Recusar novamente';

    // Calcula dias cobertos
    final startDate = DateTime.parse(atestado.dataInicio);
    final endDate = DateTime.parse(atestado.dataFim);
    final dias = endDate.difference(startDate).inDays + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: nome + data envio
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  atestado.employeeName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                DateFormat('dd/MM/yy').format(atestado.createdAt),
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          if (showCurrentStatus) ...[
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Período
          Row(
            children: [
              const Icon(Icons.date_range_outlined,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                mesmodia ? inicio : '$inicio – $fim',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          const SizedBox(height: 6),

          // Arquivo
          Row(
            children: [
              const Icon(Icons.picture_as_pdf,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 6),
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
          const SizedBox(height: 14),

          // Botões
          Row(
            children: [
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
                  child: Text(rejectLabel),
                ),
              ),
              const SizedBox(width: 12),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(approveLabel),
                ),
              ),
            ],
          ),

          if (showCurrentStatus &&
              !isApproved &&
              atestado.reason != null &&
              atestado.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Motivo da recusa anterior',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              atestado.reason!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
