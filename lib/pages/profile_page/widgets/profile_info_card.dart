import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'profile_info_row.dart';

class ProfileInfoCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final int? workloadMinutes;
  final bool isAdmin;
  final VoidCallback onEdit;

  const ProfileInfoCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.workloadMinutes,
    required this.isAdmin,
    required this.onEdit,
  });

  String _formatWorkload(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins == 0
        ? '${hours}h'
        : '${hours}h${mins.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
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
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ProfileInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email,
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ProfileInfoRow(
            icon: Icons.badge_outlined,
            label: 'Cargo',
            value: role.isNotEmpty ? role : 'Sem cargo',
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          ProfileInfoRow(
            icon: Icons.schedule_outlined,
            label: 'Carga horária diária',
            value: _formatWorkload(workloadMinutes),
          ),
        ],
      ),
    );
  }
}
