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
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

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

  void _showNotificationsSheet(
    BuildContext context,
    List<MapEntry<String, Map<String, String>>> incompletos,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
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
                        color: AppColors.warning.withValues(alpha: 0.15),
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
                  final motivo = (m['pausa'] != null && m['retorno'] == null)
                      ? 'Pausa sem retorno'
                      : 'Entrada sem saída';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
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

                        String roleFromArgs =
                            (currentArgs['employeeRole'] ?? '').toString();
                        String chosenRole = roleFromArgs;
                        final profileState = context.read<ProfileBloc>().state;
                        if (profileState is ProfileLoaded &&
                            profileState.role.isNotEmpty) {
                          chosenRole = profileState.role;
                        }

                        // Fallback: check AuthBloc state for admin indicator
                        if (chosenRole.isEmpty) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AdminAuthenticated) {
                            chosenRole = (authState.userData['role'] ?? 'ADM')
                                .toString();
                          } else if (authState is UserAuthenticated) {
                            chosenRole =
                                (authState.userData['role'] ?? '').toString();
                          }
                        }

                        final isAdminUser =
                            chosenRole.toUpperCase().contains('ADM');

                        final navArgs = <String, dynamic>{
                          ...currentArgs,
                          'employeeRole': chosenRole,
                          'initialHistoryDate': date.toIso8601String(),
                        };

                        final route = isAdminUser ? '/home/employee' : '/home';
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
              ],
            ),
          ),
        );
      },
    );
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
        BlocBuilder<PontoTodayCubit, PontoTodayState>(
          builder: (context, pontoState) {
            final incompletos = _computeIncompletos(pontoState);
            return Badge(
              isLabelVisible: incompletos.isNotEmpty,
              label: Text('${incompletos.length}'),
              offset: const Offset(-4, 4),
              backgroundColor: AppColors.warning,
              child: IconButton(
                icon: Icon(
                  incompletos.isNotEmpty
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: incompletos.isNotEmpty
                      ? AppColors.warning
                      : AppColors.primary,
                  size: 22,
                ),
                tooltip: incompletos.isEmpty
                    ? 'Sem pendências'
                    : '${incompletos.length} registro(s) incompleto(s)',
                onPressed: incompletos.isEmpty
                    ? null
                    : () => _showNotificationsSheet(context, incompletos),
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
