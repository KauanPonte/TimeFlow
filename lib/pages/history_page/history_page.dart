import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/repositories/justificativa_repository.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/services/ponto_edit_dialogs.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'widgets/dialogs/day_edit_dialog.dart';
import 'widgets/card/day_card.dart';
import 'widgets/empty_history_state.dart';
import 'widgets/history_mode_calendar_view.dart';
import 'widgets/history_mode_list_view.dart';
import 'widgets/history_shared_utils.dart';
import 'widgets/history_view_mode_icon_button.dart';
import 'widgets/month_selector.dart';

class HistoryPage extends StatelessWidget {
  final String? targetUid;
  final String? targetName;
  final DateTime? initialDate;

  const HistoryPage({
    super.key,
    this.targetUid,
    this.targetName,
    this.initialDate,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startMonth = initialDate != null
        ? DateTime(initialDate!.year, initialDate!.month)
        : DateTime(now.year, now.month);
    return BlocProvider(
      create: (_) => PontoHistoryBloc(
        repository: PontoHistoryRepository(),
        globalLoading: context.read<GlobalLoadingCubit>(),
      )..add(LoadHistoryEvent(uid: targetUid, month: startMonth)),
      child: _HistoryView(
        targetUid: targetUid,
        targetName: targetName,
        initialDate: initialDate,
      ),
    );
  }
}

class _HistoryView extends StatefulWidget {
  final String? targetUid;
  final String? targetName;
  final DateTime? initialDate;

  const _HistoryView({this.targetUid, this.targetName, this.initialDate});

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final _viewPreferenceRepository = HistoryViewPreferenceRepository();
  final _justificativaRepository = JustificativaRepository();

  late DateTime _currentMonth;
  late DateTime _selectedCalendarDay;
  HistoryViewPreference _viewPreference =
      HistoryViewPreferenceRepository.currentMode;

  // ← NOVO
  Set<String> _calendarBlockedDays = {};

  /// Justificativas do funcionário sendo visualizado (admin mode).
  Map<String, JustificativaModel> _adminJustificativas = {};

