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
  final List<SolicitationModel> pendingSolicitations;
  final void Function(Map<String, dynamic>)? onEditEvento;
  final void Function(Map<String, dynamic>)? onDeleteEvento;
  final VoidCallback? onAddEvento;
  final VoidCallback? onBatchEdit;
  final VoidCallback? onRequestSolicitation;
  final void Function(String)? onCancelSolicitation;

  const FilledDayCard({
    super.key,
    required this.diaId,
    required this.eventos,
    this.isAdmin = false,
    this.pendingSolicitations = const [],
    this.onEditEvento,
    this.onDeleteEvento,
    this.onAddEvento,
    this.onBatchEdit,
    this.onRequestSolicitation,
    this.onCancelSolicitation,
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

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: incomplete ? AppColors.warningLight8 : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: incomplete ? AppColors.warningLight30 : AppColors.borderLight,
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
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: incomplete
                  ? AppColors.warningLight20
                  : AppColors.primaryLight10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              incomplete ? Icons.warning_amber_rounded : Icons.calendar_today,
              color: incomplete ? AppColors.warning : AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            formatDate(diaId),
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: _buildSubtitle(incomplete, hasPending, count),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 8),
            ..._buildEventoRows(),
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
        color: AppColors.warningLight20,
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

  List<Widget> _buildEventoRows() {
    return eventos.map((ev) {
      final tipo = (ev['tipo'] ?? '').toString();
      final at = ev['at'] as DateTime?;
      final color = colorForTipo(tipo);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
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
                  Text(
                    formatTime(at),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (isAdmin) ...[
              // Botões individuais de editar/excluir omitidos quando
              // a edição em lote está habilitada.
              if (onBatchEdit == null) ...[
                IconButton(
                  onPressed: () => onEditEvento?.call(ev),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.primary),
                  tooltip: 'Editar',
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  onPressed: () => onDeleteEvento?.call(ev),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: AppColors.error),
                  tooltip: 'Remover',
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ],
          ],
        ),
      );
    }).toList();
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
              color: AppColors.warningLight10,
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
