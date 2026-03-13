import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  bool _isAdmin(String role) {
    return role.toUpperCase().contains('ADM');
  }

  Color _getRoleColor(String role) {
    return _isAdmin(role) ? AppColors.error : AppColors.primary;
  }

  List<Color> _getRoleGradientColors(String role) {
    if (_isAdmin(role)) {
      return [AppColors.errorLight20, AppColors.errorLight10];
    }
    return [AppColors.primaryLight20, AppColors.primaryLight10];
  }

  Uint8List? _decodeProfileImage(String data) {
    if (data.isEmpty) return null;
    try {
      final cleaned = data.contains(',') ? data.split(',').last : data;
      return base64Decode(cleaned);
    } catch (_) {
      return null;
    }
  }

  Color _getRoleBadgeColor(String role) {
    return _isAdmin(role) ? AppColors.errorLight10 : AppColors.primaryLight10;
  }

  Color _getRoleBorderColor(String role) {
    return _isAdmin(role) ? AppColors.errorLight20 : AppColors.primaryLight30;
  }

  @override
  Widget build(BuildContext context) {
    final roleColor = _getRoleColor(user['role']);
    final Uint8List? profileBytes =
        _decodeProfileImage(user['profileImage'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap ?? () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: profileBytes == null
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _getRoleGradientColors(user['role']),
                          )
                        : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: profileBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(
                            profileBytes,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            user['name'][0].toUpperCase(),
                            style: AppTextStyles.h2.copyWith(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.email_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user['email'],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleBadgeColor(user['role']),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getRoleBorderColor(user['role']),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 14,
                              color: roleColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              user['role'],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: roleColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Actions Menu
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.manage_accounts_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, onEdit);
                      },
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      child: const Row(
                        children: [
                          Icon(
                            Icons.delete,
                            size: 16,
                            color: AppColors.error,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Excluir',
                            style: TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                      onTap: () {
                        Future.delayed(Duration.zero, onDelete);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
