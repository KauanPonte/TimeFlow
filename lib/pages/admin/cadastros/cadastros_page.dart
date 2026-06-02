import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import '../users_management/users_management_mode.dart';
import '../users_management/users_management_page.dart';
import '../create_user/create_user_page.dart';

class CadastrosPage extends StatelessWidget {
  const CadastrosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface, size: 20),
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
                Icons.person_add_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Cadastros',
              style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selecione uma opção',
              style: AppTextStyles.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _CadastroCard(
              icon: Icons.person_add,
              title: 'Usuários',
              description: 'Cadastrar novo usuário',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateUserPage(),
                  ),
                );
                if (result == true && context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
            const SizedBox(height: 12),
            _CadastroCard(
              icon: Icons.people_outline,
              title: 'Funcionários',
              description: 'Gerenciar funcionários cadastrados',
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UsersManagementPage(
                      mode: UsersManagementMode.employees,
                    ),
                  ),
                );
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CadastroCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _CadastroCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.primaryLight30 : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.68),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
