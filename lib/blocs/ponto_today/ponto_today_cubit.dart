import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';
import 'ponto_today_state.dart';

/// Cubit global que mantém os dados de ponto do dia atual.
class PontoTodayCubit extends Cubit<PontoTodayState> {
  final PontoDataChangedCubit _dataChangedCubit;
  StreamSubscription<DateTime>? _dataChangedSub;
  Timer? _cutoffTimer;
  String? _cutoffScheduledDayId;
  bool _loadedOnce = false;

  /// Quando o cubit é criado, ele não tem dados e está em loading = false. O método [load]
  bool get hasLoadedOnce => _loadedOnce;

  PontoTodayCubit({required PontoDataChangedCubit dataChangedCubit})
      : _dataChangedCubit = dataChangedCubit,
        super(const PontoTodayState()) {
    _dataChangedSub = _dataChangedCubit.stream.listen((_) => refresh());
  }

  /// Carrega todos os dados do dia.
  /// Retorna assim que os dados essenciais estiverem disponíveis (loading = false).
  /// O saldo acumulado é calculado em background após o retorno.
  Future<void> load() async {
    if (!_loadedOnce) {
      emit(state.copyWith(loading: true));
    }
    await _fetchEssentialData();
    // Saldo acumulado é pesado — roda em background sem bloquear.
    _updateBalanceInBackground();
  }

  /// Atualiza silenciosamente os eventos do dia (sem recalcular o saldo).
  Future<void> refresh() async {
    await _fetchEssentialData();
  }

  /// Carrega APENAS os dados essenciais da UI e emite loading = false.
  /// Operações pesadas (recálculo de faltas, saldo) ficam fora deste método.
  Future<void> _fetchEssentialData() async {
    try {
      // Fire-and-forget: recálculo de faltas roda em background.
      // NÃO entra no Future.wait, para não atrasar o carregamento da UI.
      PontoService.recalcularFaltasMesAtual().catchError((_) {});

      // Queries de dados da UI — todas em paralelo.
      final results = await Future.wait([
        PontoService.loadEventosHoje(), // 0
        PontoService.getLockedWorkModeHoje(), // 1
        PontoService.loadRegistros(), // 2
        PontoService.getResumoMesAtual(), // 3
        PontoService.getCargaHorariaUsuarioAtual(), // 4
        PontoService.isFeriado(ServerTimeService.now()), // 5
      ]);

      _loadedOnce = true;

      if (!isClosed) {
        final eventos = results[0] as List<Map<String, dynamic>>;
        final lockedWorkMode = results[1] as String?;
        final registros = results[2] as Map<String, Map<String, String>>;
        final mesResumo = results[3] as MesResumo;
        final workloadMinutes = results[4] as int;
        final isFeriadoHoje = results[5] as bool;

        _scheduleCutoffRefresh();

        // Formata os eventos aqui mesmo para evitar query duplicada
        final eventosFormatados = eventos.map((m) {
          final at = m['at'];
          final hora =
              at is Timestamp ? DateFormat('HH:mm').format(at.toDate()) : '';
          return {
            'tipo': m['tipo'].toString(),
            'hora': hora,
            'workMode': m['workMode'].toString(),
            'origin': m['origin'].toString(),
          };
        }).toList();

        emit(PontoTodayState(
          loading: false,
          eventosHoje: eventos,
          eventosHojeFormatados: eventosFormatados,
          ultimoTipo:
              eventos.isNotEmpty ? eventos.last['tipo'].toString() : null,
          lockedWorkMode: lockedWorkMode,
          registros: registros,
          monthBalance: state.monthBalance,
          monthWorkedMinutes: mesResumo.workedMinutes,
          monthExpectedMinutes: mesResumo.expectedMinutes,
          monthBusinessDays: mesResumo.businessDaysTotal,
          workloadMinutes: workloadMinutes,
          isFeriadoHoje: isFeriadoHoje,
        ));
      }
    } catch (_) {
      if (!isClosed && state.loading) {
        emit(state.copyWith(loading: false));
      }
    }
  }

  /// Recalcula o saldo acumulado total em background e atualiza o estado.
  void _updateBalanceInBackground() {
    PontoService.calcularSaldoAcumuladoTotal().then((saldoMinutes) {
      if (!isClosed) {
        emit(state.copyWith(monthBalance: saldoMinutes.toDouble()));
      }
    }).catchError((_) {});
  }

  /// Limpa todos os dados (chamado no logout).
  void clear() {
    _loadedOnce = false;
    _cutoffTimer?.cancel();
    _cutoffTimer = null;
    _cutoffScheduledDayId = null;
    emit(const PontoTodayState());
  }

  /// Registra ponto, atualiza dados e notifica outras telas.
  Future<PontoResult> registrar(String tipo, {required String workMode}) async {
    final result = await PontoService.registrarPonto(tipo, workMode: workMode);
    if (result.success) {
      await _fetchEssentialData();
      if (tipo == 'saida') _updateBalanceInBackground();
      _dataChangedCubit.notifyChanged();
    }
    return result;
  }

  @override
  Future<void> close() {
    _dataChangedSub?.cancel();
    _cutoffTimer?.cancel();
    return super.close();
  }

  void _scheduleCutoffRefresh() {
    final now = ServerTimeService.now();
    final todayId =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (_cutoffScheduledDayId == todayId) return;

    final cutoff = DateTime(now.year, now.month, now.day, 18, 0);
    if (!now.isBefore(cutoff)) return;

    _cutoffTimer?.cancel();
    _cutoffScheduledDayId = todayId;
    _cutoffTimer = Timer(cutoff.difference(now), () async {
      if (isClosed) return;
      await refresh();
    });
  }
}
