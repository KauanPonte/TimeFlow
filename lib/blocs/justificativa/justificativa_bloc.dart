import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/models/justificativa_model.dart';
import 'package:flutter_application_appdeponto/repositories/justificativa_repository.dart';
import 'justificativa_event.dart';
import 'justificativa_state.dart';

class JustificativaBloc extends Bloc<JustificativaEvent, JustificativaState> {
  final JustificativaRepository repository;
  final GlobalLoadingCubit? globalLoading;

  bool _isAdmin = false;
  List<JustificativaModel> _lastList = [];

  JustificativaBloc({
    required this.repository,
    this.globalLoading,
  }) : super(const JustificativaInitial()) {
    on<LoadJustificativasEvent>(_onLoad);
    on<SilentLoadJustificativasEvent>(_onSilentLoad);
    on<SubmitJustificativaEvent>(_onSubmit);
    on<ApproveJustificativaEvent>(_onApprove);
    on<RejectJustificativaEvent>(_onReject);
    on<DismissReviewedJustificativaEvent>(_onDismissReviewed);
    on<ResetJustificativasEvent>((_, emit) {
      _lastList = [];
      emit(const JustificativaInitial());
    });
  }

  void reset() => add(const ResetJustificativasEvent());

  Future<void> _onSilentLoad(
    SilentLoadJustificativasEvent event,
    Emitter<JustificativaState> emit,
  ) async {
    try {
      final list = await repository.getPendingJustificativas();
      _lastList = list;
      emit(JustificativaLoaded(justificativas: list, isAdmin: true));
    } catch (_) {}
  }

  Future<void> _onLoad(
    LoadJustificativasEvent event,
    Emitter<JustificativaState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const JustificativaLoading());
    try {
      final list = _isAdmin
          ? await repository.getPendingJustificativas()
          : await repository.getMyJustificativas();
      _lastList = list;
      emit(JustificativaLoaded(justificativas: list, isAdmin: _isAdmin));
    } catch (e) {
      emit(JustificativaError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSubmit(
    SubmitJustificativaEvent event,
    Emitter<JustificativaState> emit,
  ) async {
    globalLoading?.show('Enviando justificativa...');
    emit(const JustificativaLoading());
    try {
      await repository.createJustificativa(
        diaId: event.diaId,
        justificativa: event.justificativa,
      );
      final list = await repository.getMyJustificativas();
      _lastList = list;
      globalLoading?.hide();
      emit(JustificativaActionSuccess(
        message: 'Justificativa enviada com sucesso!',
        justificativas: list,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(JustificativaError(
        message: e.toString().replaceAll('Exception: ', ''),
        justificativas: _lastList,
      ));
    }
  }

  Future<void> _onApprove(
    ApproveJustificativaEvent event,
    Emitter<JustificativaState> emit,
  ) async {
    globalLoading?.show('Aprovando justificativa...');
    try {
      await repository.approveJustificativa(event.justificativaId);
      final list = await repository.getPendingJustificativas();
      _lastList = list;
      globalLoading?.hide();
      emit(JustificativaActionSuccess(
        message: 'Justificativa aprovada.',
        justificativas: list,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(JustificativaError(
        message: e.toString().replaceAll('Exception: ', ''),
        justificativas: _lastList,
      ));
    }
  }

  Future<void> _onReject(
    RejectJustificativaEvent event,
    Emitter<JustificativaState> emit,
  ) async {
    globalLoading?.show('Recusando justificativa...');
    try {
      await repository.rejectJustificativa(event.justificativaId,
          reason: event.reason);
      final list = await repository.getPendingJustificativas();
      _lastList = list;
      globalLoading?.hide();
      emit(JustificativaActionSuccess(
        message: 'Justificativa recusada.',
        justificativas: list,
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(JustificativaError(
        message: e.toString().replaceAll('Exception: ', ''),
        justificativas: _lastList,
      ));
    }
  }

  Future<void> _onDismissReviewed(
    DismissReviewedJustificativaEvent event,
    Emitter<JustificativaState> emit,
  ) async {
    await repository.markSeenByEmployee(event.justificativaId);
    _lastList = _lastList
        .map((j) => j.id == event.justificativaId
            ? j.copyWith(seenByEmployee: true)
            : j)
        .toList();
    emit(JustificativaLoaded(justificativas: _lastList, isAdmin: _isAdmin));
  }
}
