import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';
import 'ponto_today_state.dart';

/// Cubit global que mantém os dados de ponto do dia atual.
/// Usa stream Firestore: emite do cache local imediatamente (sem spinner na
/// segunda abertura+) e sincroniza automaticamente com qualquer dispositivo.
class PontoTodayCubit extends Cubit<PontoTodayState> {
  final PontoDataChangedCubit _dataChangedCubit;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _diaHojeSub;
  StreamSubscription<DateTime>? _dataChangedSub;
  Timer? _cutoffTimer;
  String? _cutoffScheduledDayId;
  bool _loadedOnce = false;

  // Dados estáticos carregados 1x por sessão de login
  int _workloadMinutes = 8 * 60;
  bool _isFeriadoHoje = false;
  bool _staticDataLoaded = false;

  bool get hasLoadedOnce => _loadedOnce;

  PontoTodayCubit({required PontoDataChangedCubit dataChangedCubit})
      : _dataChangedCubit = dataChangedCubit,
        super(const PontoTodayState()) {
    // Recalcula saldo mensal quando admin edita pontos do mesmo processo
    _dataChangedSub = _dataChangedCubit.stream.listen((_) => _reloadMonthData());
  }

  /// Inicia o stream do dia atual. Na primeira chamada mostra loading;
  /// nas subsequentes os dados do cache local aparecem imediatamente.
  Future<void> load() async {
    if (!_loadedOnce) {
      emit(state.copyWith(loading: true));
    }
    _setupStreams();
  }

  void _setupStreams() {
    _diaHojeSub?.cancel();

    // Dados estáticos: workload e feriado carregados 1x por sessão
    if (!_staticDataLoaded) {
      Future.wait([
        PontoService.getCargaHorariaUsuarioAtual(),
        PontoService.isFeriado(ServerTimeService.todayBrazilDate()),
      ]).then((results) {
        if (isClosed) return;
        _workloadMinutes = results[0] as int;
        _isFeriadoHoje = results[1] as bool;
        _staticDataLoaded = true;
        if (!isClosed) {
          emit(state.copyWith(
            workloadMinutes: _workloadMinutes,
            isFeriadoHoje: _isFeriadoHoje,
          ));
        }
      }).catchError((_) {});
    }

    // Stream do dia atual — primeira emissão vem do cache local (instantânea)
    _diaHojeSub = PontoService.streamDiaHoje().listen(
      _onDiaHojeUpdated,
      onError: (_) {
        if (!isClosed && state.loading) emit(state.copyWith(loading: false));
      },
    );

    _scheduleCutoffRefresh();

    // Fire-and-forget: recálculo de faltas, saldo e resumo em background
    PontoService.recalcularFaltasMesAtual().catchError((_) {});
    _updateBalanceInBackground();
    _reloadMonthData();

    // Registros (todos os dias) carregados lazily para notificações de incompletos
    // Não bloqueia a UI — stream já cuida dos dados do dia atual
    PontoService.loadRegistros().then((registros) {
      if (!isClosed) emit(state.copyWith(registros: registros));
    }).catchError((_) {});
  }

