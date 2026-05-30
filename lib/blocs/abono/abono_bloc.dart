import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/models/abono_model.dart';
import 'package:flutter_application_appdeponto/repositories/abono_repository.dart';
import 'abono_event.dart';
import 'abono_state.dart';

class AbonoBloc extends Bloc<AbonoEvent, AbonoState> {
  final AbonoRepository repository;
  final GlobalLoadingCubit? globalLoading;

  List<AbonoModel> _lastList = [];
  StreamSubscription<List<AbonoModel>>? _adminSub;

  AbonoBloc({required this.repository, this.globalLoading})
      : super(const AbonoInitial()) {
    on<LoadAbonosEvent>(_onLoad);
    on<SilentLoadAbonosEvent>(_onSilentLoad);
    on<SubscribeAdminAbonosEvent>(_onSubscribeAdmin);
    on<SubmitAbonoEvent>(_onSubmit);
    on<ApproveAbonoEvent>(_onApprove);
    on<RejectAbonoEvent>(_onReject);
    on<DeleteAbonoEvent>(_onDelete);
    on<DismissReviewedAbonoEvent>(_onDismissReviewed);
    on<ResetAbonosEvent>((_, emit) async {
      await _adminSub?.cancel();
      _adminSub = null;
      _lastList = [];
      emit(const AbonoInitial());
    });
  }

  void reset() => add(const ResetAbonosEvent());

  Future<void> _onSubscribeAdmin(
    SubscribeAdminAbonosEvent event,
    Emitter<AbonoState> emit,
  ) async {
    await _adminSub?.cancel();
    await emit.forEach<List<AbonoModel>>(
      repository.streamPendingAbonos(),
      onData: (list) {
        _lastList = list;
        return AbonoLoaded(abonos: list, isAdmin: true);
      },
      onError: (_, __) => state,
    );
  }

  Future<void> _onLoad(
    LoadAbonosEvent event,
    Emitter<AbonoState> emit,
  ) async {
    emit(const AbonoLoading());
    try {
      final list = event.isAdmin
          ? await repository.getPendingAbonos()
          : await repository.getMyAbonos();
      _lastList = list;
      emit(AbonoLoaded(abonos: list, isAdmin: event.isAdmin));
    } catch (e) {
      emit(AbonoError(message: e.toString(), abonos: _lastList));
    }
  }

  Future<void> _onSilentLoad(
    SilentLoadAbonosEvent event,
    Emitter<AbonoState> emit,
  ) async {
    try {
      final list = event.isAdmin
          ? await repository.getPendingAbonos()
          : await repository.getMyAbonos();
      _lastList = list;
      emit(AbonoLoaded(abonos: list, isAdmin: event.isAdmin));
    } catch (_) {}
  }

  Future<void> _onSubmit(
    SubmitAbonoEvent event,
    Emitter<AbonoState> emit,
  ) async {
    globalLoading?.show('Enviando pedido de abono…');
    try {
      await repository.requestAbono(
        diaId: event.diaId,
        observacao: event.observacao,
        dataInicio: event.dataInicio,
        dataFim: event.dataFim,
        abonoMinutes: event.abonoMinutes,
        isFullDay: event.isFullDay,
        fileName: event.fileName,
        fileBytes: event.fileBytes,
      );
      final list = await repository.getMyAbonos();
      _lastList = list;
      emit(AbonoActionSuccess(
          message: 'Pedido de abono enviado com sucesso.',
          abonos: list));
    } catch (e) {
      emit(AbonoError(
          message: e.toString().replaceAll('Exception: ', ''),
          abonos: _lastList));
    } finally {
      globalLoading?.hide();
    }
  }

  Future<void> _onApprove(
    ApproveAbonoEvent event,
    Emitter<AbonoState> emit,
  ) async {
    globalLoading?.show('Aprovando abono…');
    try {
      await repository.approveAbono(event.abonoId);
      final list = await repository.getPendingAbonos();
      _lastList = list;
      emit(AbonoActionSuccess(
          message: 'Abono aprovado.', abonos: list));
    } catch (e) {
      emit(AbonoError(
          message: e.toString().replaceAll('Exception: ', ''),
          abonos: _lastList));
    } finally {
      globalLoading?.hide();
    }
  }

  Future<void> _onReject(
    RejectAbonoEvent event,
    Emitter<AbonoState> emit,
  ) async {
    globalLoading?.show('Recusando abono…');
    try {
      await repository.rejectAbono(event.abonoId, reason: event.reason);
      final list = await repository.getPendingAbonos();
      _lastList = list;
      emit(AbonoActionSuccess(
          message: 'Abono recusado.', abonos: list));
    } catch (e) {
      emit(AbonoError(
          message: e.toString().replaceAll('Exception: ', ''),
          abonos: _lastList));
    } finally {
      globalLoading?.hide();
    }
  }

  Future<void> _onDelete(
    DeleteAbonoEvent event,
    Emitter<AbonoState> emit,
  ) async {
    globalLoading?.show('Removendo abono…');
    try {
      await repository.deleteAbono(event.abonoId);
      final list = await repository.getMyAbonos();
      _lastList = list;
      emit(AbonoActionSuccess(
          message: 'Abono removido.', abonos: list));
    } catch (e) {
      emit(AbonoError(
          message: e.toString().replaceAll('Exception: ', ''),
          abonos: _lastList));
    } finally {
      globalLoading?.hide();
    }
  }

  Future<void> _onDismissReviewed(
    DismissReviewedAbonoEvent event,
    Emitter<AbonoState> emit,
  ) async {
    try {
      await repository.markSeenByEmployee(event.abonoId);
      final updated =
          _lastList.where((a) => a.id != event.abonoId).toList();
      _lastList = updated;
      emit(AbonoLoaded(abonos: updated, isAdmin: false));
    } catch (_) {}
  }
}
