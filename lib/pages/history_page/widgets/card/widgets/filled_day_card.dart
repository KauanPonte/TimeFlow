import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'day_card_helpers.dart';
import 'pending_solicitations_section.dart';
import 'solicitation_button.dart';

/// Day card completo para dias com eventos registrados.
class FilledDayCard extends StatelessWidget {
  final String diaId;
  final List<Map<String, dynamic>> eventos;
  final bool isAdmin;
  final bool disabled;
  final List<SolicitationModel> pendingSolicitations;
  final void Function(Map<String, dynamic>)? onEditEvento;
  final void Function(Map<String, dynamic>)? onDeleteEvento;
  final VoidCallback? onAddEvento;
  final VoidCallback? onBatchEdit;
  final VoidCallback? onRequestSolicitation;
  final void Function(String)? onCancelSolicitation;
  final String? holidayName;

  const FilledDayCard({
    super.key,
    required this.diaId,
    required this.eventos,
    this.isAdmin = false,
    this.disabled = false,
    this.pendingSolicitations = const [],
    this.onEditEvento,
    this.onDeleteEvento,
    this.onAddEvento,
    this.onBatchEdit,
    this.onRequestSolicitation,
    this.onCancelSolicitation,
    this.holidayName,
  });

  bool get _incomplete => isIncomplete(
        eventos,
        isToday: _isToday,
        isFuture: false,
      );

  bool get _isToday {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return diaId == today;
  }

