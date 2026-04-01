import 'package:flutter/material.dart';
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
  final JustificativaModel? justificativa;
  final List<SolicitationModel> pendingSolicitations;
  final void Function(String solicitationId)? onCancelSolicitation;

  /// Admin: abre edição em lote passando diaId e eventos atuais.
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
    this.justificativa,
    this.pendingSolicitations = const [],
    this.onCancelSolicitation,
    this.onBatchEdit,
  });

  @override
  Widget build(BuildContext context) {
    final blockedDay = isWeekendOrHoliday(diaId);
    final disabled = isFuture || blockedDay;

    if (isFuture) {
      return EmptyDayCard(
        diaId: diaId,
        disabled: disabled,
        isAdmin: isAdmin,
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
        onAddEvento: disabled ? null : onAddEvento,
        onBatchEdit: (!disabled && onBatchEdit != null)
            ? () => onBatchEdit!(diaId, [])
            : null,
        onRequestSolicitation: disabled ? null : onRequestSolicitation,
        onJustify: disabled ? null : onJustify,
        justificativa: justificativa,
      );
    }
    if (eventos.isEmpty && pendingSolicitations.isNotEmpty) {
      return PendingOnlyDayCard(
        diaId: diaId,
        pendingSolicitations: pendingSolicitations,
        disabled: disabled,
        isAdmin: isAdmin,
        onCancelSolicitation: disabled ? null : onCancelSolicitation,
        onRequestSolicitation: disabled ? null : onRequestSolicitation,
      );
    }
    return FilledDayCard(
      diaId: diaId,
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
    );
  }
}
