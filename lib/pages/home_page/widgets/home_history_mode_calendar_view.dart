import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../history_page/widgets/calendar/calendar_day_status_helper.dart';

class HomeHistoryModeCalendarView extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDay;
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final String Function(DateTime day) dayIdFor;
  final bool Function(DateTime day) isFutureDate;
  final Set<String> pendingDayIds;
  final ValueChanged<DateTime> onDaySelected;
  final Widget Function(String dayId) dayBuilder;

  const HomeHistoryModeCalendarView({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.daysMap,
    required this.dayIdFor,
    required this.isFutureDate,
    this.pendingDayIds = const {},
    required this.onDaySelected,
    required this.dayBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = dayIdFor(selectedDay);
    final statusHelper = CalendarDayStatusHelper(
      daysMap: daysMap,
      pendingDayIds: pendingDayIds,
      dayIdFor: dayIdFor,
      isFutureDate: isFutureDate,
    );

    return Column(
      children: [
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
            focusedDay: selectedDay,
            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
            availableCalendarFormats: const {CalendarFormat.month: 'Mês'},
            calendarFormat: CalendarFormat.month,
            enabledDayPredicate: (day) => !isFutureDate(day),
            eventLoader: statusHelper.eventLoader,
            onDaySelected: (selected, _) {
              if (isFutureDate(selected)) return;
              onDaySelected(
                  DateTime(selected.year, selected.month, selected.day));
            },
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              leftChevronVisible: false,
              rightChevronVisible: false,
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
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
      ],
    );
  }
}
