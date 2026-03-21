import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_event.dart';
import 'package:flutter_application_appdeponto/blocs/atestado/atestado_state.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'upload_atestado_page.dart';

class SolicitacoesPage extends StatefulWidget {
  const SolicitacoesPage({super.key});

  @override
  State<SolicitacoesPage> createState() => _SolicitacoesPageState();
}

class _SolicitacoesPageState extends State<SolicitacoesPage> {
  @override
  void initState() {
    super.initState();
    // Sempre recarrega os atestados do usuário ao abrir a página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AtestadoBloc>().add(const LoadAtestadosEvent(isAdmin: false));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        title: const Text('Solicitações'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: BlocBuilder<AtestadoBloc, AtestadoState>(
        builder: (context, state) {
          final atestados = switch (state) {
            AtestadoLoaded(:final atestados) => atestados,
            AtestadoActionSuccess(:final atestados) => atestados,
            AtestadoError(:final atestados) => atestados,
            _ => <AtestadoModel>[],
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Botão enviar atestado
              _ActionCard(
                icon: Icons.cloud_upload_outlined,
                title: 'Enviar Atestado',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UploadAtestadoPage(),
                    ),
                  ).then((_) {
                    // Recarrega lista ao voltar
                    if (context.mounted) {
                      context
                          .read<AtestadoBloc>()
                          .add(const LoadAtestadosEvent());
                    }
                  });
                },
              ),

              if (atestados.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Meus Atestados',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...atestados.map((a) => _AtestadoCard(atestado: a)),
              ],

              if (state is AtestadoLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: CircularProgressIndicator()),
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
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
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

  const _AtestadoCard({required this.atestado});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final inicio = fmt.format(DateTime.parse(atestado.dataInicio));
    final fim = fmt.format(DateTime.parse(atestado.dataFim));
    final mesmodia = atestado.dataInicio == atestado.dataFim;

    final (statusLabel, statusColor) = switch (atestado.status) {
      AtestadoStatus.pending => ('Pendente', Colors.orange),
      AtestadoStatus.approved => ('Aprovado', Colors.green),
      AtestadoStatus.rejected => ('Recusado', AppColors.error),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mesmodia ? inicio : '$inicio – $fim',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  atestado.fileName,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: AppTextStyles.bodySmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