  @override
  Widget build(BuildContext context) {
    final incomplete = _incomplete;
    final hasPending = pendingSolicitations.isNotEmpty;
    final count = pendingSolicitations.length;
    final disabledStyle = disabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: disabledStyle ? AppColors.surface : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: disabledStyle
              ? AppColors.surface
              : (incomplete
                  ? AppColors.warning.withValues(alpha: 0.05)
                  : AppColors.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabledStyle
                ? AppColors.borderLight.withValues(alpha: 0.7)
                : (incomplete
                    ? AppColors.warningLight30
                    : AppColors.borderLight),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: IgnorePointer(
            ignoring: disabledStyle,
            child: Opacity(
              opacity: disabledStyle ? 0.85 : 1,
              child: ExpansionTile(
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: disabledStyle
                        ? AppColors.borderLight.withValues(alpha: 0.4)
                        : (incomplete
                            ? AppColors.warning.withValues(alpha: 0.05)
                            : AppColors.primaryLight10),
                    border: Border.all(
                      color: disabledStyle
                          ? AppColors.borderLight.withValues(alpha: 0.7)
                          : (incomplete
                              ? AppColors.warningLight30
                              : AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    incomplete
                        ? Icons.warning_amber_rounded
                        : Icons.calendar_today,
                    color: disabledStyle
                        ? AppColors.textSecondary
                        : (incomplete ? AppColors.warning : AppColors.primary),
                    size: 20,
                  ),
                ),
                title: Text(
                  formatDate(diaId),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: disabledStyle
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
                subtitle: _buildSubtitle(incomplete, hasPending, count),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  if (holidayName != null) buildHolidayBanner(holidayName!),
                  ..._buildEventoRows(incomplete),
                  if (incomplete) _buildIncompleteWarning(),
                  if (isAdmin && onBatchEdit != null) _buildBatchEditButton(),
                  if (!isAdmin && onAddEvento != null) _buildAddButton(),
                  if (hasPending) ...[
                    PendingSolicitationsSection(
                      solicitations: pendingSolicitations,
                      isAdmin: isAdmin,
                      onCancel: onCancelSolicitation,
                    ),
                  ],
                  if (!isAdmin && onRequestSolicitation != null)
                    SolicitationButton(onTap: onRequestSolicitation!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Sub-builders

  Widget _buildSubtitle(bool incomplete, bool hasPending, int count) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined,
                size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              computeWorked(eventos),
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight10,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${eventos.length} registro${eventos.length != 1 ? 's' : ''}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        if (incomplete)
          _badge(
            Icons.warning_amber_rounded,
            'Incompleto',
            AppColors.warning,
          ),
        if (hasPending)
          _badge(
            null,
            '$count pendencia${count != 1 ? 's' : ''}',
            AppColors.warning,
          ),
      ],
    );
  }

  Widget _badge(IconData? icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warningLight30, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEventoRows(bool incomplete) {
    final orderedEventos = List<Map<String, dynamic>>.from(eventos)
      ..sort((a, b) {
        final atA = a['at'] as DateTime?;
        final atB = b['at'] as DateTime?;
        if (atA == null && atB == null) return 0;
        if (atA == null) return 1;
        if (atB == null) return -1;
        return atA.compareTo(atB);
      });

    final cycles = <List<Map<String, dynamic>>>[];
    List<Map<String, dynamic>> currentCycle = [];

    for (var ev in orderedEventos) {
      final tipo = (ev['tipo'] ?? '').toString();

      if (tipo == 'entrada') {
        if (currentCycle.isNotEmpty) {
          cycles.add(currentCycle);
        }
        currentCycle = [ev];
      } else {
        currentCycle.add(ev);
        if (tipo == 'saida') {
          cycles.add(currentCycle);
          currentCycle = [];
        }
      }
    }
    if (currentCycle.isNotEmpty) {
      cycles.add(currentCycle);
    }

    final groups = <_ModeGroup>[];

    for (var cycle in cycles) {
      bool hasPresencial = false;
      bool hasRemoto = false;

      for (var ev in cycle) {
        final rawMode = (ev['workMode'] ?? '').toString();
        if (rawMode == 'presencial') {
          hasPresencial = true;
        } else if (rawMode == 'remoto') {
          hasRemoto = true;
        }
      }

      final cycleMode =
          hasPresencial ? 'presencial' : (hasRemoto ? 'remoto' : 'outro');

      for (var ev in cycle) {
        if (groups.isEmpty || groups.last.mode != cycleMode) {
          groups.add(_ModeGroup(mode: cycleMode, events: [ev]));
        } else {
          groups.last.events.add(ev);
        }
      }
    }

    final widgets = <Widget>[];
    final showHeaders = groups.isNotEmpty;

    for (final group in groups) {
      if (showHeaders) {
        widgets.add(_buildModeHeader(group.mode));
      }
      widgets.addAll([
        Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                    color: incomplete
                        ? AppColors.warning.withValues(alpha: 0.45)
                        : AppColors.borderLight,
                    width: 3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child:
                  Column(children: group.events.map(_buildEventoRow).toList()),
            ))
      ]);
    }

    return widgets;
  }

  Widget _buildModeHeader(String workMode) {
    final color = _colorForWorkMode(workMode);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Icon(iconForWorkMode(workMode), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            labelForWorkMode(workMode),
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorForWorkMode(String workMode) {
    switch (workMode) {
      case 'presencial':
        return AppColors.primary;
      case 'remoto':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildEventoRow(Map<String, dynamic> ev) {
    final tipo = (ev['tipo'] ?? '').toString();
    final at = ev['at'] as DateTime?;
    final origin = (ev['origin'] ?? 'registrado').toString();
    final color = colorForTipo(tipo);
    final originColor = colorForOrigin(origin);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Icon(iconForTipo(tipo), size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelForTipo(tipo),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatTime(at),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: originColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: originColor.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        labelForOrigin(origin),
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: originColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isAdmin) ...[
            if (onBatchEdit == null) ...[
              IconButton(
                onPressed: () => onEditEvento?.call(ev),
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.primary),
                tooltip: 'Editar',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                onPressed: () => onDeleteEvento?.call(ev),
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.error),
                tooltip: 'Remover',
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildIncompleteWarning() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warningLight30, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    motivoIncompleto(eventos),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildBatchEditButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: onBatchEdit,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primaryLight10.withValues(alpha: 0.3),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_note_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Editar dia',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: InkWell(
        onTap: onAddEvento,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.primaryLight10.withValues(alpha: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'Adicionar ponto',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeGroup {
  final String mode;
  final List<Map<String, dynamic>> events;

  _ModeGroup({required this.mode, required this.events});
}
