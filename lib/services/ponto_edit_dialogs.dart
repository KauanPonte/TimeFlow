import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import '../pages/history_page/widgets/evento_dialog.dart';

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

/// Exibe o diálogo para editar um [evento] existente.
Future<void> showPontoEditDialog({
  required BuildContext context,
  required String uid,
  required String diaId,
  required Map<String, dynamic> evento,
}) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => EventoDialog(
      title: 'Editar Ponto',
      initialTipo: evento['tipo'],
      initialHorario: evento['at'],
    ),
  );

  if (result != null && context.mounted) {
    context.read<PontoHistoryBloc>().add(UpdateEventoEvent(
          uid: uid,
          diaId: result['diaId'],
          eventoId: evento['id'],
          tipo: result['tipo'],
          horario: result['horario'],
        ));
  }
}

/// Exibe confirmação e remove o [evento] do [diaId].
void showPontoDeleteConfirm({
  required BuildContext context,
  required String uid,
  required String diaId,
  required Map<String, dynamic> evento,
}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
          SizedBox(width: 12),
          Text('Remover Ponto', style: AppTextStyles.h3),
        ],
      ),
      content: Text(
        'Tem certeza que deseja remover este registro de ponto?',
        style: AppTextStyles.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancelar',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.read<PontoHistoryBloc>().add(DeleteEventoEvent(
                  uid: uid,
                  diaId: diaId,
                  eventoId: evento['id'],
                ));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Remover'),
        ),
      ],
    ),
  );
}
