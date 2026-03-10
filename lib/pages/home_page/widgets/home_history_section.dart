import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:flutter_application_appdeponto/widgets/custom_snackbar.dart';
import 'package:flutter_application_appdeponto/services/ponto_edit_dialogs.dart';
import '../../history_page/widgets/day_card.dart';
import '../../history_page/widgets/month_selector.dart';

class HomeHistorySection extends StatefulWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isAdmin;
  final String? uid;
  final List<String> Function() generateMonthDays;
  final VoidCallback onActionSuccess;

  /// Dia que deve receber destaque visual e scroll (ISO 'yyyy-MM-dd').
  final String? highlightDayId;

  const HomeHistorySection({
    super.key,
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.isAdmin,
    required this.generateMonthDays,
    required this.onActionSuccess,
    this.uid,
    this.highlightDayId,
  });

  @override
  State<HomeHistorySection> createState() => _HomeHistorySectionState();
}

class _HomeHistorySectionState extends State<HomeHistorySection> {
  /// GlobalKeys por diaId para `Scrollable.ensureVisible`.
  final Map<String, GlobalKey> _dayKeys = {};

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
    }

    // Highlight mudou → se o histórico já está carregado, scrolla imediatamente.
    if (widget.highlightDayId != oldWidget.highlightDayId &&
        widget.highlightDayId != null) {
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
    return Column(
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
              child:
                  const Icon(Icons.history, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Meu Histórico',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
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
            if (state is PontoHistoryLoaded && widget.highlightDayId != null) {
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

            final allDays = widget.generateMonthDays();

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

            return Column(
              children: allDays.map((diaId) {
                final eventos = daysMap[diaId] ?? [];
                final isHighlight = diaId == widget.highlightDayId;
                return DayCard(
                  key: isHighlight ? _keyForDay(diaId) : null,
                  diaId: diaId,
                  eventos: eventos,
                  isAdmin: widget.isAdmin,
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
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
