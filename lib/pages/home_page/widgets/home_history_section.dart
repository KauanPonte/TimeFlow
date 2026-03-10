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

class HomeHistorySection extends StatelessWidget {
  final DateTime currentMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isAdmin;
  final String? uid;
  final List<String> Function() generateMonthDays;
  final VoidCallback onActionSuccess;

  const HomeHistorySection({
    super.key,
    required this.currentMonth,
    required this.onPrevious,
    required this.onNext,
    required this.isAdmin,
    required this.generateMonthDays,
    required this.onActionSuccess,
    this.uid,
  });

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
          currentMonth: currentMonth,
          onPrevious: onPrevious,
          onNext: onNext,
        ),
        const SizedBox(height: 8),
        BlocConsumer<PontoHistoryBloc, PontoHistoryState>(
          listener: (context, state) {
            if (state is PontoHistoryActionSuccess) {
              CustomSnackbar.showSuccess(context, state.message);
              onActionSuccess();
            } else if (state is PontoHistoryActionError) {
              CustomSnackbar.showError(context, state.message);
            } else if (state is PontoHistoryError) {
              CustomSnackbar.showError(context, state.message);
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
            }

            final allDays = generateMonthDays();

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

            final canEdit = isAdmin && uid != null;

            return Column(
              children: allDays.map((diaId) {
                final eventos = daysMap[diaId] ?? [];
                return DayCard(
                  diaId: diaId,
                  eventos: eventos,
                  isAdmin: isAdmin,
                  onAddEvento: canEdit
                      ? () => showPontoAddDialog(
                            context: context,
                            uid: uid!,
                            diaId: diaId,
                          )
                      : null,
                  onEditEvento: canEdit
                      ? (ev) => showPontoEditDialog(
                            context: context,
                            uid: uid!,
                            diaId: diaId,
                            evento: ev,
                          )
                      : null,
                  onDeleteEvento: canEdit
                      ? (ev) => showPontoDeleteConfirm(
                            context: context,
                            uid: uid!,
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
