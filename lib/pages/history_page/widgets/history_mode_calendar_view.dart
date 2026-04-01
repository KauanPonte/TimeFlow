import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar/calendar_day_status_helper.dart';

class HistoryModeCalendarView extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final String Function(DateTime day) dayIdFor;
  final bool Function(DateTime day) isFutureDate;
  final Set<String> pendingDayIds;
  final ValueChanged<DateTime> onDaySelected;
  final Widget Function(String dayId) dayBuilder;
  final Future<void> Function()? onRefresh;
  final Set<String> holidayDayIds;

  const HistoryModeCalendarView({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.daysMap,
    required this.dayIdFor,
    required this.isFutureDate,
    this.pendingDayIds = const {},
    required this.onDaySelected,
    required this.dayBuilder,
    this.holidayDayIds = const {},
    this.onRefresh,
    required Map<DateTime, List<Map<String, dynamic>>> calendarEvents,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = dayIdFor(selectedDay);
    final statusHelper = CalendarDayStatusHelper(
      daysMap: daysMap,
      pendingDayIds: pendingDayIds,
      dayIdFor: dayIdFor,
      isFutureDate: isFutureDate,
      holidayDayIds: holidayDayIds,
    );

    final content = <Widget>[
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TableCalendar<Map<String, dynamic>>(
          locale: 'pt_BR',
          firstDay: DateTime(month.year, month.month, 1),
          lastDay: DateTime(month.year, month.month + 1, 0),
          availableGestures: AvailableGestures.none,
          focusedDay: selectedDay,
          selectedDayPredicate: (day) => isSameDay(day, selectedDay),
          availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
          calendarFormat: CalendarFormat.month,
          //enabledDayPredicate: (day) => !isFutureDate(day),
          eventLoader: statusHelper.eventLoader,

          onDaySelected: (selected, _) {
            final isFuture = isFutureDate(selected);
            final isHoliday = statusHelper.isHoliday(selected);
            final status = statusHelper.statusForDay(selected);

            final isAdminMarked = status != CalendarDayStatus.none;

            if (isFuture && !isHoliday && !isAdminMarked) return;

            onDaySelected(
              DateTime(selected.year, selected.month, selected.day),
            );
          },
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            leftChevronVisible: false,
            rightChevronVisible: false,
            titleTextFormatter: (date, locale) => '',
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            disabledTextStyle: const TextStyle(
              color: Colors.black,
            ),
            todayDecoration: BoxDecoration(
              color: AppColors.primaryLight10,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
            selectedDecoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary),
            ),
            markersMaxCount: 1,
          ),
          calendarBuilders: statusHelper.builders(
            selectedDay: selectedDay,
          ),
        ),
      ),
      const SizedBox(height: 10),
      dayBuilder(selectedId),
    ];

    if (onRefresh == null) {
      return Column(children: content);
    }

    return RefreshIndicator(
      onRefresh: onRefresh!,
      color: AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: content,
      ),
    );
  }
}
