import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'ponto_history_event.dart';
import 'ponto_history_state.dart';

class PontoHistoryBloc extends Bloc<PontoHistoryEvent, PontoHistoryState> {
  final PontoHistoryRepository repository;
  final GlobalLoadingCubit? globalLoading;
  StreamSubscription<DateTime>? _dataChangedSub;
  String? _currentUid;
  DateTime _currentMonth = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _lastDaysMap = {};

  /// Cache em memória: chave = "uid_ano_mes" → daysMap do mês.
  /// Permite exibir dados imediatamente ao trocar de mês sem spinner.
  final Map<String, Map<String, List<Map<String, dynamic>>>> _monthCache = {};

  /// Mês atualmente carregado.
  DateTime get currentMonth => _currentMonth;

  /// Gera a chave do cache para o mês/uid indicados.
  String _cacheKey(DateTime month, String? uid) =>
      '${uid ?? 'me'}_${month.year}_${month.month}';

  PontoHistoryBloc({
    required this.repository,
    this.globalLoading,
    PontoDataChangedCubit? dataChangedCubit,
  }) : super(const PontoHistoryInitial()) {
    on<LoadHistoryEvent>(_onLoad);
    on<SilentReloadHistoryEvent>(_onSilentReload);
    on<AddEventoEvent>(_onAdd);
    on<UpdateEventoEvent>(_onUpdate);
    on<DeleteEventoEvent>(_onDelete);
    on<BatchUpdateDayEvent>(_onBatchUpdate);
    on<ResetHistoryEvent>((_, emit) => emit(const PontoHistoryInitial()));

    // Auto-refresh silenciosamente quando dados de ponto mudarem.
    if (dataChangedCubit != null) {
      _dataChangedSub = dataChangedCubit.stream
          .listen((_) => add(const SilentReloadHistoryEvent()));
    }
  }

  Future<void> _onLoad(
    LoadHistoryEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    _currentUid = event.uid;
    _currentMonth = event.month;

    final requestedUid = _currentUid;
    final requestedMonth = _currentMonth;
    final key = _cacheKey(requestedMonth, requestedUid);
    final cached = _monthCache[key];

    // Exibe dados cacheados imediatamente — sem spinner ao trocar de mês.
    if (cached != null) {
      _lastDaysMap = cached;
      emit(PontoHistoryLoaded(daysMap: cached));
    } else {
      emit(const PontoHistoryLoading());
    }

    try {
      final daysMap = await repository.loadDaysByMonth(
        uid: event.uid,
        year: requestedMonth.year,
        month: requestedMonth.month,
      );

      // Cacheia para uso rápido ao navegar entre meses.
      _monthCache[key] = daysMap;

      // Só atualiza a UI se este carregamento ainda for o mês/usuário atual.
      if (requestedUid == _currentUid && requestedMonth == _currentMonth) {
        _lastDaysMap = daysMap;
        emit(PontoHistoryLoaded(daysMap: daysMap));
      }
    } catch (e) {
      // Se não havia cache, exibe erro; caso contrário mantém dados cacheados.
      if (cached == null) {
        emit(PontoHistoryError(
            message: e.toString().replaceAll('Exception: ', '')));
      }
    }
  }


  /// Recarrega sem emitir PontoHistoryLoading — mantém os dados atuais visíveis.
  Future<void> _onSilentReload(
    SilentReloadHistoryEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    try {
      // _currentUid pode ser null → o repositório usa FirebaseAuth.currentUser.
      final daysMap = await repository.loadDaysByMonth(
        uid: _currentUid,
        year: _currentMonth.year,
        month: _currentMonth.month,
      );
      _monthCache[_cacheKey(_currentMonth, _currentUid)] = daysMap;
      _lastDaysMap = daysMap;
      emit(PontoHistoryLoaded(daysMap: daysMap));
    } catch (_) {
      // Silencia erros — mantém o estado atual sem exibir spinner.
    }
  }

