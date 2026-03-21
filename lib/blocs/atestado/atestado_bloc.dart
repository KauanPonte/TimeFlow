import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/models/atestado_model.dart';
import 'package:flutter_application_appdeponto/repositories/atestado_repository.dart';
import 'atestado_event.dart';
import 'atestado_state.dart';

class AtestadoBloc extends Bloc<AtestadoEvent, AtestadoState> {
  final AtestadoRepository repository;
  final GlobalLoadingCubit? globalLoading;

  bool _isAdmin = false;
  List<AtestadoModel> _lastList = [];

  AtestadoBloc({
    required this.repository,
    this.globalLoading,
  }) : super(const AtestadoInitial()) {
    on<LoadAtestadosEvent>(_onLoad);
    on<SilentLoadAtestadosEvent>(_onSilentLoad);
    on<SubmitAtestadoEvent>(_onSubmit);
    on<ApproveAtestadoEvent>(_onApprove);
    on<RejectAtestadoEvent>(_onReject);
    on<ResetAtestadosEvent>((_, emit) {
      _lastList = [];
      emit(const AtestadoInitial());
    });
  }

  void reset() => add(const ResetAtestadosEvent());

  Future<void> _onSilentLoad(
    SilentLoadAtestadosEvent event,
    Emitter<AtestadoState> emit,
  ) async {
    try {
      final list = await repository.getPendingAtestados();
      _lastList = list;
      emit(AtestadoLoaded(atestados: list, isAdmin: true));
    } catch (_) {}
  }

  Future<void> _onLoad(
    LoadAtestadosEvent event,
    Emitter<AtestadoState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const AtestadoLoading());
    try {
      final list = _isAdmin
          ? await repository.getPendingAtestados()
          : await repository.getMyAtestados();
      _lastList = list;
      emit(AtestadoLoaded(atestados: list, isAdmin: _isAdmin));
    } catch (e) {
      emit(AtestadoError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSubmit(
    SubmitAtestadoEvent event,
    Emitter<AtestadoState> emit,
  ) async {
    globalLoading?.show('Enviando atestado...');
    emit(const AtestadoLoading());
    try {
      await repository.createAtestado(
        dataInicio: event.dataInicio,
        dataFim: event.dataFim,
        fileName: event.fileName,
        fileBytes: event.fileBytes,
      );
      final list = await repository.getMyAtestados();
      _lastList = list;
      globalLoading?.hide();
      emit(AtestadoActionSuccess(
        message: 'Atestado enviado com sucesso!',
        atestados: list,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(AtestadoError(
        message: e.toString().replaceAll('Exception: ', ''),
        atestados: _lastList,
      ));
    }
  }

  Future<void> _onApprove(
    ApproveAtestadoEvent event,
    Emitter<AtestadoState> emit,
  ) async {
    globalLoading?.show('Aprovando atestado...');
    try {
      await repository.approveAtestado(event.atestadoId);
      final list = await repository.getPendingAtestados();
      _lastList = list;
      globalLoading?.hide();
      emit(AtestadoActionSuccess(
        message: 'Atestado aprovado! Dias marcados como facultativos.',
        atestados: list,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(AtestadoError(
        message: e.toString().replaceAll('Exception: ', ''),
        atestados: _lastList,
      ));
    }
  }

  Future<void> _onReject(
    RejectAtestadoEvent event,
    Emitter<AtestadoState> emit,
  ) async {
    globalLoading?.show('Recusando atestado...');
    try {
      await repository.rejectAtestado(event.atestadoId, reason: event.reason);
      final list = await repository.getPendingAtestados();
      _lastList = list;
      globalLoading?.hide();
      emit(AtestadoActionSuccess(
        message: 'Atestado recusado.',
        atestados: list,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(AtestadoError(
        message: e.toString().replaceAll('Exception: ', ''),
        atestados: _lastList,
      ));
    }
  }
}
