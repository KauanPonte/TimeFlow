import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'widgets/empty_day_card.dart';
import 'widgets/filled_day_card.dart';
import 'widgets/pending_only_day_card.dart';

/// Widget roteador: delega para EmptyDayCard, PendingOnlyDayCard ou FilledDayCard.
class DayCard extends StatelessWidget {
  final String diaId;
  final List<Map<String, dynamic>> eventos;
  final bool isAdmin;
  final bool isFuture;
  final void Function(Map<String, dynamic> evento)? onEditEvento;
  final void Function(Map<String, dynamic> evento)? onDeleteEvento;
  final VoidCallback? onAddEvento;
  final VoidCallback? onRequestSolicitation;
  final List<SolicitationModel> pendingSolicitations;
  final void Function(String solicitationId)? onCancelSolicitation;

  const DayCard({
    super.key,
    required this.diaId,
    required this.eventos,
    this.isAdmin = false,
    this.isFuture = false,
    this.onEditEvento,
    this.onDeleteEvento,
    this.onAddEvento,
    this.onRequestSolicitation,
    this.pendingSolicitations = const [],
    this.onCancelSolicitation,
  });

  @override
  Widget build(BuildContext context) {
    if (isFuture) {
      return EmptyDayCard(
        diaId: diaId,
        disabled: true,
        isAdmin: isAdmin,
        onAddEvento: onAddEvento,
        onRequestSolicitation: onRequestSolicitation,
      );
    }
    if (eventos.isEmpty && pendingSolicitations.isEmpty) {
      return EmptyDayCard(
        diaId: diaId,
        disabled: false,
        isAdmin: isAdmin,
        onAddEvento: onAddEvento,
        onRequestSolicitation: onRequestSolicitation,
      );
    }
    if (eventos.isEmpty && pendingSolicitations.isNotEmpty) {
      return PendingOnlyDayCard(
        diaId: diaId,
        pendingSolicitations: pendingSolicitations,
        isAdmin: isAdmin,
        onCancelSolicitation: onCancelSolicitation,
        onRequestSolicitation: onRequestSolicitation,
      );
    }
    return FilledDayCard(
      diaId: diaId,
      eventos: eventos,
      isAdmin: isAdmin,
      pendingSolicitations: pendingSolicitations,
      onEditEvento: onEditEvento,
      onDeleteEvento: onDeleteEvento,
      onAddEvento: onAddEvento,
      onRequestSolicitation: onRequestSolicitation,
      onCancelSolicitation: onCancelSolicitation,
    );
  }
}
