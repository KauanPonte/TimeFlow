import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';

class MonthSelector extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const MonthSelector({
    super.key,
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
  });

  bool get _canGoNext {
    final now = ServerTimeService.nowBrazilUtc();
    return currentMonth.year < now.year ||
        (currentMonth.year == now.year && currentMonth.month < now.month);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formatter = DateFormat("MMMM 'de' yyyy", 'pt_BR');
    final label = formatter.format(currentMonth);
    final displayLabel = label[0].toUpperCase() + label.substring(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.primaryLight30 : AppColors.borderLight,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: Icon(
              Icons.chevron_left,
              color: isDark ? colorScheme.onSurface : AppColors.primary,
            ),
            tooltip: 'Mês anterior',
          ),
          Text(
            displayLabel,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          IconButton(
            onPressed: _canGoNext ? onNext : null,
            icon: Icon(
              Icons.chevron_right,
              color: _canGoNext
                  ? (isDark ? colorScheme.onSurface : colorScheme.primary)
                  : colorScheme.onSurface.withValues(alpha: 0.28),
            ),
            tooltip: 'Próximo mês',
          ),
        ],
      ),
    );
  }
}
