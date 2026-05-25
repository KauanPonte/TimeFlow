import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'global_loading_state.dart';

/// Cubit global para controlar o overlay de carregamento.
///
/// Qualquer parte do app (blocs, services, UI) pode chamar
/// [show] para exibir o overlay e [hide] para removê-lo.
///
/// [show] é *atrasado*: o overlay só aparece se a operação durar mais que
/// [_showDelay]. A maioria das ações (writes confirmados pelo cache local)
/// terminam antes disso e nunca exibem o overlay — evita o "flash" de
/// loading em operações rápidas.
class GlobalLoadingCubit extends Cubit<GlobalLoadingState> {
  GlobalLoadingCubit() : super(const GlobalLoadingState());

  Timer? _showTimer;

  /// Atraso antes do overlay realmente aparecer. Operações que terminam
  /// antes disso nunca exibem o overlay.
  static const Duration _showDelay = Duration(milliseconds: 250);

  /// Agenda a exibição do overlay. Só aparece se a operação durar mais que
  /// [_showDelay]; caso contrário [hide] cancela o timer antes de aparecer.
  void show(String message) {
    _showTimer?.cancel();
    _showTimer = Timer(_showDelay, () {
      emit(GlobalLoadingState(isLoading: true, message: message));
    });
  }

  /// Exibe o overlay imediatamente, sem atraso. Use para operações sabidamente
  /// longas (ex.: upload de imagem) onde o overlay deve aparecer na hora.
  void showImmediate(String message) {
    _showTimer?.cancel();
    _showTimer = null;
    emit(GlobalLoadingState(isLoading: true, message: message));
  }

  /// Remove o overlay. Se a operação terminou antes de [_showDelay], cancela
  /// o timer e o overlay nunca chega a aparecer.
  void hide() {
    _showTimer?.cancel();
    _showTimer = null;
    if (state.isLoading) emit(const GlobalLoadingState());
  }

  @override
  Future<void> close() {
    _showTimer?.cancel();
    return super.close();
  }
}
