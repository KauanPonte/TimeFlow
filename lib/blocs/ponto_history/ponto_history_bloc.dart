import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/ponto_history_repository.dart';
import 'ponto_history_event.dart';
import 'ponto_history_state.dart';

class PontoHistoryBloc extends Bloc<PontoHistoryEvent, PontoHistoryState> {
  final PontoHistoryRepository repository;
  final GlobalLoadingCubit? globalLoading;
  String? _currentUid;
  DateTime _currentMonth = DateTime.now();
  Map<String, List<Map<String, dynamic>>> _lastDaysMap = {};

  PontoHistoryBloc({required this.repository, this.globalLoading})
      : super(const PontoHistoryInitial()) {
    on<LoadHistoryEvent>(_onLoad);
    on<AddEventoEvent>(_onAdd);
    on<UpdateEventoEvent>(_onUpdate);
    on<DeleteEventoEvent>(_onDelete);
  }

  Future<void> _onLoad(
    LoadHistoryEvent event,
    Emitter<PontoHistoryState> emit,
  ) async {
    emit(const PontoHistoryLoading());
    try {
      _currentUid = event.uid;
      _currentMonth = event.month;
      final daysMap = await repository.loadDaysByMonth(
        uid: event.uid,
        year: _currentMonth.year,
        month: _currentMonth.month,
      );
      emit(PontoHistoryLoaded(daysMap: daysMap));
      _lastDaysMap = daysMap;
    } catch (e) {
      emit(PontoHistoryError(
          message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> _reloadMonth(String uid) {
    return repository.loadDaysByMonth(
      uid: uid,
      year: _currentMonth.year,
      month: _currentMonth.month,
    );
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
      final daysMap = await _reloadMonth(_currentUid ?? event.uid);
      _lastDaysMap = daysMap;
      emit(PontoHistoryActionSuccess(
        message: 'Ponto adicionado com sucesso',
        daysMap: daysMap,
      ));
    } catch (e) {
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    } finally {
      globalLoading?.hide();
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
      final daysMap = await _reloadMonth(_currentUid ?? event.uid);
      _lastDaysMap = daysMap;
      emit(PontoHistoryActionSuccess(
        message: 'Ponto atualizado com sucesso',
        daysMap: daysMap,
      ));
    } catch (e) {
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    } finally {
      globalLoading?.hide();
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
      final daysMap = await _reloadMonth(_currentUid ?? event.uid);
      _lastDaysMap = daysMap;
      emit(PontoHistoryActionSuccess(
        message: 'Ponto removido com sucesso',
        daysMap: daysMap,
      ));
    } catch (e) {
      emit(PontoHistoryActionError(
        message: e.toString().replaceAll('Exception: ', ''),
        daysMap: _lastDaysMap,
      ));
    } finally {
      globalLoading?.hide();
    }
  }
}
