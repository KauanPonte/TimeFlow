import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_palette.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'day_card_helpers.dart';
import 'pending_solicitations_section.dart';
import 'solicitation_button.dart';

/// Day card para dias sem eventos reais mas com solicitações pendentes.
class PendingOnlyDayCard extends StatelessWidget {
  final String diaId;
  final List<SolicitationModel> pendingSolicitations;
  final bool isAdmin;
  final bool disabled;
  final void Function(String)? onCancelSolicitation;
  final VoidCallback? onRequestSolicitation;
  final String? holidayName;

  const PendingOnlyDayCard({
    super.key,
    required this.diaId,
    required this.pendingSolicitations,
    this.isAdmin = false,
    this.disabled = false,
    this.onCancelSolicitation,
    this.onRequestSolicitation,
    this.holidayName,
  });

  @override
  Widget build(BuildContext context) {
    final count = pendingSolicitations.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: disabled ? context.palette.surface : context.palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: disabled
              ? context.palette.borderLight.withValues(alpha: 0.7)
              : context.palette.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: context.palette.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.85 : 1,
            child: ExpansionTile(
              initiallyExpanded: true,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.palette.borderLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today,
                    color: disabled
                        ? context.palette.textSecondary
                        : context.palette.textSecondary,
                    size: 20),
              ),
              title: Text(
                formatDate(diaId),
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: disabled
                      ? context.palette.textSecondary
                      : context.palette.textPrimary,
                ),
              ),
              subtitle: Row(
                children: [
                  Text(
                    'Sem registros',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.palette.textSecondary.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight20,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.warningLight30, width: 0.5),
                    ),
                    child: Text(
                      '$count pendencia${count != 1 ? 's' : ''}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                if (holidayName != null) buildHolidayBanner(holidayName!),
                PendingSolicitationsSection(
                  solicitations: pendingSolicitations,
                  isAdmin: isAdmin,
                  onCancel: onCancelSolicitation,
                ),
                if (onRequestSolicitation != null)
                  SolicitationButton(onTap: onRequestSolicitation!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
