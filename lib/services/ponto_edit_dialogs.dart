import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import '../pages/history_page/widgets/evento_dialog.dart';
import '../pages/history_page/widgets/dialogs/day_edit_dialog.dart';

/// Exibe o diálogo para adicionar um ponto num [diaId] para o [uid] informado.
Future<void> showPontoAddDialog({
  required BuildContext context,
  required String uid,
  required String diaId,
}) async {
  final date = DateTime.parse(diaId);
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => EventoDialog(
      title: 'Adicionar Ponto',
      fixedDate: date,
    ),
  );

  if (result != null && context.mounted) {
    context.read<PontoHistoryBloc>().add(AddEventoEvent(
          uid: uid,
          diaId: result['diaId'],
          tipo: result['tipo'],
          horario: result['horario'],
        ));
  }
}

/// Exibe o diálogo de edição em lote para o [diaId] do [uid].
Future<void> showBatchEditDayDialog({
  required BuildContext context,
  required String uid,
  required String diaId,
  required List<Map<String, dynamic>> eventos,
}) async {
  final result = await showDialog<BatchEditResult>(
    context: context,
    builder: (_) => DayEditDialog(
      mode: DayEditMode.adminEdit,
      diaId: diaId,
      eventos: eventos,
    ),
  );

  if (result != null && !result.isEmpty && context.mounted) {
    context.read<PontoHistoryBloc>().add(BatchUpdateDayEvent(
          uid: uid,
          diaId: diaId,
          updates: result.updates,
          deletes: result.deletes,
          adds: result.adds,
        ));
  }
}
