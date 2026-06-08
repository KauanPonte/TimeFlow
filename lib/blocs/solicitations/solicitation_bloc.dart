import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_appdeponto/blocs/global_loading/global_loading_cubit.dart';
import 'package:flutter_application_appdeponto/repositories/solicitation_repository.dart';
import 'package:flutter_application_appdeponto/models/solicitation_model.dart';
import 'solicitation_event.dart';
import 'solicitation_state.dart';

class SolicitationBloc extends Bloc<SolicitationEvent, SolicitationState> {
  final SolicitationRepository repository;
  final GlobalLoadingCubit? globalLoading;
  bool _isAdmin = false;
  List<SolicitationModel> _lastList = [];
  List<SolicitationModel> _lastReviewed = [];

  StreamSubscription? _sub;

  SolicitationBloc({
    required this.repository,
    this.globalLoading,
  }) : super(const SolicitationInitial()) {
    on<LoadSolicitationsEvent>(_onLoad);
    on<SubscribeSolicitationsEvent>(_onSubscribe);
    on<SilentReloadSolicitationsEvent>(_onSilentReload);
    on<CreateSolicitationEvent>(_onCreate);
    on<UpdateSolicitationEvent>(_onUpdate);
    on<CancelSolicitationEvent>(_onCancel);
    on<ProcessSolicitationEvent>(_onProcess);
    on<DismissReviewedSolicitationEvent>(_onDismiss);
    on<ResetSolicitationsEvent>((_, emit) async {
      await _sub?.cancel();
      _sub = null;
      _lastList = [];
      _lastReviewed = [];
      emit(const SolicitationInitial());
    });
  }

  void reset() => add(const ResetSolicitationsEvent());

  //  Helpers

  /// Revisadas ainda não vistas pelo funcionário (filtradas pelo servidor via seenByEmployee).
  List<SolicitationModel> _visibleReviewed() => List.from(_lastReviewed);

  //  Handlers

