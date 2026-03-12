import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/services/ponto_service.dart';
import 'ponto_today_state.dart';

/// Cubit global que mantém os dados de ponto do dia atual.
///
/// Persiste entre trocas de tela e se atualiza silenciosamente
/// quando [PontoDataChangedCubit] sinaliza alterações.
class PontoTodayCubit extends Cubit<PontoTodayState> {
  final PontoDataChangedCubit _dataChangedCubit;
  StreamSubscription<DateTime>? _dataChangedSub;
  bool _loadedOnce = false;

  PontoTodayCubit({required PontoDataChangedCubit dataChangedCubit})
      : _dataChangedCubit = dataChangedCubit,
        super(const PontoTodayState()) {
    _dataChangedSub = _dataChangedCubit.stream.listen((_) => refresh());
  }

  /// Carrega todos os dados do dia.
  /// Na primeira chamada exibe loading; nas seguintes mostra os dados em
  /// cache enquanto busca dados novos em background.
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
      final results = await Future.wait([
        PontoService.loadEventosHoje(),
        PontoService.loadEventosHojeFormatados(),
        PontoService.getUltimoTipoHoje(),
        PontoService.loadRegistros(),
        PontoService.getSaldoMesAtualHoras(),
      ]);

      _loadedOnce = true;

      if (!isClosed) {
        final ultimoTipo = results[2] as String?;

        emit(PontoTodayState(
          loading: false,
          eventosHoje: results[0] as List<Map<String, dynamic>>,
          eventosHojeFormatados: results[1] as List<Map<String, String>>,
          ultimoTipo: ultimoTipo,
          registros: results[3] as Map<String, Map<String, String>>,
          monthBalance: results[4] as double,
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
    emit(const PontoTodayState());
  }

  /// Registra ponto, atualiza dados e notifica outras telas.
  /// Retorna [PontoResult] para exibição de snackbar pelo chamador.
  Future<PontoResult> registrar(String tipo) async {
    final result = await PontoService.registrarPonto(tipo);
    if (result.success) {
      await _fetchAll();
      _dataChangedCubit.notifyChanged();
    }
    return result;
  }

  @override
  Future<void> close() {
    _dataChangedSub?.cancel();
    return super.close();
  }
}
