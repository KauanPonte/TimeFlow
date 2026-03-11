import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_event.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/services/ponto_edit_dialogs.dart';
import 'package:intl/intl.dart';
import 'widgets/card/day_card.dart';
import 'widgets/empty_history_state.dart';
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
  late DateTime _currentMonth;

  bool get isAdmin => widget.targetUid != null;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = widget.initialDate != null
        ? DateTime(widget.initialDate!.year, widget.initialDate!.month)
        : DateTime(now.year, now.month);
  }

  void _goToPreviousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
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

    Map<String, List<Map<String, dynamic>>> daysMap = {};
    if (state is PontoHistoryLoaded) {
      daysMap = state.daysMap;
    } else if (state is PontoHistoryActionSuccess) {
      daysMap = state.daysMap;
    } else if (state is PontoHistoryActionError) {
      daysMap = state.daysMap;
    } else if (state is PontoHistoryActionProcessing) {
      daysMap = state.daysMap;
    }

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

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PontoHistoryBloc>().add(
              LoadHistoryEvent(
                uid: widget.targetUid,
                month: _currentMonth,
              ),
            );
      },
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: allDays.length,
        itemBuilder: (context, index) {
          final diaId = allDays[index];
          final eventos = daysMap[diaId] ?? [];

          return DayCard(
            diaId: diaId,
            eventos: eventos,
            isAdmin: isAdmin,
            onAddEvento:
                isAdmin ? () => _showAddDialogForDay(context, diaId) : null,
            onEditEvento: isAdmin
                ? (evento) => _showEditDialog(context, diaId, evento)
                : null,
            onDeleteEvento: isAdmin
                ? (evento) => _showDeleteConfirm(context, diaId, evento)
                : null,
          );
        },
      ),
    );
  }
}