  bool get isAdmin => widget.targetUid != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month)
        : DateTime(now.year, now.month);
    _selectedCalendarDay =
        HistorySharedUtils.defaultSelectedDayForMonth(_currentMonth);
    _loadCalendarBlockedDays();
  }

  Future<void> _loadCalendarBlockedDays() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('calendar_events')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(_currentMonth.year, _currentMonth.month, 1)))
          .where('date',
              isLessThanOrEqualTo: Timestamp.fromDate(
                  DateTime(_currentMonth.year, _currentMonth.month + 1, 0)))
          .where('type', whereIn: ['feriado', 'recesso']).get();

      final blocked = <String>{};

      // Feriados do Firebase (admin criados)
      for (final doc in snapshot.docs) {
        final ts = doc.data()['date'] as Timestamp?;
        if (ts == null) continue;
        final d = ts.toDate();
        blocked.add(
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        );
      }

      // Feriados fixos nacionais/estaduais
      final fixos = PontoService.getBrazilHolidays(_currentMonth.year);
      for (final date in fixos.keys) {
        if (date.month == _currentMonth.month) {
          blocked.add(
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
          );
        }
      }

      if (mounted) setState(() => _calendarBlockedDays = blocked);
    } catch (_) {
      // falha silenciosa — dias do Firestore não bloqueiam, feriados fixos ainda funcionam
    }

    if (isAdmin) {
      _loadAdminJustificativas();
    }
  }


  Future<void> _loadAdminJustificativas() async {
    try {
      final list = await _justificativaRepository
          .getJustificativasForEmployee(widget.targetUid!);
      if (mounted) {
        setState(() {
          _adminJustificativas = {for (final j in list) j.diaId: j};
        });
      }
    } catch (_) {}
  }

  Future<void> _setPreferredView(HistoryViewPreference value) async {
    if (_viewPreference == value) return;
    setState(() => _viewPreference = value);
    try {
      await _viewPreferenceRepository.savePreferredMode(value);
    } catch (_) {}
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedCalendarDay =
          HistorySharedUtils.defaultSelectedDayForMonth(_currentMonth);
    });
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(uid: widget.targetUid, month: _currentMonth),
        );
    _loadCalendarBlockedDays(); // ← NOVO
  }

  void _goToNextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year && nextMonth.month > now.month)) {
      return;
    }
    setState(() {
      _currentMonth = nextMonth;
      _selectedCalendarDay =
          HistorySharedUtils.defaultSelectedDayForMonth(_currentMonth);
    });
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(uid: widget.targetUid, month: _currentMonth),
        );
    _loadCalendarBlockedDays(); // ← NOVO
  }

  void _showAddDialogForDay(BuildContext context, String diaId) =>
      showPontoAddDialog(
        context: context,
        uid: widget.targetUid!,
        diaId: diaId,
      );

  /// Abre o diálogo de solicitação de alteração (inclui campo de justificativa de falta).
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
              CreateSolicitationEvent(
                  diaId: diaId, items: items, reason: reason),
            );
      }
    }
  }

  /// Admin define justificativa diretamente sem fluxo de aprovação.
  void _showAdminSetJustificativaDialog(
      BuildContext context, String diaId, String? existing) {
    final controller = TextEditingController(text: existing ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.assignment_late_outlined,
                  color: AppColors.error, size: 20),
              const SizedBox(width: 8),
              Text(existing != null
                  ? 'Editar Justificativa'
                  : 'Adicionar Justificativa'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A justificativa será salva diretamente sem necessidade de aprovação.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 4,
                maxLength: 300,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Descreva a justificativa...',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.pop(dialogCtx);
                try {
                  await _justificativaRepository.adminSetJustificativa(
                    uid: widget.targetUid!,
                    diaId: diaId,
                    justificativa: text,
                  );
                  await _loadAdminJustificativas();
                  if (context.mounted) {
                    CustomSnackbar.showSuccess(
                        context, 'Justificativa salva.');
                  }
                } catch (e) {
                  if (context.mounted) {
                    CustomSnackbar.showError(context,
                        e.toString().replaceAll('Exception: ', ''));
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSingleDayCard(
    BuildContext context,
    String diaId,
    List<Map<String, dynamic>> eventos,
    Map<String, JustificativaModel> justificativasMap,
  ) {
    final justificativa = justificativasMap[diaId];
    final date = DateTime.tryParse(diaId);
    final isHoliday = _calendarBlockedDays.contains(diaId);
    final isFuture = date != null &&
        HistorySharedUtils.isFutureDate(date) &&
        !isHoliday;

    return DayCard(
      diaId: diaId,
      eventos: eventos,
      isAdmin: isAdmin,
      isFuture: isFuture,
      calendarBlockedDays: _calendarBlockedDays,
      justificativa: justificativa,
      onBatchEdit: isAdmin
          ? (d, evs) => showBatchEditDayDialog(
                context: context,
                uid: widget.targetUid!,
                diaId: d,
                eventos: evs,
              )
          : null,
      onAddEvento: isAdmin ? () => _showAddDialogForDay(context, diaId) : null,
      onJustify: isAdmin
          ? () => _showAdminSetJustificativaDialog(
              context, diaId, justificativa?.justificativa)
          : null,
      onRequestSolicitation: !isAdmin
          ? () => _showSolicitationDialog(context, diaId, eventos)
          : null,
    );
  }


  Future<void> _refreshHistory() async {
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(
            uid: widget.targetUid,
            month: _currentMonth,
          ),
        );
    _loadCalendarBlockedDays(); // ← NOVO
    if (isAdmin) await _loadAdminJustificativas();
  }

  @override
  Widget build(BuildContext context) {
    final title = isAdmin ? (widget.targetName ?? 'Usuário') : 'Meu Histórico';
    final subTitle = isAdmin ? 'Histórico de Pontos' : null;

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight10,
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subTitle != null)
                    Text(
                      subTitle,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          HistoryViewModeIconButton(
            icon: Icons.view_agenda_outlined,
            selected: _viewPreference == HistoryViewPreference.list,
            tooltip: 'Visualização em lista',
            onTap: () => _setPreferredView(HistoryViewPreference.list),
          ),
          HistoryViewModeIconButton(
            icon: Icons.calendar_month_outlined,
            selected: _viewPreference == HistoryViewPreference.calendar,
            tooltip: 'Visualização em calendário',
            onTap: () => _setPreferredView(HistoryViewPreference.calendar),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<PontoHistoryBloc, PontoHistoryState>(
        listener: (context, state) {
          if (state is PontoHistoryActionSuccess) {
            CustomSnackbar.showSuccess(context, state.message);
          } else if (state is PontoHistoryActionError) {
            CustomSnackbar.showError(context, state.message);
          } else if (state is PontoHistoryError) {
            CustomSnackbar.showError(context, state.message);
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              MonthSelector(
                currentMonth: _currentMonth,
                onPrevious: _goToPreviousMonth,
                onNext: _goToNextMonth,
              ),
              Expanded(
                child: _buildHistoryContent(context, state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistoryContent(BuildContext context, PontoHistoryState state) {
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
              state.message,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<PontoHistoryBloc>().add(
                      LoadHistoryEvent(
                        uid: widget.targetUid,
                        month: _currentMonth,
                      ),
                    );
              },
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    final allDays = HistorySharedUtils.generateMonthDays(_currentMonth);

    if (allDays.isEmpty) {
      return const EmptyHistoryState();
    }

    // Monta mapa de justificativas: admin usa _adminJustificativas,
    // funcionário lê do JustificativaBloc.
    Map<String, JustificativaModel> justificativasMap = {};
    if (isAdmin) {
      justificativasMap = _adminJustificativas;
    } else {
      final justState = context.watch<JustificativaBloc>().state;
      List<JustificativaModel> list = [];
      if (justState is JustificativaLoaded) list = justState.justificativas;
      if (justState is JustificativaActionSuccess) {
        list = justState.justificativas;
      }
      justificativasMap = {for (final j in list) j.diaId: j};
    }

    Widget buildDayCardById(String diaId) {
      final eventos = daysMap[diaId] ?? [];
      return _buildSingleDayCard(context, diaId, eventos, justificativasMap);
    }

    if (_viewPreference == HistoryViewPreference.calendar) {
      return HistoryModeCalendarView(
        month: _currentMonth,
        selectedDay: _selectedCalendarDay,
        daysMap: daysMap,
        dayIdFor: HistorySharedUtils.toDayId,
        isFutureDate: HistorySharedUtils.isFutureDate,
        onDaySelected: (day) => setState(() => _selectedCalendarDay = day),
        dayBuilder: buildDayCardById,
        onRefresh: _refreshHistory,
        calendarEvents: {},
      );
    }

    return HistoryModeListView(
      dayIds: allDays,
      dayBuilder: buildDayCardById,
      onRefresh: _refreshHistory,
    );
  }
}
