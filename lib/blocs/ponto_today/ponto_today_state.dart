import 'package:equatable/equatable.dart';

class PontoTodayState extends Equatable {
  final bool loading;
  final List<Map<String, dynamic>> eventosHoje;
  final List<Map<String, String>> eventosHojeFormatados;
  final String? ultimoTipo;
  final String? lockedWorkMode;
  final Map<String, Map<String, String>> registros;
  final double monthBalance;

  const PontoTodayState({
    this.loading = true,
    this.eventosHoje = const [],
    this.eventosHojeFormatados = const [],
    this.ultimoTipo,
    this.lockedWorkMode,
    this.registros = const {},
    this.monthBalance = 0.0,
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
      ];
}
