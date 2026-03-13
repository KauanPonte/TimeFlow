import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SettingsAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
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
            child:
                const Icon(Icons.settings, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'Configuracoes',
            style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}
