import 'package:flutter_application_appdeponto/blocs/ponto_history/ponto_history_state.dart';
import 'package:intl/intl.dart';

class HistorySharedUtils {
  const HistorySharedUtils._();

  static DateTime normalizeDay(DateTime day) {
    return DateTime(day.year, day.month, day.day);
  }

  static DateTime today() {
    return normalizeDay(DateTime.now());
  }

  static DateTime defaultSelectedDayForMonth(DateTime month) {
    final monthLastDay = DateTime(month.year, month.month + 1, 0);
    final normalizedLastDay = normalizeDay(monthLastDay);
    final todayDay = today();
    return normalizedLastDay.isAfter(todayDay) ? todayDay : normalizedLastDay;
  }

  static String toDayId(DateTime day) {
    return DateFormat('yyyy-MM-dd').format(normalizeDay(day));
  }

  static bool isFutureDate(DateTime day) {
    return normalizeDay(day).isAfter(today());
  }

  static List<String> generateMonthDays(DateTime month) {
    final todayDay = today();
    final monthLastDay = DateTime(month.year, month.month + 1, 0).day;

    final days = <String>[];
    for (int d = monthLastDay; d >= 1; d--) {
      final date = DateTime(month.year, month.month, d);
      if (normalizeDay(date).isAfter(todayDay)) continue;
      days.add(toDayId(date));
    }
    return days;
  }

  static Map<String, List<Map<String, dynamic>>> daysMapFromState(
    PontoHistoryState state,
  ) {
    if (state is PontoHistoryLoaded) return state.daysMap;
    if (state is PontoHistoryActionSuccess) return state.daysMap;
    if (state is PontoHistoryActionError) return state.daysMap;
    if (state is PontoHistoryActionProcessing) return state.daysMap;
    return {};
  }
}
