import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/repositories/history_view_preference_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/services/ponto_edit_dialogs.dart';
import 'package:intl/intl.dart';
import 'widgets/card/day_card.dart';
import 'widgets/empty_history_state.dart';
import 'widgets/history_mode_calendar_view.dart';
import 'widgets/history_mode_list_view.dart';
import 'widgets/month_selector.dart';

class HistoryPage extends StatelessWidget {
  /// Se [targetUid] e [targetName] forem passados, exibe o histórico desse user (admin mode).
  final String? targetUid;
  final String? targetName;

  /// Quando fornecido, abre o histórico já no mês desta data.
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

  late DateTime _currentMonth;
  late DateTime _selectedCalendarDay;
  HistoryViewPreference _viewPreference = HistoryViewPreference.list;

  bool get isAdmin => widget.targetUid != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month)
        : DateTime(now.year, now.month);
    _selectedCalendarDay = _defaultSelectedDayForMonth(_currentMonth);
    _loadPreferredView();
  }

  Future<void> _loadPreferredView() async {
    final preferred = await _viewPreferenceRepository.loadPreferredMode();
    if (!mounted) return;
    setState(() => _viewPreference = preferred);
  }

  Future<void> _setPreferredView(HistoryViewPreference value) async {
    if (_viewPreference == value) return;
    setState(() => _viewPreference = value);

    try {
      await _viewPreferenceRepository.savePreferredMode(value);
    } catch (_) {
      // Mantém a UI responsiva mesmo sem persistência temporária.
    }
  }

  DateTime _defaultSelectedDayForMonth(DateTime month) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    return lastDay.isAfter(today) ? today : lastDay;
  }

  String _toDayId(DateTime day) {
    return DateFormat('yyyy-MM-dd').format(
      DateTime(day.year, day.month, day.day),
    );
  }

  bool _isFutureDate(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalized = DateTime(day.year, day.month, day.day);
    return normalized.isAfter(today);
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _selectedCalendarDay = _defaultSelectedDayForMonth(_currentMonth);
    });
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(uid: widget.targetUid, month: _currentMonth),
        );
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
      _selectedCalendarDay = _defaultSelectedDayForMonth(_currentMonth);
    });
    context.read<PontoHistoryBloc>().add(
          LoadHistoryEvent(uid: widget.targetUid, month: _currentMonth),
        );
  }

  /// Gera lista de todos os dias do mês selecionado (desc), sem ultrapassar hoje.
  List<String> _generateMonthDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDay =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;

    final days = <String>[];
    for (int d = lastDay; d >= 1; d--) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, d);
      // Não mostrar dias futuros
      if (date.isAfter(today)) continue;
      days.add(DateFormat('yyyy-MM-dd').format(date));
    }
    return days;
  }

  void _showAddDialogForDay(BuildContext context, String diaId) =>
      showPontoAddDialog(
        context: context,
        uid: widget.targetUid!,
        diaId: diaId,
      );

  void _showEditDialog(
          BuildContext context, String diaId, Map<String, dynamic> evento) =>
      showPontoEditDialog(
        context: context,
        uid: widget.targetUid!,
        diaId: diaId,
        evento: evento,
      );

  void _showDeleteConfirm(
          BuildContext context, String diaId, Map<String, dynamic> evento) =>
      showPontoDeleteConfirm(
        context: context,
        uid: widget.targetUid!,
        diaId: diaId,
        evento: evento,
      );

  Map<String, List<Map<String, dynamic>>> _daysMapFromState(
      PontoHistoryState state) {
    if (state is PontoHistoryLoaded) return state.daysMap;
    if (state is PontoHistoryActionSuccess) return state.daysMap;
    if (state is PontoHistoryActionError) return state.daysMap;
    if (state is PontoHistoryActionProcessing) return state.daysMap;
    return {};
  }

  Widget _buildSingleDayCard(
    BuildContext context,
    String diaId,
    List<Map<String, dynamic>> eventos,
  ) {
    return DayCard(
      diaId: diaId,
      eventos: eventos,
      isAdmin: isAdmin,
      onBatchEdit: isAdmin
          ? (d, evs) => showBatchEditDayDialog(
                context: context,
                uid: widget.targetUid!,
                diaId: d,
                eventos: evs,
              )
          : null,
      onAddEvento: isAdmin ? () => _showAddDialogForDay(context, diaId) : null,
      onEditEvento:
          isAdmin ? (evento) => _showEditDialog(context, diaId, evento) : null,
      onDeleteEvento: isAdmin
          ? (evento) => _showDeleteConfirm(context, diaId, evento)
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
          _ViewModeIconButton(
            icon: Icons.view_agenda_outlined,
            selected: _viewPreference == HistoryViewPreference.list,
            tooltip: 'Visualização em lista',
            onTap: () => _setPreferredView(HistoryViewPreference.list),
          ),
          _ViewModeIconButton(
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

    final daysMap = _daysMapFromState(state);

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

    // Gera todos os dias do mês (sem futuros)
    final allDays = _generateMonthDays();

    if (allDays.isEmpty) {
      return const EmptyHistoryState();
    }

    Widget buildDayCardById(String diaId) {
      final eventos = daysMap[diaId] ?? [];
      return _buildSingleDayCard(context, diaId, eventos);
    }

    if (_viewPreference == HistoryViewPreference.calendar) {
      return HistoryModeCalendarView(
        month: _currentMonth,
        selectedDay: _selectedCalendarDay,
        daysMap: daysMap,
        dayIdFor: _toDayId,
        isFutureDate: _isFutureDate,
        onDaySelected: (day) => setState(() => _selectedCalendarDay = day),
        dayBuilder: buildDayCardById,
        onRefresh: _refreshHistory,
      );
    }

    return HistoryModeListView(
      dayIds: allDays,
      dayBuilder: buildDayCardById,
      onRefresh: _refreshHistory,
    );
  }
}

class _ViewModeIconButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;

  const _ViewModeIconButton({
    required this.icon,
    required this.selected,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: selected ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}
