import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';

class PresenceBadge extends StatelessWidget {
  final bool isOnline;
  final bool compact;

  const PresenceBadge({
    super.key,
    required this.isOnline,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isOnline ? AppColors.success : AppColors.warning;
    final label = isOnline ? 'Online' : 'Inativo';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.38)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style:
                (compact ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium)
                    .copyWith(
              color: isDark ? colorScheme.onSurface : color,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
