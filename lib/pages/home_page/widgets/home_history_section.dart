import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_event.dart';
import 'package:flutter_application_appdeponto/blocs/justificativa/justificativa_state.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_event.dart';
import 'package:flutter_application_appdeponto/blocs/solicitations/solicitation_state.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/widgets/app_dialog_components.dart';
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
  final Map<String, GlobalKey> _dayKeys = {};
  late DateTime _selectedCalendarDay;
  String? _pendingScrollDayId;

  // 1. Variável de estado para os feriados e eventos do admin
  Map<DateTime, List<Map<String, dynamic>>> _allVisibleEvents = {};
  final Set<int> _loadedFixedHolidaysYears = {};

  HistoryViewPreference _viewPreference =
      HistoryViewPreferenceRepository.currentMode;

  @override
  void initState() {
    super.initState();
    _selectedCalendarDay =
        HistorySharedUtils.defaultSelectedDayForMonth(widget.currentMonth);

    // 2. Chama o carregamento dos feriados ao iniciar
    _loadCalendarEvents();
  }

  Future<void> _loadCalendarEvents() async {
    final year = widget.currentMonth.year;
    if (_loadedFixedHolidaysYears.contains(year) && _allVisibleEvents.isNotEmpty) {
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('calendar_events').get();

      final Map<DateTime, List<Map<String, dynamic>>> newEvents = Map.from(_allVisibleEvents);

      // Carrega Feriados Fixos do Código (Nacionais/Estaduais)
      final fixos = PontoService.getBrazilHolidays(year);
      fixos.forEach((date, name) {
        final cleanDate = DateTime(date.year, date.month, date.day);
        if (!newEvents.containsKey(cleanDate)) {
          newEvents[cleanDate] = [{'title': name, 'type': 'feriado'}];
        }
      });
      _loadedFixedHolidaysYears.add(year);

      // Carrega Feriados dinâmicos do Firebase (gravados pelo Admin)
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['date'] == null) continue;

        final date = (data['date'] as Timestamp).toDate();
        final cleanDate = DateTime(date.year, date.month, date.day);

        if (newEvents[cleanDate] == null) {
          newEvents[cleanDate] = [data];
        } else {
          // Evita duplicar se o evento já veio do Firestore antes ou é um fixo
          final exists = newEvents[cleanDate]!.any((ev) => ev['id'] == doc.id || (ev['title'] == data['title'] && ev['type'] == data['type']));
          if (!exists) {
            newEvents[cleanDate]!.add(data);
          }
        }
      }

      if (mounted) {
        setState(() {
          _allVisibleEvents = newEvents;
        });
      }
    } catch (e) {
      debugPrint("Erro ao carregar eventos do calendário: $e");
    }
  }

  void _requestScrollToDay(String dayId) {
    _pendingScrollDayId = dayId;

    final state = context.read<PontoHistoryBloc>().state;
    final alreadyLoaded = state is PontoHistoryLoaded ||
        state is PontoHistoryActionSuccess ||
        state is PontoHistoryActionError ||
        state is PontoHistoryActionProcessing;

    if (alreadyLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToPendingDay();
      });
    }
  }

  void _scrollToPendingDay() {
    final dayId = _pendingScrollDayId;
    if (dayId == null) return;

    final ctx = _dayKeys[dayId]?.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      alignment: 0.15,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );

    _pendingScrollDayId = null;
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

  @override
  void didUpdateWidget(HomeHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Mês mudou → limpa chaves velhas (evita acúmulo desnecessário) e agenda
    // scroll para o dia padrão desse mês.
    if (widget.currentMonth != oldWidget.currentMonth) {
      _dayKeys.clear();
      _selectedCalendarDay =
          HistorySharedUtils.defaultSelectedDayForMonth(widget.currentMonth);

      _requestScrollToDay(HistorySharedUtils.toDayId(_selectedCalendarDay));
      if (widget.currentMonth.year != oldWidget.currentMonth.year) {
        _loadCalendarEvents();
      }
    }

    // Caso o dia destacado mude (por notificação de registro incompleto),
    // agenda scroll pro dia e ajusta o dia selecionado no calendário.
    if (widget.highlightDayId != null &&
        widget.highlightDayId != oldWidget.highlightDayId) {
      final highlighted = DateTime.tryParse(widget.highlightDayId!);
      if (highlighted != null) {
        _selectedCalendarDay =
            DateTime(highlighted.year, highlighted.month, highlighted.day);
      }
      _requestScrollToDay(widget.highlightDayId!);
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

              // Scroll para o dia pendente (mês carregado / dia selecionado / registro incompleto)
              if (state is PontoHistoryLoaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _scrollToPendingDay();
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

              // Justificativas do funcionário
              final justState = context.watch<JustificativaBloc>().state;
              final Map<String, JustificativaModel> justificativasMap;
              if (!widget.isAdmin) {
                List<JustificativaModel> jList = [];
                if (justState is JustificativaLoaded) jList = justState.justificativas;
                if (justState is JustificativaActionSuccess) jList = justState.justificativas;
                justificativasMap = {for (final j in jList) j.diaId: j};
              } else {
                justificativasMap = {};
              }

              DayCard buildDayCard(String diaId) {
                final eventos = daysMap[diaId] ?? [];
                final daySolicitations = widget.isAdmin
                    ? <SolicitationModel>[]
                    : pendingSolicitations
                        .where((s) => s.diaId == diaId)
                        .toList();

                final date = DateTime.tryParse(diaId);
                String? holidayName;
                bool isHoliday = false;
                if (date != null) {
                  final cleanDate = DateTime(date.year, date.month, date.day);
                  final eventsForDay = _allVisibleEvents[cleanDate];
                  if (eventsForDay != null && eventsForDay.isNotEmpty) {
                    final title = eventsForDay.first['title'] as String?;
                    if (title != null) holidayName = title;
                    isHoliday = true;
                  }
                }

                final isFuture = date != null &&
                    HistorySharedUtils.isFutureDate(date) &&
                    !isHoliday;

                return DayCard(
                  key: _keyForDay(diaId),
                  diaId: diaId,
                  eventos: eventos,
                  isAdmin: widget.isAdmin,
                  isFuture: isFuture,
                  holidayName: holidayName,
                  pendingSolicitations: daySolicitations,
                  justificativa: justificativasMap[diaId],
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
                  onRequestSolicitation: (!widget.isAdmin)
                      ? () => _showSolicitationDialog(
                            context,
                            diaId,
                            eventos,
                            daySolicitations,
                          )
                      : null,
                  onCancelSolicitation: (!widget.isAdmin)
                      ? (solId) => _confirmCancelSolicitation(solId)
                      : null,
                );
              }


              if (_viewPreference == HistoryViewPreference.calendar) {
                final holidayDayIds = _allVisibleEvents.keys.map((date) {
                  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }).toSet();

                return HistoryModeCalendarView(
                  month: widget.currentMonth,
                  selectedDay: _selectedCalendarDay,
                  daysMap: daysMap,
                  calendarEvents: _allVisibleEvents,
                  dayIdFor: HistorySharedUtils.toDayId,
                  isFutureDate: HistorySharedUtils.isFutureDate,
                  pendingDayIds: pendingDayIds,
                  holidayDayIds: holidayDayIds,
                  onDaySelected: (day) {
                    setState(() => _selectedCalendarDay = day);
                    _requestScrollToDay(HistorySharedUtils.toDayId(day));
                  },
                  dayBuilder: (dayId) => buildDayCard(dayId),
                );
              }

              return HistoryModeListView(
                dayIds: allDays,
                dayBuilder: (dayId) => buildDayCard(dayId),
                embedInParentScroll: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelSolicitation(
    String solicitationId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialogScaffold(
        title: 'Cancelar solicitação?',
        subtitle: 'Tem certeza que deseja cancelar esta solicitação?\n'
            'Esta ação não pode ser desfeita.',
        icon: Icons.warning_amber_rounded,
        isDestructive: true,
        confirmLabel: 'Cancelar solicitação',
        cancelLabel: 'Voltar',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
        children: const [],
      ),
    );

    if (confirmed == true && mounted) {
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
    // ← NOVO: bloqueia se for feriado/recesso/ponto facultativo
    final date = DateTime.parse(diaId);
    final ehFeriado = await PontoService.isFeriado(date);
    if (!context.mounted) return;

    if (ehFeriado) {
      CustomSnackbar.showError(
        context,
        'Registro negado. Não há trabalho neste dia.',
      );
      return;
    }

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

    if (!context.mounted) return;

    if (result != null) {
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
        if (existing != null) {
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
}
