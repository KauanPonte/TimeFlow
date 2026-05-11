import 'package:flutter/material.dart';
import 'package:flutter_application_appdeponto/theme/app_colors.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';
import 'package:table_calendar/table_calendar.dart';
import '../card/widgets/day_card_helpers.dart';

const _justifiedColor = AppColors.error;

enum CalendarDayStatus {
  none,
  complete,
  incomplete,
  pending,
  incompleteWithPending,
  holiday,
  justifiedAbsence,
}

class CalendarDayStatusHelper {
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final Set<String> pendingDayIds;
  final String Function(DateTime day) dayIdFor;
  final bool Function(DateTime day) isFutureDate;
  final Set<String> holidayDayIds;
  final Set<String> justifiedAbsenceDayIds;
  final Map<DateTime, List<Map<String, dynamic>>> calendarEvents;

  const CalendarDayStatusHelper({
    required this.daysMap,
    required this.pendingDayIds,
    required this.dayIdFor,
    required this.isFutureDate,
    required this.calendarEvents,
    this.holidayDayIds = const {},
    this.justifiedAbsenceDayIds = const {},
  });

  bool isHoliday(DateTime day) {
    return holidayDayIds.contains(dayIdFor(day));
  }

  List<Map<String, dynamic>> eventLoader(DateTime day) {
    final dayId = dayIdFor(day);
    final eventos = daysMap[dayId] ?? [];

    // Inclui feriados/recessos para garantir que o TableCalendar mostre marcadores
    final holidayEvents = calendarEvents[normalizeDay(day)] ?? [];

    if (pendingDayIds.contains(dayId) && eventos.isEmpty) {
      return [
        {'_pendingOnly': true},
        ...holidayEvents,
      ];
    }

    return [...eventos, ...holidayEvents];
  }

  static DateTime normalizeDay(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  CalendarDayStatus statusForDay(DateTime day) {
    final dayId = dayIdFor(day);
    final eventos = daysMap[dayId] ?? const <Map<String, dynamic>>[];
    final hasPending = pendingDayIds.contains(dayId);

    if (eventos.isEmpty) {
      if (justifiedAbsenceDayIds.contains(dayId)) {
        return CalendarDayStatus.justifiedAbsence;
      }
      return hasPending ? CalendarDayStatus.pending : CalendarDayStatus.none;
    }

    final now = ServerTimeService.nowBrazilUtc();
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

    if (isHoliday(day)) {
      return CalendarDayStatus.holiday;
    }

    return CalendarDayStatus.complete;
  }

  CalendarBuilders<Map<String, dynamic>> builders({
    required DateTime selectedDay,
  }) {
    return CalendarBuilders<Map<String, dynamic>>(
      markerBuilder: (context, day, _) => const SizedBox.shrink(),
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
    final isJustified = status == CalendarDayStatus.justifiedAbsence;
    final isFuture =
        isFutureDate(day) && !isHoliday; // Feriados futuros ficam normais

    Color accentColor() {
      if (isHoliday) return Colors.green;
      if (isJustified) return _justifiedColor;
      if (isWarning) return AppColors.warning;
      return AppColors.primary;
    }

    BoxDecoration? decoration;
    if (isSelected) {
      decoration = BoxDecoration(
        color: isHoliday
            ? Colors.green.withValues(alpha: 0.15)
            : isJustified
                ? AppColors.errorLight20
                : isWarning
                    ? AppColors.warningLight20
                    : AppColors.primaryLight10,
        shape: BoxShape.circle,
        border: Border.all(color: accentColor()),
      );
    } else if (isToday) {
      decoration = BoxDecoration(
        color: isHoliday
            ? Colors.green.withValues(alpha: 0.08)
            : isJustified
                ? AppColors.errorLight10
                : isWarning
                    ? AppColors.warningLight10
                    : AppColors.primaryLight10,
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor().withValues(alpha: 0.45),
        ),
      );
    }

    Color textColor = isHoliday
        ? Colors.green[700]!
        : isJustified
            ? _justifiedColor
            : isWarning
                ? AppColors.warning
                : Colors.black;

    // Se for futuro e não for feriado, acinzenta
    if (isFuture) {
      textColor = AppColors.textSecondary.withValues(alpha: 0.4);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: decoration,
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontWeight: (isWarning || isJustified)
                  ? FontWeight.w700
                  : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 2),
        if (status != CalendarDayStatus.none)
          _buildDayMarkerInline(status)
        else
          const SizedBox(height: 6),
      ],
    );
  }

  bool _isWarningStatus(CalendarDayStatus status) {
    return status == CalendarDayStatus.incomplete ||
        status == CalendarDayStatus.pending ||
        status == CalendarDayStatus.incompleteWithPending;
  }

  Widget _buildDayMarkerInline(CalendarDayStatus status) {
    final warning = _isWarningStatus(status);
    final color = warning ? AppColors.warning : AppColors.primary;

    if (status == CalendarDayStatus.justifiedAbsence) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: _justifiedColor,
          shape: BoxShape.circle,
        ),
      );
    }

    if (status == CalendarDayStatus.pending) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
        ),
      );
    }

    if (status == CalendarDayStatus.incompleteWithPending) {
      return Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 1.4),
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
      );
    }

    if (status == CalendarDayStatus.holiday) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.6),
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