  Future<void> _onAdd(
    AddEventoEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    globalLoading?.show('Adicionando ponto...');
    emit(PontoHistoryActionProcessing(
      message: 'Adicionando ponto...',
      daysMap: _lastDaysMap,
    ));
    try {
      await repository.addEvento(
        uid: event.uid,
        diaId: event.diaId,
        tipo: event.tipo,
        horario: event.horario,
      );
      // Otimização: Recarrega apenas o dia alterado
      final newDayEvents = await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap = Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
      if (newDayEvents.isEmpty) {
        updatedDaysMap.remove(event.diaId);
      } else {
        updatedDaysMap[event.diaId] = newDayEvents;
      }
      
      _monthCache[_cacheKey(_currentMonth, _currentUid)] = updatedDaysMap;
      _lastDaysMap = updatedDaysMap;
      
      globalLoading?.hide();
      emit(PontoHistoryActionSuccess(
        message: 'Ponto adicionado com sucesso',
        daysMap: updatedDaysMap,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateEventoEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    globalLoading?.show('Atualizando ponto...');
    emit(PontoHistoryActionProcessing(
      message: 'Atualizando ponto...',
      daysMap: _lastDaysMap,
    ));
    try {
      await repository.updateEvento(
        uid: event.uid,
        diaId: event.diaId,
        eventoId: event.eventoId,
        tipo: event.tipo,
        horario: event.horario,
      );
      // Otimização: Recarrega apenas o dia alterado
      final newDayEvents = await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap = Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
      if (newDayEvents.isEmpty) {
        updatedDaysMap.remove(event.diaId);
      } else {
        updatedDaysMap[event.diaId] = newDayEvents;
      }
      
      _monthCache[_cacheKey(_currentMonth, _currentUid)] = updatedDaysMap;
      _lastDaysMap = updatedDaysMap;

      globalLoading?.hide();
      emit(PontoHistoryActionSuccess(
        message: 'Ponto atualizado com sucesso',
        daysMap: updatedDaysMap,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    }
  }

  Future<void> _onDelete(
    DeleteEventoEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    globalLoading?.show('Removendo ponto...');
    emit(PontoHistoryActionProcessing(
      message: 'Removendo ponto...',
      daysMap: _lastDaysMap,
    ));
    try {
      await repository.deleteEvento(
        uid: event.uid,
        diaId: event.diaId,
        eventoId: event.eventoId,
      );
      // Otimização: Recarrega apenas o dia alterado
      final newDayEvents = await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap = Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
      if (newDayEvents.isEmpty) {
        updatedDaysMap.remove(event.diaId);
      } else {
        updatedDaysMap[event.diaId] = newDayEvents;
      }
      
      _monthCache[_cacheKey(_currentMonth, _currentUid)] = updatedDaysMap;
      _lastDaysMap = updatedDaysMap;

      globalLoading?.hide();
      emit(PontoHistoryActionSuccess(
        message: 'Ponto removido com sucesso',
        daysMap: updatedDaysMap,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    }
  }

  Future<void> _onBatchUpdate(
    BatchUpdateDayEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    globalLoading?.show('Salvando alterações...');
    emit(PontoHistoryActionProcessing(
      message: 'Salvando alterações...',
      daysMap: _lastDaysMap,
    ));
    try {
      await repository.batchUpdateDay(
        uid: event.uid,
        diaId: event.diaId,
        updates: event.updates,
        deletes: event.deletes,
        adds: event.adds,
      );
      // Otimização: Recarrega apenas o dia alterado
      final newDayEvents = await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap = Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
      if (newDayEvents.isEmpty) {
        updatedDaysMap.remove(event.diaId);
      } else {
        updatedDaysMap[event.diaId] = newDayEvents;
      }
      
      _monthCache[_cacheKey(_currentMonth, _currentUid)] = updatedDaysMap;
      _lastDaysMap = updatedDaysMap;

      globalLoading?.hide();
      emit(PontoHistoryActionSuccess(
        message: 'Alterações salvas com sucesso',
        daysMap: updatedDaysMap,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    }
  }

  /// Limpa o estado e o cache (chamado no logout).
  void reset() {
    _monthCache.clear();
    add(const ResetHistoryEvent());
  }

  @override
  Future<void> close() {
    _dataChangedSub?.cancel();
    return super.close();
  }
}
