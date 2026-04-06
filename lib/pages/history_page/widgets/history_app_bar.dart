import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'history_view_mode_icon_button.dart';

class HistoryAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subTitle;
  final Uint8List? profileBytes;
  final HistoryViewPreference viewPreference;
  final ValueChanged<HistoryViewPreference> onViewChanged;

  const HistoryAppBar({
    super.key,
    required this.title,
    this.subTitle,
    this.profileBytes,
    required this.viewPreference,
    required this.onViewChanged,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: profileBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      profileBytes!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  )
                : const Icon(Icons.history, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subTitle != null)
                  Text(
                    subTitle!,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        HistoryViewModeIconButton(
          icon: Icons.view_agenda_outlined,
          selected: viewPreference == HistoryViewPreference.list,
          tooltip: 'Visualização em lista',
          onTap: () => onViewChanged(HistoryViewPreference.list),
        ),
        HistoryViewModeIconButton(
          icon: Icons.calendar_month_outlined,
          selected: viewPreference == HistoryViewPreference.calendar,
          tooltip: 'Visualização em calendário',
          onTap: () => onViewChanged(HistoryViewPreference.calendar),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
