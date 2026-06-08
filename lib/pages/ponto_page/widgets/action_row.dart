import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';

class ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accentColor;
  final bool done;
  final bool isNext;
  final bool isLast;
  final bool optional;
  final String? time;
  final bool isRegistering;
  final VoidCallback onTap;
  // Quando true, indica que este tipo já tem uma solicitação pendente de aprovação.
  final bool isPending;

  const ActionRow({
    super.key,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.done,
    required this.isNext,
    required this.isLast,
    required this.onTap,
    required this.isRegistering,
    this.optional = false,
    this.time,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bool enabled = isNext && !isRegistering && !isPending;
    final bool skipped = optional && !done && !isNext && !isPending;
    final inactiveTextColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.72 : 0.68,
    );
    final supportingTextColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.66 : 0.62,
    );
    final mutedTextColor = colorScheme.onSurface.withValues(
      alpha: isDark ? 0.52 : 0.50,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.vertical(
            bottom: isLast ? const Radius.circular(16) : Radius.zero,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: done
                        ? accentColor.withValues(alpha: 0.12)
                        : isNext
                            ? accentColor
                            : isDark
                                ? AppColors.darkSurfaceAlt
                                : AppColors.bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : icon,
                    color: done
                        ? accentColor
                        : isNext
                            ? Colors.white
                            : inactiveTextColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Label + hora
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            label,
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.w600,
                              color: done
                                  ? accentColor
                                  : isNext
                                      ? colorScheme.onSurface
                                      : inactiveTextColor,
                            ),
                          ),
                          if (optional && !done) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primaryLight20
                                    : AppColors.borderLight,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'opcional',
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontSize: 10,
                                  color: isDark
                                      ? colorScheme.onSurface
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (time != null)
                        Text(
                          'Registrado às $time',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: accentColor, fontSize: 12),
                        )
                      else if (isPending)
                        Text(
                          'Solicitação pendente de aprovação',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.warning,
                            fontSize: 12,
                          ),
                        )
                      else if (isNext)
                        Text(
                          'Toque para registrar',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: supportingTextColor,
                            fontSize: 12,
                          ),
                        )
                      else if (skipped)
                        Text(
                          'Não utilizada',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 12,
                            color: mutedTextColor,
                          ),
                        ),
                    ],
                  ),
                ),
                // Indicador direita
                if (isPending)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.hourglass_top_rounded,
                            size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          'Pendente',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isNext && !isRegistering)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark ? colorScheme.onSurface : accentColor,
                  )
                else if (done)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      time ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 16,
            color: isDark ? AppColors.primaryLight30 : AppColors.borderLight,
          ),
      ],
    );
  }
}
