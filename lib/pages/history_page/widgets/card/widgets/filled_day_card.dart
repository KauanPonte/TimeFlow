import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_palette.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'day_card_helpers.dart';
import 'pending_solicitations_section.dart';
import 'solicitation_button.dart';

class FilledDayCard extends StatefulWidget {
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
  final VoidCallback? onOpenDayActions;
  final AbonoModel? abono;
  final VoidCallback? onApplyAbono;
  final VoidCallback? onDeleteAbono;

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
    this.onOpenDayActions,
    this.abono,
    this.onApplyAbono,
    this.onDeleteAbono,
  });

  @override
  State<FilledDayCard> createState() => _FilledDayCardState();
}

class _FilledDayCardState extends State<FilledDayCard> {
  bool _isExpanded = false;

  bool get _incomplete => isIncomplete(
        widget.eventos,
        isToday: _isToday,
        isFuture: false,
      );

  bool get _isToday {
    final now = ServerTimeService.nowBrazilUtc();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return widget.diaId == today;
  }

  @override
  Widget build(BuildContext context) {
    final incomplete = _incomplete;
    final hasPending = widget.pendingSolicitations.isNotEmpty;
    final count = widget.pendingSolicitations.length;
    final disabledStyle = widget.disabled;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: disabledStyle
              ? context.palette.surface
              : (incomplete
                  ? AppColors.warning.withValues(alpha: 0.05)
                  : context.palette.surface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: disabledStyle
                ? context.palette.borderLight.withValues(alpha: 0.7)
                : (incomplete
                    ? AppColors.warningLight30
                    : context.palette.borderLight),
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
            ignoring: disabledStyle,
            child: Opacity(
              opacity: disabledStyle ? 0.85 : 1,
              child: ExpansionTile(
                onExpansionChanged: (v) => setState(() => _isExpanded = v),
                controlAffinity: ListTileControlAffinity.trailing,
                tilePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding:
                    const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: disabledStyle
                        ? context.palette.borderLight.withValues(alpha: 0.4)
                        : (incomplete
                            ? AppColors.warning.withValues(alpha: 0.05)
                            : AppColors.primaryLight10),
                    border: Border.all(
                      color: disabledStyle
                          ? context.palette.borderLight.withValues(alpha: 0.7)
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
                        ? context.palette.textSecondary
                        : (incomplete ? AppColors.warning : AppColors.primary),
                    size: 20,
                  ),
                ),
                title: Text(
                  formatDate(widget.diaId),
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: disabledStyle
                        ? context.palette.textSecondary
                        : context.palette.textPrimary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onOpenDayActions != null)
                      GestureDetector(
                        onTap: widget.onOpenDayActions,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.expand_more,
                        color: context.palette.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                subtitle: _buildSubtitle(incomplete, hasPending, count),
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  if (widget.abono != null)
                    _buildAbonoRetornoCard(),
                  if (widget.holidayName != null)
                    buildHolidayBanner(widget.holidayName!),
                  ..._buildEventoRows(incomplete),
                  if (incomplete) _buildIncompleteWarning(),
                  if (widget.isAdmin &&
                      widget.onBatchEdit != null &&
                      widget.onOpenDayActions == null)
                    _buildBatchEditButton(),
                  if (!widget.isAdmin && widget.onAddEvento != null)
                    _buildAddButton(),
                  if (hasPending)
                    PendingSolicitationsSection(
                      solicitations: widget.pendingSolicitations,
                      isAdmin: widget.isAdmin,
                      onCancel: widget.onCancelSolicitation,
                    ),
                  if (!widget.isAdmin && widget.onRequestSolicitation != null)
                    SolicitationButton(onTap: widget.onRequestSolicitation!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(bool incomplete, bool hasPending, int count) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined,
                size: 14, color: context.palette.textSecondary),
            const SizedBox(width: 4),
            Text(
              _computeWorkedWithAbono(),
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.palette.textSecondary),
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
            '${widget.eventos.length} registro${widget.eventos.length != 1 ? 's' : ''}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
        if (incomplete)
          _badge(Icons.warning_amber_rounded, 'Incompleto', AppColors.warning),
        if (hasPending)
          _badge(null, '$count pendencia${count != 1 ? 's' : ''}',
              AppColors.warning),
        // Badge de abono pendente
        if (widget.abono != null &&
            widget.abono!.status == AbonoStatus.pending)
          _badge(
              Icons.hourglass_top_rounded, 'Abono pendente', AppColors.warning),
        // Badge de abono aprovado: mostra as horas compensadas
        if (widget.abono != null &&
            widget.abono!.status == AbonoStatus.approved &&
            widget.abono!.abonoMinutes > 0)
          _abonoAprovadoBadge(widget.abono!.abonoMinutes),
      ],
    );
  }

  Widget _abonoAprovadoBadge(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final label = h > 0 && m > 0
        ? '${h}h ${m}min abonada${minutes != 1 ? 's' : ''}'
        : h > 0
            ? '${h}h abonada${h != 1 ? 's' : ''}'
            : '${m}min abonado${m != 1 ? 's' : ''}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.success.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_outlined,
              size: 11, color: AppColors.success),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAbono() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover abono'),
        content: const Text(
            'Deseja remover este pedido de abono? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteAbono?.call();
            },
            child: const Text('Remover',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
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
    final orderedEventos = List<Map<String, dynamic>>.from(widget.eventos)
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
        if (currentCycle.isNotEmpty) cycles.add(currentCycle);
        currentCycle = [ev];
      } else {
        currentCycle.add(ev);
        if (tipo == 'saida') {
          cycles.add(currentCycle);
          currentCycle = [];
        }
      }
    }
    if (currentCycle.isNotEmpty) cycles.add(currentCycle);

