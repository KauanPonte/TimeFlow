import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
        PontoService.getLockedWorkModeHoje(),
        PontoService.getResumoMesAtual(),
        PontoService.getCargaHorariaUsuarioAtual(),
      ]);

      _loadedOnce = true;

      if (!isClosed) {
        final eventos = results[0] as List<Map<String, dynamic>>;
        final lockedWorkMode = results[1] as String?;
        final mesResumo = results[2] as MesResumo;
        final workloadMinutes = results[3] as int;

        _scheduleCutoffRefresh();

        // Formata os eventos aqui mesmo para evitar query duplicada
        final eventosFormatados = eventos.map((m) {
          final at = m['at'];
          final hora = at is Timestamp 
              ? DateFormat('HH:mm').format(at.toDate())
              : '';
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
          ultimoTipo: eventos.isNotEmpty ? eventos.last['tipo'].toString() : null,
          lockedWorkMode: lockedWorkMode,
          monthBalance: mesResumo.monthBalance,
          monthWorkedMinutes: mesResumo.workedMinutes,
          monthExpectedMinutes: mesResumo.expectedMinutes,
          monthBusinessDays: mesResumo.businessDaysTotal,
          workloadMinutes: workloadMinutes,
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
