import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_state.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/services/ponto_edit_dialogs.dart';
import '../../history_page/widgets/card/day_card.dart';
import '../../history_page/widgets/history_mode_calendar_view.dart';
import '../../history_page/widgets/history_mode_list_view.dart';
import '../../history_page/widgets/history_shared_utils.dart';
import '../../history_page/widgets/history_view_mode_icon_button.dart';
import '../../history_page/widgets/month_selector.dart';
import '../../history_page/widgets/dialogs/day_edit_dialog.dart';

class HomeHistorySection extends StatefulWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isAdmin;
  final String? uid;
  final VoidCallback onActionSuccess;

  /// Dia que deve receber destaque visual e scroll (ISO 'yyyy-MM-dd').
  final String? highlightDayId;

  const HomeHistorySection({
    super.key,
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.isAdmin,
    required this.onActionSuccess,
    this.uid,
    this.highlightDayId,
  });

  @override
  State<HomeHistorySection> createState() => _HomeHistorySectionState();
}

class _HomeHistorySectionState extends State<HomeHistorySection> {
  final _viewPreferenceRepository = HistoryViewPreferenceRepository();

  /// GlobalKeys por diaId para `Scrollable.ensureVisible`.
  final Map<String, GlobalKey> _dayKeys = {};
  HistoryViewPreference _viewPreference =
      HistoryViewPreferenceRepository.currentMode;
  late DateTime _selectedCalendarDay;

  @override
  void initState() {
    super.initState();
    _selectedCalendarDay =
        HistorySharedUtils.defaultSelectedDayForMonth(widget.currentMonth);
  }

  Future<void> _setPreferredView(HistoryViewPreference value) async {
    if (_viewPreference == value) return;
    setState(() => _viewPreference = value);

    try {
      await _viewPreferenceRepository.savePreferredMode(value);
    } catch (_) {
      // Evita travar UI se persistência falhar momentaneamente.
    }
  }

  GlobalKey _keyForDay(String diaId) =>
      _dayKeys.putIfAbsent(diaId, () => GlobalKey());

  void _scrollToHighlightedDay() {
    final id = widget.highlightDayId;
    if (id == null) return;
    final ctx = _dayKeys[id]?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.15,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(HomeHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Mês mudou → limpa chaves velhas (evita acúmulo desnecessário).
    if (widget.currentMonth != oldWidget.currentMonth) {
      _dayKeys.clear();
      _selectedCalendarDay =
          HistorySharedUtils.defaultSelectedDayForMonth(widget.currentMonth);
    }

    if (widget.highlightDayId != null &&
        widget.highlightDayId != oldWidget.highlightDayId) {
      final highlighted = DateTime.tryParse(widget.highlightDayId!);
      if (highlighted != null) {
        _selectedCalendarDay =
            DateTime(highlighted.year, highlighted.month, highlighted.day);
      }
    }

    // Highlight mudou → se o histórico já está carregado, scrolla imediatamente.
    if (widget.highlightDayId != null &&
        widget.highlightDayId != oldWidget.highlightDayId) {
      final state = context.read<PontoHistoryBloc>().state;
      final alreadyLoaded = state is PontoHistoryLoaded ||
          state is PontoHistoryActionSuccess ||
          state is PontoHistoryActionError ||
          state is PontoHistoryActionProcessing;
      if (alreadyLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToHighlightedDay();
        });
      }
      // Se não está carregado, o BlocConsumer.listener cuidará do scroll
      // quando o estado mudar para PontoHistoryLoaded.
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SolicitationBloc, SolicitationState>(
      listener: (context, solState) {
        if (solState is SolicitationActionSuccess) {
          CustomSnackbar.showSuccess(context, solState.message);
        } else if (solState is SolicitationError &&
            solState.message.isNotEmpty) {
          CustomSnackbar.showError(context, solState.message);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.history,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Meu Histórico',
                style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
              ),
              const Spacer(),
              HistoryViewModeIconButton(
                icon: Icons.view_agenda_outlined,
                selected: _viewPreference == HistoryViewPreference.list,
                tooltip: 'Visualização em lista',
                onTap: () => _setPreferredView(HistoryViewPreference.list),
              ),
              const SizedBox(width: 4),
              HistoryViewModeIconButton(
                icon: Icons.calendar_month_outlined,
                selected: _viewPreference == HistoryViewPreference.calendar,
                tooltip: 'Visualização em calendário',
                onTap: () => _setPreferredView(HistoryViewPreference.calendar),
              ),
            ],
          ),
          const SizedBox(height: 12),
          MonthSelector(
            currentMonth: widget.currentMonth,
            onPrevious: widget.onPrevious,
            onNext: widget.onNext,
          ),
          const SizedBox(height: 8),
          BlocConsumer<PontoHistoryBloc, PontoHistoryState>(
            listener: (context, state) {
              if (state is PontoHistoryActionSuccess) {
                CustomSnackbar.showSuccess(context, state.message);
                widget.onActionSuccess();
              } else if (state is PontoHistoryActionError) {
                CustomSnackbar.showError(context, state.message);
              } else if (state is PontoHistoryError) {
                CustomSnackbar.showError(context, state.message);
              }

              // Scroll para o dia destacado assim que o histórico terminar
              // de carregar (caso o mês tenha mudado).
              if (state is PontoHistoryLoaded &&
                  widget.highlightDayId != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _scrollToHighlightedDay();
                });
              }
            },
            builder: (context, state) {
              if (state is PontoHistoryLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                );
              }

