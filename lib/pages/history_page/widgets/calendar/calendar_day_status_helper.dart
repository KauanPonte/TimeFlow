import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:table_calendar/table_calendar.dart';
import '../card/widgets/day_card_helpers.dart';

enum CalendarDayStatus {
  none,
  complete,
  incomplete,
  pending,
  incompleteWithPending,
}

class CalendarDayStatusHelper {
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final Set<String> pendingDayIds;
  final String Function(DateTime day) dayIdFor;
  final bool Function(DateTime day) isFutureDate;
  final Set<String> holidayDayIds;

  const CalendarDayStatusHelper({
    required this.daysMap,
    required this.pendingDayIds,
    required this.dayIdFor,
    required this.isFutureDate,
    this.holidayDayIds = const {},
  });

  bool isHoliday(DateTime day) {
    return holidayDayIds.contains(dayIdFor(day));
  }

  List<Map<String, dynamic>> eventLoader(DateTime day) {
    final dayId = dayIdFor(day);
    final eventos = daysMap[dayId] ?? const <Map<String, dynamic>>[];
    if (pendingDayIds.contains(dayId) && eventos.isEmpty) {
      return const <Map<String, dynamic>>[
        {'_pendingOnly': true},
      ];
    }
    return eventos;
  }

  CalendarDayStatus statusForDay(DateTime day) {
    final dayId = dayIdFor(day);
    final eventos = daysMap[dayId] ?? const <Map<String, dynamic>>[];
    final hasPending = pendingDayIds.contains(dayId);

    if (eventos.isEmpty) {
      return hasPending ? CalendarDayStatus.pending : CalendarDayStatus.none;
    }

    final now = DateTime.now();
    final isToday =
        day.year == now.year && day.month == now.month && day.day == now.day;
    final incomplete = isIncomplete(
      eventos,
      isToday: isToday,
      isFuture: isFutureDate(day),
    );

    if (incomplete && hasPending) {
      return CalendarDayStatus.incompleteWithPending;
    }

    if (incomplete) {
      return CalendarDayStatus.incomplete;
    }

    if (hasPending) {
      return CalendarDayStatus.pending;
    }

    return CalendarDayStatus.complete;
  }

  CalendarBuilders<Map<String, dynamic>> builders({
    required DateTime selectedDay,
  }) {
    return CalendarBuilders<Map<String, dynamic>>(
      markerBuilder: (context, day, _) {
        final holiday = isHoliday(day);
        final status = statusForDay(day);

        if (holiday) return _buildHolidayMarker();
        if (status == CalendarDayStatus.none) return const SizedBox.shrink();

        return _buildDayMarker(status);
      },
      defaultBuilder: (context, day, _) => _buildDayCell(
        day: day,
        status: statusForDay(day),
        isHoliday: isHoliday(day),
      ),
      todayBuilder: (context, day, _) => _buildDayCell(
        day: day,
        status: statusForDay(day),
        isToday: true,
        isHoliday: isHoliday(day),
      ),
      selectedBuilder: (context, day, _) => _buildDayCell(
        day: day,
        status: statusForDay(day),
        isSelected: isSameDay(day, selectedDay),
        isHoliday: isHoliday(day),
      ),
    );
  }

  Widget _buildDayCell({
    required DateTime day,
    required CalendarDayStatus status,
    bool isToday = false,
    bool isSelected = false,
    bool isHoliday = false,
  }) {
    final isWarning = _isWarningStatus(status);
    final isFuture = isFutureDate(day);

    BoxDecoration? decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: isHoliday
            ? Colors.green.withValues(alpha: 0.15)
            : isWarning
                ? AppColors.warningLight20
                : AppColors.primaryLight10,
        shape: BoxShape.circle,
        border: Border.all(
          color: isHoliday
              ? Colors.green
              : isWarning
                  ? AppColors.warning
                  : AppColors.primary,
        ),
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        color: isHoliday
            ? Colors.green.withValues(alpha: 0.08)
            : isWarning
                ? AppColors.warningLight10
                : AppColors.primaryLight10,
        shape: BoxShape.circle,
        border: Border.all(
          color: (isHoliday
                  ? Colors.green
                  : isWarning
                      ? AppColors.warning
                      : AppColors.primary)
              .withValues(alpha: 0.45),
        ),
      );
    }

    final textColor = isFuture
        ? AppColors.textSecondary.withValues(alpha: 0.45)
        : isHoliday
            ? Colors.green[700]!
            : isWarning
                ? AppColors.warning
                : AppColors.textPrimary;

    return Container(
      alignment: Alignment.center,
      margin: const EdgeInsets.all(6),
      decoration: decoration,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: textColor,
          fontWeight:
              isHoliday || isWarning ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  bool _isWarningStatus(CalendarDayStatus status) {
    return status == CalendarDayStatus.incomplete ||
        status == CalendarDayStatus.pending ||
        status == CalendarDayStatus.incompleteWithPending;
  }

  Widget _buildHolidayMarker() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildDayMarker(CalendarDayStatus status) {
    final warning = _isWarningStatus(status);
    final color = warning ? AppColors.warning : AppColors.primary;

    if (status == CalendarDayStatus.pending) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(bottom: 5),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.6),
          ),
        ),
      );
    }

    if (status == CalendarDayStatus.incompleteWithPending) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 9,
          height: 9,
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.6),
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: 7,
        height: 7,
        margin: const EdgeInsets.only(bottom: 5),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