  void _onDiaHojeUpdated(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (isClosed) return;

    final data = snap.data();
    final List<Map<String, dynamic>> eventos;
    final String? lockedWorkMode;

    if (data == null || !snap.exists) {
      eventos = [];
      lockedWorkMode = null;
    } else {
      // Parseia eventosCache — array inline já ordenado por tempo
      final cache = data['eventosCache'];
      if (cache is List && cache.isNotEmpty) {
        eventos = cache.map<Map<String, dynamic>>((e) {
          final m = e as Map<String, dynamic>;
          return {
            'tipo': (m['tipo'] ?? '').toString(),
            'at': m['at'],
            'workMode': (m['workMode'] ?? '').toString(),
            'origin': (m['origin'] ?? 'registrado').toString(),
          };
        }).toList();
      } else {
        eventos = [];
      }

      // Deriva lockedWorkMode de lastTipo + workMode do último evento
      final lastTipo = data['lastTipo']?.toString();
      if (lastTipo == null || lastTipo == 'saida' || eventos.isEmpty) {
        lockedWorkMode = null;
      } else {
        final lastWm = (eventos.last['workMode'] ?? '').toString();
        lockedWorkMode =
            (lastWm == 'presencial' || lastWm == 'remoto') ? lastWm : null;
      }
    }

    // Formata horários para exibição
    final eventosFormatados = eventos.map((m) {
      final at = m['at'];
      final hora = at is Timestamp
          ? DateFormat('HH:mm')
              .format(ServerTimeService.timestampToBrazil(at)!)
          : '';
      return {
        'tipo': m['tipo'].toString(),
        'hora': hora,
        'workMode': m['workMode'].toString(),
        'origin': m['origin'].toString(),
      };
    }).toList();

    _loadedOnce = true;

    emit(PontoTodayState(
      loading: false,
      eventosHoje: eventos,
      eventosHojeFormatados: eventosFormatados,
      ultimoTipo: eventos.isNotEmpty ? eventos.last['tipo'].toString() : null,
      lockedWorkMode: lockedWorkMode,
      registros: state.registros,
      monthBalance: state.monthBalance,
      monthWorkedMinutes: state.monthWorkedMinutes,
      monthExpectedMinutes: state.monthExpectedMinutes,
      monthBusinessDays: state.monthBusinessDays,
      workloadMinutes: _workloadMinutes,
      isFeriadoHoje: _isFeriadoHoje,
    ));
  }

  /// Recalcula resumo mensal em background (workedMinutes, expectedMinutes).
  void _reloadMonthData() {
    PontoService.getResumoMesAtual().then((mesResumo) {
      if (!isClosed) {
        emit(state.copyWith(
          monthWorkedMinutes: mesResumo.workedMinutes,
          monthExpectedMinutes: mesResumo.expectedMinutes,
          monthBusinessDays: mesResumo.businessDaysTotal,
        ));
      }
    }).catchError((_) {});
  }

  /// Recalcula o saldo acumulado total em background.
  void _updateBalanceInBackground() {
    PontoService.calcularSaldoAcumuladoTotal().then((saldoMinutes) {
      if (!isClosed) {
        emit(state.copyWith(monthBalance: saldoMinutes.toDouble()));
      }
    }).catchError((_) {});
  }

  /// Limpa todos os dados e cancela streams (chamado no logout).
  void clear() {
    _loadedOnce = false;
    _staticDataLoaded = false;
    _workloadMinutes = 8 * 60;
    _isFeriadoHoje = false;
    _diaHojeSub?.cancel();
    _diaHojeSub = null;
    _cutoffTimer?.cancel();
    _cutoffTimer = null;
    _cutoffScheduledDayId = null;
    emit(const PontoTodayState());
  }

  /// Atualiza silenciosamente o saldo mensal (pull-to-refresh, ação externa).
  /// Os eventos do dia são gerenciados pelo stream — não precisam de refresh manual.
  Future<void> refresh() async {
    _reloadMonthData();
    _updateBalanceInBackground();
  }

  /// Registra ponto e notifica outras telas.
  /// O stream cuida automaticamente de atualizar os eventos do dia.
  Future<PontoResult> registrar(String tipo, {required String workMode}) async {
    final result = await PontoService.registrarPonto(tipo, workMode: workMode);
    if (result.success) {
      // Stream auto-atualiza eventos — só recalcula o que o stream não cobre
      _reloadMonthData();
      if (tipo == 'saida') _updateBalanceInBackground();
      _dataChangedCubit.notifyChanged();
    }
    return result;
  }

  @override
  Future<void> close() {
    _diaHojeSub?.cancel();
    _dataChangedSub?.cancel();
    _cutoffTimer?.cancel();
    return super.close();
  }

  void _scheduleCutoffRefresh() {
    final now = ServerTimeService.nowBrazilUtc();
    final todayId = ServerTimeService.todayId();
    if (_cutoffScheduledDayId == todayId) return;

    final cutoff = ServerTimeService.brazilTodayUtcAt(18);
    if (!now.isBefore(cutoff)) return;

    _cutoffTimer?.cancel();
    _cutoffScheduledDayId = todayId;
    _cutoffTimer = Timer(cutoff.difference(now), () async {
      if (isClosed) return;
      _reloadMonthData();
    });
  }
}
