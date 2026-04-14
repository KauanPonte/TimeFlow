import 'package:equatable/equatable.dart';

class PontoTodayState extends Equatable {
  final bool loading;
  final List<Map<String, dynamic>> eventosHoje;
  final List<Map<String, String>> eventosHojeFormatados;
  final String? ultimoTipo;
  final String? lockedWorkMode;
  final Map<String, Map<String, String>> registros;
  final double monthBalance;
  final int monthWorkedMinutes;
  final int monthExpectedMinutes;
  final int monthBusinessDays;
  final int workloadMinutes;
  final bool isFeriadoHoje;

  const PontoTodayState({
    this.loading = true,
    this.eventosHoje = const [],
    this.eventosHojeFormatados = const [],
    this.ultimoTipo,
    this.lockedWorkMode,
    this.registros = const {},
    this.monthBalance = 0.0,
    this.monthWorkedMinutes = 0,
    this.monthExpectedMinutes = 0,
    this.monthBusinessDays = 0,
    this.workloadMinutes = 8 * 60,
    this.isFeriadoHoje = false,
  });

  PontoTodayState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? eventosHoje,
    List<Map<String, String>>? eventosHojeFormatados,
    String? ultimoTipo,
    bool clearUltimoTipo = false,
    String? lockedWorkMode,
    bool clearLockedWorkMode = false,
    Map<String, Map<String, String>>? registros,
    double? monthBalance,
    int? monthWorkedMinutes,
    int? monthExpectedMinutes,
    int? monthBusinessDays,
    int? workloadMinutes,
    bool? isFeriadoHoje,
  }) {
    return PontoTodayState(
      loading: loading ?? this.loading,
      eventosHoje: eventosHoje ?? this.eventosHoje,
      eventosHojeFormatados:
          eventosHojeFormatados ?? this.eventosHojeFormatados,
      ultimoTipo: clearUltimoTipo ? null : (ultimoTipo ?? this.ultimoTipo),
      lockedWorkMode:
          clearLockedWorkMode ? null : (lockedWorkMode ?? this.lockedWorkMode),
      registros: registros ?? this.registros,
      monthBalance: monthBalance ?? this.monthBalance,
      monthWorkedMinutes: monthWorkedMinutes ?? this.monthWorkedMinutes,
      monthExpectedMinutes: monthExpectedMinutes ?? this.monthExpectedMinutes,
      monthBusinessDays: monthBusinessDays ?? this.monthBusinessDays,
      workloadMinutes: workloadMinutes ?? this.workloadMinutes,
      isFeriadoHoje: isFeriadoHoje ?? this.isFeriadoHoje,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        eventosHoje,
        eventosHojeFormatados,
        ultimoTipo,
        lockedWorkMode,
        registros,
        monthBalance,
        monthWorkedMinutes,
        monthExpectedMinutes,
        monthBusinessDays,
        workloadMinutes,
        isFeriadoHoje,
      ];
}
