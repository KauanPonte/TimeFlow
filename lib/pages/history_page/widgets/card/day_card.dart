import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'widgets/empty_day_card.dart';
import 'widgets/filled_day_card.dart';
import 'widgets/pending_only_day_card.dart';
import 'widgets/day_card_helpers.dart';

/// Widget roteador: delega para EmptyDayCard, PendingOnlyDayCard ou FilledDayCard.
class DayCard extends StatelessWidget {
  final String diaId;
  final List<Map<String, dynamic>> eventos;
  final bool isAdmin;
  final bool isFuture;
  final VoidCallback? onAddEvento;
  final VoidCallback? onRequestSolicitation;
  final VoidCallback? onJustify;
  final VoidCallback? onApplyAbono;
  final VoidCallback? onDeleteJustificativa;
  final VoidCallback? onDeleteAbono;
  final JustificativaModel? justificativa;
  final AbonoModel? abono;
  final List<SolicitationModel> pendingSolicitations;
  final void Function(String solicitationId)? onCancelSolicitation;
  final Set<String> calendarBlockedDays;
  final String? holidayName;
  final VoidCallback? onOpenDayActions;
  final void Function(String diaId, List<Map<String, dynamic>> eventos)?
      onBatchEdit;

  const DayCard({
    super.key,
    required this.diaId,
    required this.eventos,
    this.isAdmin = false,
    this.isFuture = false,
    this.onAddEvento,
    this.onRequestSolicitation,
    this.onJustify,
    this.onApplyAbono,
    this.onDeleteJustificativa,
    this.onDeleteAbono,
    this.justificativa,
    this.abono,
    this.pendingSolicitations = const [],
    this.onCancelSolicitation,
    this.onBatchEdit,
    this.calendarBlockedDays = const {},
    this.holidayName,
    this.onOpenDayActions,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isFuture || isWeekendDay(diaId);

    if (isFuture) {
      return EmptyDayCard(
        diaId: diaId,
        disabled: disabled,
        isAdmin: isAdmin,
        holidayName: holidayName,
        onAddEvento: disabled ? null : onAddEvento,
        onBatchEdit: (!disabled && onBatchEdit != null)
            ? () => onBatchEdit!(diaId, [])
            : null,
        onRequestSolicitation: disabled ? null : onRequestSolicitation,
      );
    }

    if (eventos.isEmpty && pendingSolicitations.isEmpty) {
      return EmptyDayCard(
        diaId: diaId,
        disabled: disabled,
        isAdmin: isAdmin,
        holidayName: holidayName,
        onAddEvento: disabled ? null : onAddEvento,
        onBatchEdit: (!disabled && onBatchEdit != null)
            ? () => onBatchEdit!(diaId, [])
            : null,
        onRequestSolicitation: disabled ? null : onRequestSolicitation,
        onJustify: disabled ? null : onJustify,
        onApplyAbono: disabled ? null : onApplyAbono,
        onDeleteJustificativa: disabled ? null : onDeleteJustificativa,
        onDeleteAbono: disabled ? null : onDeleteAbono,
        justificativa: justificativa,
        abono: abono,
        onOpenDayActions: onOpenDayActions,
      );
    }

    if (eventos.isEmpty && pendingSolicitations.isNotEmpty) {
      return PendingOnlyDayCard(
        diaId: diaId,
        holidayName: holidayName,
        pendingSolicitations: pendingSolicitations,
        disabled: disabled,
        isAdmin: isAdmin,
        onCancelSolicitation: disabled ? null : onCancelSolicitation,
        onRequestSolicitation: disabled ? null : onRequestSolicitation,
      );
    }

    return FilledDayCard(
      diaId: diaId,
      holidayName: holidayName,
      eventos: eventos,
      disabled: disabled,
      isAdmin: isAdmin,
      pendingSolicitations: pendingSolicitations,
      onAddEvento: disabled ? null : onAddEvento,
      onBatchEdit: (!disabled && onBatchEdit != null)
          ? () => onBatchEdit!(diaId, eventos)
          : null,
      onRequestSolicitation: disabled ? null : onRequestSolicitation,
      onCancelSolicitation: disabled ? null : onCancelSolicitation,
      onOpenDayActions: onOpenDayActions,
      abono: abono,
      onApplyAbono: disabled ? null : onApplyAbono,
      onDeleteAbono: disabled ? null : onDeleteAbono,
    );
  }
}
