import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/pages/history_page/widgets/card/widgets/day_card_helpers.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/presence_badge.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isCurrentUser;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final bool showActions;
  final bool showDeleteAction;

  const UserCard({
    super.key,
    required this.user,
    this.isCurrentUser = false,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.showActions = true,
    this.showDeleteAction = true,
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(user['role']);
    final Uint8List? profileBytes =
        _decodeProfileImage(user['profileImage'] ?? '');
    final bool didPunchToday = user['didPunchToday'] == true;
    final bool isOnlineToday = user['isOnlineToday'] == true;
    final String todayWorkMode =
        (user['todayWorkMode'] ?? '').toString().toLowerCase();
    final IconData punchIcon = didPunchToday
        ? iconForWorkMode(todayWorkMode)
        : Icons.watch_later_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.primaryLight10 : colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primaryLight20
              : (isDark ? AppColors.primaryLight30 : AppColors.borderLight),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap ?? () {},
              child: Padding(
                padding: EdgeInsets.only(
                    left: isCurrentUser ? 0 : 16,
                    top: 16,
                    bottom: 16,
                    right: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isCurrentUser)
                      Container(
                        width: 4,
                        height: 88,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                        ),
                      ),
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
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user['name'],
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (didPunchToday) ...[
                                const SizedBox(width: 8),
                                PresenceBadge(
                                  isOnline: isOnlineToday,
                                  compact: true,
                                ),
                              ],
                              if (isCurrentUser)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8,
                                    right: 12,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight10,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Você',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.email_outlined,
                                size: 14,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.68),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  user['email'],
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: colorScheme.onSurface
                                        .withValues(alpha: 0.68),
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
                    if (showActions)
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: colorScheme.onSurface.withValues(alpha: 0.12),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            size: 20,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.68),
                          ),
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                          ),
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: colorScheme.surface,
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[
                              PopupMenuItem(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.manage_accounts_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Editar',
                                      style: TextStyle(
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Future.delayed(Duration.zero, onEdit);
                                },
                              ),
                            ];

                            if (showDeleteAction && !isCurrentUser) {
                              items.add(const PopupMenuDivider(height: 1));
                              items.add(
                                PopupMenuItem(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.errorLight10,
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.delete_outlined,
                                          size: 16,
                                          color: AppColors.error,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Excluir',
                                          style: TextStyle(
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  onTap: () {
                                    Future.delayed(Duration.zero, onDelete);
                                  },
                                ),
                              );
                            }

                            return items;
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (user['didPunchToday'] != null)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: didPunchToday
                      ? (todayWorkMode == 'presencial'
                          ? AppColors.successLight10
                          : AppColors.primaryLight10)
                      : const Color(0x14757575),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  punchIcon,
                  size: 18,
                  color: didPunchToday
                      ? (todayWorkMode == 'presencial'
                          ? AppColors.success
                          : AppColors.primary)
                      : colorScheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
