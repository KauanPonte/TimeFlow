import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/auth/auth_event.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import '../pages/solicitacoes_page/solicitacoes_page.dart';

/// AppBar padrão para as telas principais (Painel, Meu Ponto, Perfil).
/// Logo + subtítulo configurável + menu com "Sair" (e "Configurações" opcional).
class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String subtitle;
  final bool showSettings;
  final VoidCallback? onSettingsTap;

  const MainAppBar({
    super.key,
    required this.subtitle,
    this.showSettings = false,
    this.onSettingsTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

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
