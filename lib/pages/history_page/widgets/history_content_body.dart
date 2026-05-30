import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/abono/abono_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/repositories/abono_repository.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/repositories/justificativa_repository.dart';
import 'package:flutter_application_appdeponto/services/ponto_edit_dialogs.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'admin_justificativa_dialog.dart';
import 'card/day_card.dart';
import 'dialogs/day_edit_dialog.dart';
import 'empty_history_state.dart';
import 'history_mode_calendar_view.dart';
import 'history_mode_list_view.dart';
import 'history_shared_utils.dart';
import '../../../pages/admin/solicitations/admin_abono_dialog.dart';

class HistoryContentBody extends StatelessWidget {
  final PontoHistoryState state;
  final DateTime currentMonth;
  final DateTime selectedCalendarDay;
  final HistoryViewPreference viewPreference;
  final bool isAdmin;
  final String? targetUid;
  final Map<DateTime, List<Map<String, dynamic>>> allCalendarEvents;

  // Justificativas (texto de falta — sem crédito de horas)
  final Map<String, JustificativaModel> adminJustificativas;
  final Map<String, JustificativaModel> employeeJustificativas;

  // Abonos (crédito de horas)
  final Map<String, AbonoModel> adminAbonos;
  final Map<String, AbonoModel> employeeAbonos;

  final Set<String> excusedDayIds;
  final JustificativaRepository justificativaRepository;
  final AbonoRepository abonoRepository;
  final ValueChanged<DateTime> onDaySelected;
  final Future<void> Function() onRefresh;
  final VoidCallback onAdminJustificativasReloaded;
  final VoidCallback onAdminAbonosReloaded;

  const HistoryContentBody({
    super.key,
    required this.state,
    required this.currentMonth,
    required this.selectedCalendarDay,
    required this.viewPreference,
    required this.isAdmin,
    this.targetUid,
    required this.allCalendarEvents,
    required this.adminJustificativas,
    this.employeeJustificativas = const {},
    required this.adminAbonos,
    this.employeeAbonos = const {},
    required this.excusedDayIds,
    required this.justificativaRepository,
    required this.abonoRepository,
    required this.onDaySelected,
    required this.onRefresh,
    required this.onAdminJustificativasReloaded,
    required this.onAdminAbonosReloaded,
  });

