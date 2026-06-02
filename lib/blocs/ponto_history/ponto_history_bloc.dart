import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/blocs/ponto_data/ponto_data_changed_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'package:flutter_application_appdeponto/services/server_time_service.dart';
import 'ponto_history_event.dart';
import 'ponto_history_state.dart';

/// Evento interno disparado pelo stream Firestore quando o mês atual atualiza.
class _MonthStreamUpdatedEvent extends PontoHistoryEvent {
  final Map<String, List<Map<String, dynamic>>> daysMap;
  final DateTime month;
  final String? uid;
  const _MonthStreamUpdatedEvent(
      {required this.daysMap, required this.month, this.uid});
}

class PontoHistoryBloc extends Bloc<PontoHistoryEvent, PontoHistoryState> {
  final PontoHistoryRepository repository;
  final GlobalLoadingCubit? globalLoading;
  StreamSubscription<DateTime>? _dataChangedSub;
  StreamSubscription<Map<String, List<Map<String, dynamic>>>>? _monthStreamSub;
  String? _currentUid;
  DateTime _currentMonth = () {
    final now = ServerTimeService.nowBrazilUtc();
    return DateTime(now.year, now.month);
  }();
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
    on<_MonthStreamUpdatedEvent>(_onMonthStreamUpdated);
    on<SilentReloadHistoryEvent>(_onSilentReload);
    on<AddEventoEvent>(_onAdd);
    on<UpdateEventoEvent>(_onUpdate);
    on<DeleteEventoEvent>(_onDelete);
    on<BatchUpdateDayEvent>(_onBatchUpdate);
    on<ResetHistoryEvent>((_, emit) => emit(const PontoHistoryInitial()));

    // Fallback: PontoDataChangedCubit notifica quando admin edita ponto do mesmo processo.
    // Com streams, o Firestore já sincroniza automaticamente — isso é redundância segura.
    if (dataChangedCubit != null) {
      _dataChangedSub = dataChangedCubit.stream.listen((_) {
        // No-op: stream Firestore já emite a atualização automaticamente.
        // Mantido para compatibilidade com flows de edição admin.
      });
    }
  }

  Future<void> _onLoad(
    LoadHistoryEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    _currentUid = event.uid;
    _currentMonth = event.month;

    final key = _cacheKey(_currentMonth, _currentUid);
    final cached = _monthCache[key];

    // Exibe dados cacheados imediatamente — sem spinner ao trocar de mês.
    if (cached != null) {
      _lastDaysMap = cached;
      emit(PontoHistoryLoaded(daysMap: cached));
    } else {
      emit(const PontoHistoryLoading());
    }

    // Cancela stream do mês anterior e inicia stream do novo mês.
    await _monthStreamSub?.cancel();
    _monthStreamSub = null;

    final uid = event.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _monthStreamSub = repository
        .streamDaysByMonth(
          uid: uid,
          year: event.month.year,
          month: event.month.month,
        )
        .listen(
          (daysMap) => add(_MonthStreamUpdatedEvent(
            daysMap: daysMap,
            month: event.month,
            uid: event.uid,
          )),
          onError: (_) {
            // Mantém estado atual em caso de erro de stream (ex: offline).
          },
        );
  }

  void _onMonthStreamUpdated(
    _MonthStreamUpdatedEvent event,
    Emitter<PontoHistoryState> emit,
  ) {
    // Descarta eventos de meses/usuários que não são mais o atual.
    if (event.month.year != _currentMonth.year ||
        event.month.month != _currentMonth.month ||
        event.uid != _currentUid) {
      return;
    }

    final key = _cacheKey(event.month, event.uid);
    _monthCache[key] = event.daysMap;
    _lastDaysMap = event.daysMap;
    emit(PontoHistoryLoaded(daysMap: event.daysMap));
  }

  /// No-op: stream Firestore cobre atualizações automáticas.
  /// Mantido para compatibilidade com chamadas existentes.
  Future<void> _onSilentReload(
    SilentReloadHistoryEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    // Stream já emitirá nova versão se houver mudança no Firestore.
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
      // Stream Firestore emitirá automaticamente com os dados atualizados.
      // Atualização otimista: mantém UI responsiva sem esperar o stream.
      final newDayEvents =
          await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap =
          Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
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
      final newDayEvents =
          await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap =
          Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
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
      final newDayEvents =
          await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap =
          Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
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
      final newDayEvents =
          await repository.loadEventsForDay(event.uid, event.diaId);
      final updatedDaysMap =
          Map<String, List<Map<String, dynamic>>>.from(_lastDaysMap);
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

  /// Limpa o estado, cache e cancela stream (chamado no logout).
  void reset() {
    _monthCache.clear();
    _monthStreamSub?.cancel();
    _monthStreamSub = null;
    add(const ResetHistoryEvent());
  }

  @override
  Future<void> close() {
    _dataChangedSub?.cancel();
    _monthStreamSub?.cancel();
    return super.close();
  }
}
