import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/services/pdf_service.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/theme/app_text_styles.dart';
import 'package:intl/intl.dart';
import 'history_shared_utils.dart';

class PdfPreviewModal {
  PdfPreviewModal._();

  /// Exibe o modal de preview do espelho mensal e permite exportar PDF.
  static Future<void> show({
    required BuildContext context,
    required DateTime currentMonth,
    required Map<String, List<Map<String, dynamic>>> punchRecords,
    required Future<MesResumo>? mesResumoFuture,
    required Map<DateTime, List<Map<String, dynamic>>> allCalendarEvents,
    required Set<String> excusedDayIds,
    required String userName,
  }) async {
    if (mesResumoFuture == null) return;
    final resumo = await mesResumoFuture;
    final dailyWorkload = resumo.businessDaysTotal > 0
        ? (resumo.expectedMinutes ~/ resumo.businessDaysTotal)
        : 8 * 60;

    final ultimoDiaMes =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final hojeApenasData =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    List<Widget> tableRows = [];
    tableRows.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: AppColors.bgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text('Data',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              flex: 5,
              child: Text('Registros',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              flex: 3,
              child: Text('Obs',
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    for (int i = ultimoDiaMes; i >= 1; i--) {
      final date = DateTime(currentMonth.year, currentMonth.month, i);
      if (date.isAfter(hojeApenasData)) continue;

      final diaId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final registros = punchRecords[diaId];

      final isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      String? holidayName = allCalendarEvents[date]?.first['title']?.toString();
      if (holidayName == null && excusedDayIds.contains(diaId)) {
        holidayName = 'Ponto Facultativo (Atestado)';
      }
      final isWorkDay = !isWeekend && holidayName == null;
      final effectiveLoad = isWorkDay ? dailyWorkload : 0;

      final p = PdfService.processDayDetails(
          registros ?? [], effectiveLoad, isWorkDay, holidayName);
      final isExtra = p['obs']!.startsWith('Extra');
      final isDebito = p['obs']!.startsWith('Débito');
      final obsColor = isExtra
          ? AppColors.success
          : isDebito
              ? AppColors.error
              : AppColors.textSecondary;

      tableRows.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderLight)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
                  style: AppTextStyles.h3.copyWith(fontSize: 14),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(p['registros']!, style: AppTextStyles.bodySmall),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  p['obs']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: obsColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Espelho Mensal', style: AppTextStyles.h2),
                          Text(
                            DateFormat("MMMM 'de' yyyy", 'pt_BR')
                                .format(currentMonth)
                                .replaceFirstMapped(RegExp(r'^([a-z])'),
                                    (m) => m[1]!.toUpperCase()),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    )
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: tableRows,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, -4),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Exportar PDF'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await PdfService.generateUserHistoryPdf(
                      userName: userName,
                      selectedDate: currentMonth,
                      workloadMinutes: dailyWorkload,
                      punchRecords: punchRecords,
                      calendarBlockedDays: {
                        ...allCalendarEvents.keys
                            .map((d) => HistorySharedUtils.toDayId(d))
                            .fold<Map<String, String>>({}, (acc, id) {
                          final date = DateTime.parse(id);
                          acc[id] = allCalendarEvents[date]?.first['title'] ??
                              'Feriado';
                          return acc;
                        }),
                        for (final id in excusedDayIds)
                          if (!allCalendarEvents.keys
                              .map(HistorySharedUtils.toDayId)
                              .contains(id))
                            id: 'Ponto Facultativo (Atestado)',
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