              final daysMap = HistorySharedUtils.daysMapFromState(state);
              final allDays =
                  HistorySharedUtils.generateMonthDays(widget.currentMonth);

              if (allDays.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhum dia para exibir',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              final canEdit = widget.isAdmin && widget.uid != null;

              // Obtém solicitações pendentes do bloc
              final solState = context.watch<SolicitationBloc>().state;
              final allSolicitations = <SolicitationModel>[];
              if (solState is SolicitationLoaded) {
                allSolicitations.addAll(solState.solicitations);
              } else if (solState is SolicitationActionSuccess) {
                allSolicitations.addAll(solState.solicitations);
              } else if (solState is SolicitationActionProcessing) {
                allSolicitations.addAll(solState.solicitations);
              } else if (solState is SolicitationError) {
                allSolicitations.addAll(solState.solicitations);
              }
              final pendingSolicitations = allSolicitations
                  .where((s) => s.status == SolicitationStatus.pending)
                  .toList(growable: false);
              final pendingDayIds = widget.isAdmin
                  ? <String>{}
                  : pendingSolicitations.map((s) => s.diaId).toSet();

              DayCard buildDayCard(String diaId, {bool withKey = false}) {
                final eventos = daysMap[diaId] ?? [];
                final isHighlight = diaId == widget.highlightDayId;
                final daySolicitations = widget.isAdmin
                    ? <SolicitationModel>[]
                    : pendingSolicitations
                        .where((s) => s.diaId == diaId)
                        .toList();

                return DayCard(
                  key: withKey && isHighlight ? _keyForDay(diaId) : null,
                  diaId: diaId,
                  eventos: eventos,
                  isAdmin: widget.isAdmin,
                  pendingSolicitations: daySolicitations,
                  onBatchEdit: canEdit
                      ? (d, evs) => showBatchEditDayDialog(
                            context: context,
                            uid: widget.uid!,
                            diaId: d,
                            eventos: evs,
                          )
                      : null,
                  onAddEvento: canEdit
                      ? () => showPontoAddDialog(
                            context: context,
                            uid: widget.uid!,
                            diaId: diaId,
                          )
                      : null,
                  onEditEvento: canEdit
                      ? (ev) => showPontoEditDialog(
                            context: context,
                            uid: widget.uid!,
                            diaId: diaId,
                            evento: ev,
                          )
                      : null,
                  onDeleteEvento: canEdit
                      ? (ev) => showPontoDeleteConfirm(
                            context: context,
                            uid: widget.uid!,
                            diaId: diaId,
                            evento: ev,
                          )
                      : null,
                  onRequestSolicitation: (!widget.isAdmin)
                      ? () => _showSolicitationDialog(
                            context,
                            diaId,
                            eventos,
                            daySolicitations,
                          )
                      : null,
                  onCancelSolicitation: (!widget.isAdmin)
                      ? (solId) => _confirmCancelSolicitation(context, solId)
                      : null,
                );
              }

              if (_viewPreference == HistoryViewPreference.calendar) {
                return HistoryModeCalendarView(
                  month: widget.currentMonth,
                  selectedDay: _selectedCalendarDay,
                  daysMap: daysMap,
                  dayIdFor: HistorySharedUtils.toDayId,
                  isFutureDate: HistorySharedUtils.isFutureDate,
                  pendingDayIds: pendingDayIds,
                  onDaySelected: (day) =>
                      setState(() => _selectedCalendarDay = day),
                  dayBuilder: (dayId) => buildDayCard(dayId),
                );
              }

              return HistoryModeListView(
                dayIds: allDays,
                dayBuilder: (dayId) => buildDayCard(dayId, withKey: true),
                embedInParentScroll: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelSolicitation(
    BuildContext context,
    String solicitationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar solicitação?', style: AppTextStyles.h3),
        content: Text(
          'Tem certeza que deseja cancelar esta solicitação?\n'
          'Esta ação não pode ser desfeita.',
          style: AppTextStyles.bodySmall,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancelar solicitação'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<SolicitationBloc>().add(
            CancelSolicitationEvent(solicitationId: solicitationId),
          );
    }
  }

  Future<void> _showSolicitationDialog(
    BuildContext context,
    String diaId,
    List<Map<String, dynamic>> eventos,
    List<SolicitationModel> daySolicitations,
  ) async {
    // Se já existe uma solicitação pendente para este dia, abre o diálogo
    // para edição — ao salvar, a existente é substituída pela nova.
    final existing =
        daySolicitations.isNotEmpty ? daySolicitations.first : null;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => DayEditDialog(
        mode: DayEditMode.solicitation,
        diaId: diaId,
        eventos: eventos,
        existingSolicitation: existing,
      ),
    );

    if (result != null && context.mounted) {
      final items = result['items'] as List<SolicitationItem>;
      final reason = result['reason'] as String?;

      if (existing != null) {
        // Substitui a solicitação existente pela nova
        context.read<SolicitationBloc>().add(
              UpdateSolicitationEvent(
                existingSolicitationId: existing.id,
                diaId: diaId,
                items: items,
                reason: reason,
              ),
            );
      } else {
        context.read<SolicitationBloc>().add(
              CreateSolicitationEvent(
                diaId: diaId,
                items: items,
                reason: reason,
              ),
            );
      }
    }
  }
}
