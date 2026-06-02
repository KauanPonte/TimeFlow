import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/presence_badge.dart';
import 'profile_info_row.dart';

class ProfileInfoCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final int? workloadMinutes;
  final bool isAdmin;
  final String contractType;
  final List<String> workDays;
  final String projectType;
  final List<String> projects;
  final VoidCallback onEdit;
  final bool showPresence;
  final bool isOnline;

  const ProfileInfoCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.workloadMinutes,
    required this.isAdmin,
    required this.onEdit,
    this.contractType = '',
    this.workDays = const [],
    this.projectType = '',
    this.projects = const [],
    this.showPresence = false,
    this.isOnline = false,
  });

  String _formatWorkload(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins == 0
        ? '${hours}h'
        : '${hours}h${mins.toString().padLeft(2, '0')}';
  }

  bool get _isBolsista => contractType == 'Bolsista';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.primaryLight30 : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Informações',
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (showPresence) ...[
                PresenceBadge(
                  isOnline: isOnline,
                  compact: true,
                ),
                const SizedBox(width: 6),
              ],
              IconButton(
                onPressed: onEdit,
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                tooltip: 'Editar perfil',
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProfileInfoRow(
            icon: Icons.person_outline,
            label: 'Nome',
            value: name,
          ),
          _divider(),
          ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          _divider(),
          ProfileInfoRow(
            icon: Icons.badge_outlined,
            label: 'Cargo',
            value: role.isNotEmpty ? role : 'Sem cargo',
          ),
          _divider(),
          ProfileInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Carga horária diária',
            value: _formatWorkload(workloadMinutes),
          ),
          if (contractType.isNotEmpty) ...[
            _divider(),
            ProfileInfoRow(
              icon: Icons.description_outlined,
              label: 'Tipo de Contrato',
              value: contractType,
            ),
          ],
          if (_isBolsista && workDays.isNotEmpty) ...[
            _divider(),
            ProfileInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Dias de trabalho',
              value: workDays.join(', '),
            ),
          ],
          if (_isBolsista && projects.isNotEmpty) ...[
            _divider(),
            ProfileInfoRow(
              icon: Icons.work_outline,
              label: projects.length == 1 ? 'Projeto vinculado' : 'Projetos vinculados',
              value: projects.join('\n'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() => const Column(
        children: [
          SizedBox(height: 12),
          Divider(height: 1),
          SizedBox(height: 12),
        ],
      );
}