    final groups = <_ModeGroup>[];

    for (var cycle in cycles) {
      bool hasPresencial = false;
      bool hasRemoto = false;

      for (var ev in cycle) {
        final rawMode = (ev['workMode'] ?? '').toString();
        if (rawMode == 'presencial') hasPresencial = true;
        if (rawMode == 'remoto') hasRemoto = true;
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

    for (final group in groups) {
      widgets.add(_buildModeHeader(group.mode));
      widgets.add(
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: incomplete
                    ? AppColors.warning.withValues(alpha: 0.45)
                    : context.palette.borderLight,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 8, top: 8),
            child: Column(
              children: group.events.map(_buildEventoRow).toList(),
            ),
          ),
        ),
      );
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
      case 'remoto':
        return AppColors.primary;
      default:
        return context.palette.textSecondary;
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
                    color: context.palette.textPrimary,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatTime(at),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.palette.textSecondary),
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
          if (widget.isAdmin && widget.onBatchEdit == null) ...[
            IconButton(
              onPressed: () => widget.onEditEvento?.call(ev),
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.primary),
              tooltip: 'Editar',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            IconButton(
              onPressed: () => widget.onDeleteEvento?.call(ev),
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppColors.error),
              tooltip: 'Remover',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ],
      ),
    );
  }

  String _computeWorkedWithAbono() {
    final base = computeWorked(widget.eventos);
    final abonoMin = widget.abono?.status == AbonoStatus.approved
        ? widget.abono!.abonoMinutes
        : 0;
    if (abonoMin <= 0) return base;

    final parts = base.split('h ');
    int totalMin = 0;
    if (parts.length == 2) {
      totalMin = (int.tryParse(parts[0]) ?? 0) * 60 +
          (int.tryParse(parts[1].replaceAll('m', '')) ?? 0);
    }
    totalMin += abonoMin;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    return '${h}h ${m}m';
  }

  Widget _buildAbonoRetornoCard() {
    final a = widget.abono!;
    final isPending = a.status == AbonoStatus.pending;
    final isApproved = a.status == AbonoStatus.approved;
    final color = isPending
        ? AppColors.warning
        : (isApproved ? AppColors.success : AppColors.error);

    String statusLabel;
    String descLabel;
    if (isPending) {
      statusLabel = 'Pendente';
      descLabel = 'Abono pendente';
    } else if (isApproved) {
      statusLabel = 'Aprovado';
      if (a.isFullDay) {
        descLabel = 'Abono dia inteiro';
      } else if (a.abonoMinutes > 0) {
        final h = a.abonoMinutes ~/ 60;
        final m = a.abonoMinutes % 60;
        descLabel = h > 0 && m > 0
            ? '${h}h ${m}min abonados'
            : h > 0
                ? '${h}h abonados'
                : '${m}min abonados';
      } else {
        descLabel = 'Abono aprovado';
      }
    } else {
      statusLabel = 'Recusado';
      descLabel = 'Abono recusado';
    }

    return GestureDetector(
      onTap: () => _showAbonoDetail(a),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  a.observacao.isNotEmpty ? a.observacao : descLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              if (widget.onDeleteAbono != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: _confirmDeleteAbono,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.delete_outline,
                        size: 14, color: AppColors.error),
                  ),
                ),
              ],
            ],
          ),
          if (a.dataInicio != null && a.dataFim != null) ...[
            const SizedBox(height: 6),
            Builder(builder: (_) {
              final p1 = a.dataInicio!.split(':');
              final p2 = a.dataFim!.split(':');
              final startMin =
                  int.tryParse(p1[0]) != null && p1.length == 2
                      ? int.parse(p1[0]) * 60 + int.parse(p1[1])
                      : 0;
              final endMin =
                  int.tryParse(p2[0]) != null && p2.length == 2
                      ? int.parse(p2[0]) * 60 + int.parse(p2[1])
                      : 0;
              final diff = (endMin - startMin).clamp(0, 1440);
              final h = diff ~/ 60;
              final m = diff % 60;
              final label = h > 0 && m > 0
                  ? '${h}h ${m}min'
                  : h > 0
                      ? '${h}h'
                      : '${m}min';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.schedule_rounded, size: 13, color: color),
                  const SizedBox(width: 4),
                  Text(
                    isPending ? '~$label a abonar' : label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ],
          // Sem dataFim mas com abonoMinutes calculado (ex: sem retorno)
          if (a.dataFim == null && a.abonoMinutes > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: color),
                const SizedBox(width: 4),
                Text(
                  () {
                    final h = a.abonoMinutes ~/ 60;
                    final m = a.abonoMinutes % 60;
                    final label = h > 0 && m > 0
                        ? '${h}h ${m}min'
                        : h > 0 ? '${h}h' : '${m}min';
                    return isPending ? '~$label a abonar' : label;
                  }(),
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (!isApproved && a.rejectionReason != null && a.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Motivo: ${a.rejectionReason}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      ),
    );
  }

  void _showAbonoDetail(AbonoModel a) {
    final color = a.status == AbonoStatus.pending
        ? AppColors.warning
        : a.status == AbonoStatus.approved
            ? AppColors.success
            : AppColors.error;
    final statusLabel = a.status == AbonoStatus.pending
        ? 'Pendente'
        : a.status == AbonoStatus.approved
            ? 'Aprovado'
            : 'Recusado';

    String fmtMin(int min) {
      final h = min ~/ 60;
      final m = min % 60;
      if (h == 0) return '${m}min';
      if (m == 0) return '${h}h';
      return '${h}h ${m}min';
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.verified_outlined,
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detalhes do Abono',
                            style: AppTextStyles.h3),
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(statusLabel,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Observação
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Text(a.observacao,
                    style: AppTextStyles.bodyMedium),
              ),

              // Tempo abonado
              if (a.abonoMinutes > 0) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 15, color: color),
                    const SizedBox(width: 6),
                    Text('Tempo: ',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(fmtMin(a.abonoMinutes),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        )),
                  ],
                ),
              ],

              // Motivo de recusa
              if (a.rejectionReason != null &&
                  a.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined,
                        size: 15, color: AppColors.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Motivo: ${a.rejectionReason}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Link para o PDF
              if (a.fileUrl != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse(a.fileUrl!),
                          mode: LaunchMode.externalApplication);
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined,
                      size: 16),
                  label: const Text('Ver documento'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
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
                    motivoIncompleto(widget.eventos),
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
        onTap: widget.onBatchEdit,
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
        onTap: widget.onAddEvento,
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
