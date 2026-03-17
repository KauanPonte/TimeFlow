import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'ponto_today_state.dart';

/// Cubit global que mantém os dados de ponto do dia atual.
class PontoTodayCubit extends Cubit<PontoTodayState> {
  final PontoDataChangedCubit _dataChangedCubit;
  StreamSubscription<DateTime>? _dataChangedSub;
  Timer? _cutoffTimer;
  String? _cutoffScheduledDayId;
  bool _loadedOnce = false;

  PontoTodayCubit({required PontoDataChangedCubit dataChangedCubit})
      : _dataChangedCubit = dataChangedCubit,
        super(const PontoTodayState()) {
    _dataChangedSub = _dataChangedCubit.stream.listen((_) => refresh());
  }

  /// Carrega todos os dados do dia.
  Future<void> load() async {
    if (!_loadedOnce) {
      emit(state.copyWith(loading: true));
    }
    await _fetchAll();
  }

  /// Atualiza silenciosamente (sem trocar loading para true).
  Future<void> refresh() async {
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    try {
      await PontoService.recalcularFaltasMesAtual();
      final results = await Future.wait([
        PontoService.loadEventosHoje(),
        PontoService.loadEventosHojeFormatados(),
        PontoService.getUltimoTipoHoje(),
        PontoService.loadRegistros(),
        PontoService.getSaldoMesAtualHoras(),
        PontoService.getLockedWorkModeHoje(),
        PontoService.getResumoMesAtual(),
      ]);

      _loadedOnce = true;

      if (!isClosed) {
        final ultimoTipo = results[2] as String?;
        final mesResumo = results[6] as MesResumo;

        _scheduleCutoffRefresh();

        emit(PontoTodayState(
          loading: false,
          eventosHoje: results[0] as List<Map<String, dynamic>>,
          eventosHojeFormatados: results[1] as List<Map<String, String>>,
          ultimoTipo: ultimoTipo,
          lockedWorkMode: results[5] as String?,
          registros: results[3] as Map<String, Map<String, String>>,
          monthBalance: results[4] as double,
          monthWorkedMinutes: mesResumo.workedMinutes,
          monthExpectedMinutes: mesResumo.expectedMinutes,
          monthBusinessDays: mesResumo.businessDaysTotal,
        ));
      }
    } catch (_) {
      // Mantém estado atual em caso de erro; apenas sai do loading.
      if (!isClosed && state.loading) {
        emit(state.copyWith(loading: false));
      }
    }
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
      await _fetchAll();
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
    final now = DateTime.now();
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