  Future<void> _onLoad(
    LoadSolicitationsEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    _isAdmin = event.isAdmin;
    emit(const SolicitationLoading());
    try {
      // Re-busca do cache local — o write acima já o populou (instantâneo).
      final list = _isAdmin
          ? await repository.getAllPendingSolicitations(preferCache: true)
          : await repository.getMyPendingSolicitations(preferCache: true);
      _lastList = list;

      final reviewed = _isAdmin
          ? <SolicitationModel>[]
          : await repository.getMyReviewedSolicitations();
      _lastReviewed = reviewed;

      emit(SolicitationLoaded(
        solicitations: list,
        reviewedSolicitations: _visibleReviewed(),
        isAdmin: _isAdmin,
      ));
    } catch (e) {
      emit(SolicitationError(
        message: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }

  Future<void> _onSubscribe(
    SubscribeSolicitationsEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    await _sub?.cancel();
    _isAdmin = event.isAdmin;
    if (_isAdmin) {
      await emit.forEach<List<SolicitationModel>>(
        repository.streamAllPendingSolicitations(),
        onData: (list) {
          _lastList = list;
          return SolicitationLoaded(
            solicitations: list,
            reviewedSolicitations: const [],
            isAdmin: true,
          );
        },
        onError: (_, __) => state,
      );
    } else {
      await emit.forEach<List<SolicitationModel>>(
        repository.streamMySolicitations(),
        onData: (all) {
          _lastList = all
              .where((s) => s.status == SolicitationStatus.pending)
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final window = DateTime.now().subtract(const Duration(days: 7));
          _lastReviewed = all
              .where((s) =>
                  (s.status == SolicitationStatus.approved ||
                      s.status == SolicitationStatus.rejected) &&
                  s.resolvedAt != null &&
                  s.resolvedAt!.isAfter(window))
              .toList()
            ..sort((a, b) {
              if (a.seenByEmployee != b.seenByEmployee) {
                return a.seenByEmployee ? 1 : -1;
              }
              return (b.resolvedAt ?? b.createdAt)
                  .compareTo(a.resolvedAt ?? a.createdAt);
            });
          return SolicitationLoaded(
            solicitations: _lastList,
            reviewedSolicitations: _visibleReviewed(),
            isAdmin: false,
          );
        },
        onError: (_, __) => state,
      );
    }
  }

  Future<void> _onSilentReload(
    SilentReloadSolicitationsEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    try {
      final isAdmin = event.isAdmin || _isAdmin;
      final list = isAdmin
          ? await repository.getAllPendingSolicitations()
          : await repository.getMyPendingSolicitations();
      _lastList = list;

      final reviewed = isAdmin
          ? <SolicitationModel>[]
          : await repository.getMyReviewedSolicitations();
      _lastReviewed = reviewed;

      emit(SolicitationLoaded(
        solicitations: list,
        reviewedSolicitations: _visibleReviewed(),
        isAdmin: isAdmin,
      ));
    } catch (_) {}
  }

  Future<void> _onCreate(
    CreateSolicitationEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    globalLoading?.show('Enviando solicitação...');
    emit(SolicitationActionProcessing(
      message: 'Enviando solicitação...',
      solicitations: _lastList,
    ));
    try {
      await repository.createSolicitation(
        diaId: event.diaId,
        items: event.items,
        reason: event.reason,
      );
      // Re-busca do cache local — o write acima já o populou (instantâneo).
      final list = _isAdmin
          ? await repository.getAllPendingSolicitations(preferCache: true)
          : await repository.getMyPendingSolicitations(preferCache: true);
      _lastList = list;
      globalLoading?.hide();
      // Revisadas NÃO mudam ao criar nova solicitação — reutiliza _lastReviewed.
      emit(SolicitationActionSuccess(
        message: 'Solicitação enviada com sucesso!',
        solicitations: list,
        reviewedSolicitations: _visibleReviewed(),
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(SolicitationError(
        message: e.toString().replaceAll('Exception: ', ''),
        solicitations: _lastList,
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateSolicitationEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    globalLoading?.show('Atualizando solicitação...');
    emit(SolicitationActionProcessing(
      message: 'Atualizando solicitação...',
      solicitations: _lastList,
    ));
    try {
      await repository.updateSolicitation(
        existingSolicitationId: event.existingSolicitationId,
        diaId: event.diaId,
        items: event.items,
        reason: event.reason,
      );
      // Re-busca do cache local — o write acima já o populou (instantâneo).
      final list = _isAdmin
          ? await repository.getAllPendingSolicitations(preferCache: true)
          : await repository.getMyPendingSolicitations(preferCache: true);
      _lastList = list;
      globalLoading?.hide();
      emit(SolicitationActionSuccess(
        message: 'Solicitação atualizada com sucesso!',
        solicitations: list,
        reviewedSolicitations: _visibleReviewed(),
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(SolicitationError(
        message: e.toString().replaceAll('Exception: ', ''),
        solicitations: _lastList,
      ));
    }
  }

  Future<void> _onCancel(
    CancelSolicitationEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    globalLoading?.show('Cancelando solicitação...');
    emit(SolicitationActionProcessing(
      message: 'Cancelando...',
      solicitations: _lastList,
    ));
    try {
      await repository.cancelSolicitation(event.solicitationId);
      // Re-busca do cache local — o write acima já o populou (instantâneo).
      final list = _isAdmin
          ? await repository.getAllPendingSolicitations(preferCache: true)
          : await repository.getMyPendingSolicitations(preferCache: true);
      _lastList = list;
      globalLoading?.hide();
      emit(SolicitationActionSuccess(
        message: 'Solicitação cancelada.',
        solicitations: list,
        reviewedSolicitations: _visibleReviewed(),
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(SolicitationError(
        message: e.toString().replaceAll('Exception: ', ''),
        solicitations: _lastList,
      ));
    }
  }

  Future<void> _onProcess(
    ProcessSolicitationEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    globalLoading?.show('Processando solicitação...');
    emit(SolicitationActionProcessing(
      message: 'Processando...',
      solicitations: _lastList,
    ));
    try {
      await repository.processSolicitation(
        solicitationId: event.solicitationId,
        itemStatuses: event.itemStatuses,
        reason: event.reason,
      );
      // Re-busca do cache local — o write acima já o populou (instantâneo).
      final list = await repository.getAllPendingSolicitations(preferCache: true);
      _lastList = list;
      globalLoading?.hide();
      emit(SolicitationActionSuccess(
        message: 'Solicitação processada com sucesso!',
        solicitations: list,
        reviewedSolicitations: _visibleReviewed(),
      ));
    } catch (e) {
      globalLoading?.hide();
      emit(SolicitationError(
        message: e.toString().replaceAll('Exception: ', ''),
        solicitations: _lastList,
      ));
    }
  }

  Future<void> _onDismiss(
    DismissReviewedSolicitationEvent event,
    Emitter<SolicitationState> emit,
  ) async {
    try {
      await repository.markSeenByEmployee(event.solicitationId);
    } catch (_) {
      // Falha silenciosa — tenta mesmo sem conexão
    }
    // Marca como visto em memória (mantém no histórico).
    _lastReviewed = _lastReviewed
        .map((s) =>
            s.id == event.solicitationId ? s.copyWith(seenByEmployee: true) : s)
        .toList();
    emit(SolicitationLoaded(
      solicitations: _lastList,
      reviewedSolicitations: _visibleReviewed(),
      isAdmin: _isAdmin,
    ));
  }
}