  @override
  Widget build(BuildContext context) {
    if (state is PontoHistoryLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    final daysMap = HistorySharedUtils.daysMapFromState(state);

    if (state is PontoHistoryError && daysMap.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              (state as PontoHistoryError).message,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<PontoHistoryBloc>().add(
                      LoadHistoryEvent(uid: targetUid, month: currentMonth),
                    );
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final allDays = HistorySharedUtils.generateMonthDays(currentMonth);
    if (allDays.isEmpty) return const EmptyHistoryState();

    final justificativasMap =
        isAdmin ? adminJustificativas : employeeJustificativas;
    final abonosMap = isAdmin ? adminAbonos : employeeAbonos;

    Widget buildDayCardById(String diaId) {
      final eventos = daysMap[diaId] ?? [];
      return _buildSingleDayCard(
          context, diaId, eventos, justificativasMap, abonosMap);
    }

    if (viewPreference == HistoryViewPreference.calendar) {
      final holidayDayIds = allCalendarEvents.keys
          .map((date) => HistorySharedUtils.toDayId(date))
          .toSet();
      holidayDayIds.addAll(excusedDayIds);

      // Dias sem ponto mas com justificativa aprovada = falta justificada
      final justifiedAbsenceDayIds = justificativasMap.entries
          .where((e) =>
              e.value.status == JustificativaStatus.approved &&
              (daysMap[e.key] == null || daysMap[e.key]!.isEmpty))
          .map((e) => e.key)
          .toSet();

      return HistoryModeCalendarView(
        month: currentMonth,
        selectedDay: selectedCalendarDay,
        daysMap: daysMap,
        dayIdFor: HistorySharedUtils.toDayId,
        isFutureDate: HistorySharedUtils.isFutureDate,
        onDaySelected: onDaySelected,
        dayBuilder: buildDayCardById,
        onRefresh: onRefresh,
        holidayDayIds: holidayDayIds,
        justifiedAbsenceDayIds: justifiedAbsenceDayIds,
        calendarEvents: allCalendarEvents,
      );
    }

    return HistoryModeListView(
      dayIds: allDays,
      dayBuilder: buildDayCardById,
      onRefresh: onRefresh,
    );
  }

  Widget _buildSingleDayCard(
    BuildContext context,
    String diaId,
    List<Map<String, dynamic>> eventos,
    Map<String, JustificativaModel> justificativasMap,
    Map<String, AbonoModel> abonosMap,
  ) {
    final justificativa = justificativasMap[diaId];
    final abono = abonosMap[diaId];

    final date = DateTime.tryParse(diaId);
    final holidayDayIds = allCalendarEvents.keys
        .map((d) => HistorySharedUtils.toDayId(d))
        .toSet();
    holidayDayIds.addAll(excusedDayIds);

    final isHoliday = holidayDayIds.contains(diaId);
    final isFuture =
        date != null && HistorySharedUtils.isFutureDate(date) && !isHoliday;

    final cleanDate =
        date != null ? DateTime(date.year, date.month, date.day) : null;
    final isExcused = excusedDayIds.contains(diaId);

    String? holidayName;
    if (cleanDate != null && allCalendarEvents.containsKey(cleanDate)) {
      holidayName = allCalendarEvents[cleanDate]!.first['title']?.toString();
    } else if (isExcused) {
      holidayName = 'Ponto Facultativo (Atestado)';
    }

    final workedMinutes = _computeWorkedMinutes(eventos);

    return DayCard(
      diaId: diaId,
      eventos: eventos,
      isAdmin: isAdmin,
      isFuture: isFuture,
      holidayName: holidayName,
      calendarBlockedDays: holidayDayIds,
      justificativa: justificativa,
      abono: abono,
      onBatchEdit: isAdmin
          ? (d, evs) => showBatchEditDayDialog(
                context: context,
                uid: targetUid!,
                diaId: d,
                eventos: evs,
              )
          : null,
      onAddEvento: isAdmin ? () => _showAddDialogForDay(context, diaId) : null,
      onJustify: isAdmin
          ? () => AdminJustificativaDialog.show(
                context: context,
                targetUid: targetUid!,
                diaId: diaId,
                existing: justificativa?.justificativa,
                justificativaRepository: justificativaRepository,
                onSaved: onAdminJustificativasReloaded,
              )
          : null,
      onApplyAbono: isAdmin
          ? () => AdminAbonoDialog.show(
                context: context,
                targetUid: targetUid!,
                diaId: diaId,
                workedMinutes: workedMinutes,
                eventos: eventos,
                abonoRepository: abonoRepository,
                onSaved: onAdminAbonosReloaded,
              )
          : null,
      onDeleteJustificativa: justificativa != null
          ? () => context
              .read<JustificativaBloc>()
              .add(DeleteJustificativaEvent(justificativa.id))
          : null,
      onDeleteAbono: abono != null
          ? () =>
              context.read<AbonoBloc>().add(DeleteAbonoEvent(abono.id))
          : null,
      onRequestSolicitation:
          !isAdmin ? () => _showSolicitationDialog(context, diaId, eventos) : null,
    );
  }

  int _computeWorkedMinutes(List<Map<String, dynamic>> eventos) {
    if (eventos.isEmpty) return 0;
    DateTime? lastEntrada;
    int total = 0;
    for (final e in eventos) {
      final tipo = (e['tipo'] ?? '').toString();
      final at = e['at'] as DateTime?;
      if (at == null) continue;
      if (tipo == 'entrada' || tipo == 'retorno') {
        lastEntrada = at;
      } else if ((tipo == 'pausa' || tipo == 'saida') && lastEntrada != null) {
        total += at.difference(lastEntrada).inMinutes;
        lastEntrada = null;
      }
    }
    return total;
  }

  void _showAddDialogForDay(BuildContext context, String diaId) =>
      showPontoAddDialog(context: context, uid: targetUid!, diaId: diaId);

  Future<void> _showSolicitationDialog(
    BuildContext context,
    String diaId,
    List<Map<String, dynamic>> eventos,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => DayEditDialog(
        mode: DayEditMode.solicitation,
        diaId: diaId,
        eventos: eventos,
      ),
    );

    if (result != null && context.mounted) {
      final items = result['items'] as List<SolicitationItem>;
      final reason = result['reason'] as String?;
      final justificativaText = result['justificativa'] as String?;

      if (justificativaText != null) {
        context.read<JustificativaBloc>().add(
              SubmitJustificativaEvent(
                  diaId: diaId, justificativa: justificativaText),
            );
      }

      if (items.isNotEmpty) {
        context.read<SolicitationBloc>().add(
              CreateSolicitationEvent(diaId: diaId, items: items, reason: reason),
            );
      }
    }
  }
}
